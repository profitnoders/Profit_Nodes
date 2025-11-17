import os
os.environ["TOKENIZERS_PARALLELISM"] = "false"

import time
import logging
import subprocess
import re
from collections import defaultdict

import ollama

from hivemind import DHT

from genrl.blockchain import SwarmCoordinator
from genrl.communication.hivemind.hivemind_backend import HivemindBackend
from genrl.data import DataManager
from genrl.game import BaseGameManager
from genrl.game.game_manager import DefaultGameManagerMixin
from genrl.logging_utils.global_defs import get_logger
from genrl.logging_utils.system_utils import get_system_info
from genrl.rewards import RewardManager
from genrl.roles import RoleManager
from genrl.state import GameState
from genrl.trainer import TrainerModule
from huggingface_hub import login, whoami

from code_gen_exp.src.utils.name_utils import get_name_from_peer_id


# приглушаем лишние логи hivemind
for _name in [
    "hivemind",
    "hivemind.dht",
    "hivemind.p2p",
    "hivemind.p2p.p2p_daemon_bindings",
]:
    logging.getLogger(_name).setLevel(logging.CRITICAL)


class SwarmGameManager(BaseGameManager, DefaultGameManagerMixin):
    """GameManager that orchestrates a game using a SwarmCoordinator."""

    def __init__(
        self,
        coordinator: SwarmCoordinator,
        max_stage: int,
        max_round: int,
        game_state: GameState,
        reward_manager: RewardManager,
        trainer: TrainerModule,
        data_manager: DataManager,
        communication_kwargs: dict,
        role_manager: RoleManager | None = None,
        run_mode: str = "train",
        log_dir: str = "logs",
        hf_token: str | None = None,
        hf_push_frequency: int = 20,
        **kwargs,
    ):
        # bootnodes от координатора — сохраняем для реконнекта
        initial_peers = coordinator.get_bootnodes()
        communication_kwargs["initial_peers"] = initial_peers
        get_logger().info(f"bootnodes: {initial_peers}")
        rewards_ollama_model = kwargs.get(
            "rewards_ollama_model", "qwen2.5-coder:1.5b-instruct"
        )

        communication = HivemindBackend(**communication_kwargs)

        super().__init__(
            max_stage=max_stage,
            max_round=max_round,
            game_state=game_state,
            reward_manager=reward_manager,
            trainer=trainer,
            data_manager=data_manager,
            communication=communication,
            role_manager=role_manager,
            run_mode=run_mode,
        )

        assert isinstance(self.communication, HivemindBackend)
        self.train_timeout = 60 * 60 * 24 * 31  # 1 month

        # сохраним исходные initial_peers для реконнекта
        self.initial_peers = list(initial_peers)

        # Logging Setup
        self.peer_id = self.communication.get_id()
        self.state.peer_id = self.peer_id
        self.animal_name = get_name_from_peer_id(self.peer_id, True)

        # Register peer_id and get current round from the chain
        self.coordinator = coordinator
        self.coordinator.register_peer(self.peer_id)
        round_num, _ = self.coordinator.get_round_and_stage()
        self.state.round = round_num

        # initialize communication module to contract's round
        self.communication.step_ = self.state.round

        self.data_manager.initialize(self.communication)

        # enable push to HF if token was provided
        self.hf_token = hf_token
        if self.hf_token not in [None, "None"]:
            self._configure_hf_hub(hf_push_frequency)

        get_logger().info("============!!!Joining CodeZero Swarm!!!============")
        get_logger().info(
            f"🐝 Hello [{get_name_from_peer_id(self.peer_id)}] [{self.peer_id}]!"
        )
        get_logger().info(f"Using Model: {self.trainer.model.config.name_or_path}")

        # ollama модель для rewards
        try:
            models = ollama.list()
            model_names = [model["model"] for model in models["models"]]
            if rewards_ollama_model not in model_names:
                ollama.pull(rewards_ollama_model)
        except Exception:
            get_logger().error(
                f"Error pulling model from ollama: {rewards_ollama_model}"
            )
            raise

        os.makedirs(log_dir, exist_ok=True)
        with open(os.path.join(log_dir, "system_info.txt"), "w") as f:
            f.write(get_system_info())

        self.batched_signals = 0.0
        self.time_since_submit = time.time()  # seconds
        self.submit_period = 3.0  # hours
        self.submitted_this_round = False

    # ---------- helpers для DHT/p2pd ----------

    def is_p2pd_alive(self) -> bool:
        """Проверяем, жив ли p2pd: существует ли control socket."""
        try:
            p2p = self.communication.dht._p2p
            control_path = p2p.daemon.control_path
            return bool(control_path) and os.path.exists(control_path)
        except Exception:
            return False

    def find_existing_p2pd(self):
        """Попробовать найти порты уже запущенного p2pd по ss."""
        try:
            # TCP
            result_tcp = subprocess.run(
                ["ss", "-tlpn"], capture_output=True, text=True, check=False
            )
            tcp_out = result_tcp.stdout

            if "p2pd" not in tcp_out:
                return None

            # берём первый попавшийся LISTEN порт p2pd
            tcp_match = re.search(r"LISTEN\s+.*:(\d+)\s+.*p2pd", tcp_out)
            if not tcp_match:
                return None

            tcp_port = tcp_match.group(1)
            host_maddrs = [f"/ip4/0.0.0.0/tcp/{tcp_port}"]
            return host_maddrs
        except Exception:
            return None

    def _reconnect_dht(self, reconnect_attempts, max_reconnect_attempts, check_interval):
        """Пытаемся пересоздать DHT (и при необходимости p2pd)."""
        if reconnect_attempts >= max_reconnect_attempts:
            return reconnect_attempts, False

        try:
            existing_maddrs = self.find_existing_p2pd()
            if existing_maddrs:
                get_logger().info(
                    "Found existing p2pd process, trying to attach as client..."
                )
                host_maddrs = existing_maddrs
                client_mode = True
                start = False
            else:
                get_logger().info("No existing p2pd found, starting a new one...")
                host_maddrs = ["/ip4/0.0.0.0/tcp/0"]
                client_mode = False
                start = True

            new_dht = DHT(
                start=start,
                host_maddrs=host_maddrs,
                initial_peers=self.initial_peers,
                client_mode=client_mode,
                use_ipfs=False,
            )

            # даём чуть времени на поднятие p2pd
            time.sleep(5)
            self.communication.dht = new_dht
            get_logger().info("Successfully reconnected DHT/p2pd")
            return 0, True
        except Exception as e:
            reconnect_attempts += 1
            get_logger().warning(
                f"DHT reconnection attempt {reconnect_attempts} failed: {e}"
            )
            if reconnect_attempts < max_reconnect_attempts:
                get_logger().info(
                    f"Retrying DHT reconnection in {check_interval} seconds..."
                )
                time.sleep(check_interval)
            return reconnect_attempts, False

    # ---------- rewards / chain ----------

    def _get_total_rewards_by_agent(self):
        rewards_by_agent = defaultdict(int)
        for stage in range(self.state.stage):
            rewards = self.rewards[stage]
            for agent_id, agent_rewards in rewards.items():
                for batch_id, batch_rewards in agent_rewards.items():
                    tot = 0
                    for generation_rewards in batch_rewards:
                        tot += sum(generation_rewards)
                    rewards_by_agent[agent_id] += tot

        return rewards_by_agent

    def _get_my_rewards(self, signal_by_agent):
        if len(signal_by_agent) == 0:
            return 0
        if self.peer_id in signal_by_agent:
            my_signal = signal_by_agent[self.peer_id]
        else:
            my_signal = 0
        # официальная логика: только положительный сигнал (+1)
        my_signal = (my_signal + 1) * (my_signal > 0) + 0 * (my_signal <= 0)
        return my_signal

    def _try_submit_to_chain(self, signal_by_agent):
        elapsed_time_hours = (time.time() - self.time_since_submit) / 3600
        if elapsed_time_hours > self.submit_period:
            try:
                self.coordinator.submit_reward(
                    self.state.round, 0, int(self.batched_signals), self.peer_id
                )
                self.batched_signals = 0.0
                if len(signal_by_agent) > 0:
                    max_agent, max_signal = max(
                        signal_by_agent.items(), key=lambda x: x[1]
                    )
                else:  # если нет signal_by_agent — считаем победителем себя
                    max_agent = self.peer_id

                self.coordinator.submit_winners(
                    self.state.round, [max_agent], self.peer_id
                )
                self.time_since_submit = time.time()
                self.submitted_this_round = True
            except Exception as e:
                get_logger().debug(str(e))

    def _hook_after_rewards_updated(self):
        try:
            signal_by_agent = self._get_total_rewards_by_agent()
            self.batched_signals += self._get_my_rewards(signal_by_agent)
        except Exception as e:
            get_logger().debug(f"Error getting total rewards by agent: {e}")
            signal_by_agent = {}

        self._try_submit_to_chain(signal_by_agent)

        for stage in range(self.state.stage):
            root_state = self.state.get_stage_state(stage)
            self.data_manager.send_response(self.rewards[stage], root_state)

    def _hook_after_round_advanced(self):
        self._save_to_hf()

        # Try to submit to chain again if necessary, but don't update our signal twice
        if not self.submitted_this_round:
            try:
                signal_by_agent = self._get_total_rewards_by_agent()
            except Exception as e:
                get_logger().debug(f"Error getting total rewards by agent: {e}")
                signal_by_agent = {}

            self._try_submit_to_chain(signal_by_agent)

        # Reset flag for next round
        self.submitted_this_round = False

        # Block until swarm round advances
        self.agent_block()

    def _hook_after_game(self):
        self._save_to_hf()

    # ---------- HuggingFace ----------

    def _configure_hf_hub(self, hf_push_frequency):
        username = whoami(token=self.hf_token)["name"]
        model_name = self.trainer.model.config.name_or_path.split("/")[-1]
        model_name += "-Gensyn-Swarm"
        model_name += f"-{self.animal_name}"
        self.trainer.args.hub_model_id = f"{username}/{model_name}"
        self.hf_push_frequency = hf_push_frequency
        get_logger().info("Logging into Hugging Face Hub...")
        login(self.hf_token)

    def _save_to_hf(self):
        if (
            self.hf_token not in [None, "None"]
            and self.state.round % self.hf_push_frequency == 0
        ):
            get_logger().info("pushing model to huggingface")
            try:
                repo_id = self.trainer.args.hub_model_id

                self.trainer.model.push_to_hub(
                    repo_id=repo_id,
                    token=self.hf_token,
                    commit_message=f"rl-swarm: round {self.state.round}, agent {self.animal_name}",
                    tags=[
                        "rl-swarm",
                        "genrl-swarm",
                        "grpo",
                        "gensyn",
                        f"I am {self.animal_name}",
                    ],
                )
            except Exception:
                get_logger().exception(
                    "Failed to push model to the Hugging Face Hub. When you conclude training please try manually pushing it yourself using the instructions here: https://huggingface.co/docs/hub/en/models-uploading",
                    stack_info=True,
                )

    # ---------- main loop blocking with авто-реконнектом ----------

    def agent_block(
        self, check_interval: float = 5.0, log_timeout: float = 10.0, max_check_interval: float = 60.0 * 15
    ):
        start_time = time.monotonic()
        fetch_log_time = start_time
        check_backoff = check_interval  # Exponential backoff for already finished rounds.
        reconnect_attempts = 0
        max_reconnect_attempts = 3

        while time.monotonic() - start_time < self.train_timeout:
            curr_time = time.monotonic()

            # --- проверяем DHT/p2pd и при необходимости реконнектим ---
            try:
                if not self.is_p2pd_alive():
                    raise ConnectionRefusedError("p2pd control socket is missing")
                _ = self.communication.dht.get_visible_maddrs(latest=True)
                reconnect_attempts = 0  # удалось — сбрасываем счётчик
            except Exception as e:
                get_logger().warning(
                    f"P2PD connection lost at {time.strftime('%Y-%m-%d %H:%M:%S')}"
                )
                get_logger().warning(f"Error details: {e}")
                reconnect_attempts, _ = self._reconnect_dht(
                    reconnect_attempts, max_reconnect_attempts, check_interval
                )

            # --- получаем текущий round/stage из координатора ---
            try:
                round_num, stage = self.coordinator.get_round_and_stage()
            except Exception as e:
                if curr_time - fetch_log_time > log_timeout:
                    get_logger().debug(
                        f"Could not fetch round and stage: {e}. Next check in {check_interval}s."
                    )
                    fetch_log_time = curr_time

                time.sleep(check_interval)
                continue

            if round_num >= self.state.round:
                get_logger().info(f"🐝 Joining round: {round_num}")
                check_backoff = check_interval  # Reset backoff after successful round
                self.state.round = round_num  # advance to swarm's round.
                return
            else:
                get_logger().info(
                    f"Already finished round: {round_num}. Next check in {check_backoff}s."
                )
                time.sleep(check_backoff)
                check_backoff = min(check_backoff * 2, max_check_interval)

            if round_num == self.max_round - 1:
                return

        get_logger().info("Training timed out!")
