import time
from web3 import Web3
from eth_account import Account

# 🔐 Вставь свой приватный ключ (ОСТОРОЖНО: не делись им с другими)
PRIVATE_KEY = 'your_private_key'
ACCOUNT = Account.from_key(PRIVATE_KEY)
ADDRESS = ACCOUNT.address

# 🧠 Сети и RPC
NETWORKS = {
    'base-sepolia': 'https://base-sepolia.g.alchemy.com/v2/kzRgZD4OcKAgdvYqQ-gagM_PiqyYW-f_',
    'arbitrum-sepolia': 'https://arb-sepolia.g.alchemy.com/v2/kzRgZD4OcKAgdvYqQ-gagM_PiqyYW-f_',
    'unichain-sepolia': 'https://unichain-sepolia.g.alchemy.com/v2/kzRgZD4OcKAgdvYqQ-gagM_PiqyYW-f_',
    'optimism-sepolia': 'https://opt-sepolia.g.alchemy.com/v2/kzRgZD4OcKAgdvYqQ-gagM_PiqyYW-f_'
}

# 💸 Сумма для отправки в ETH
AMOUNT_ETH = 0.001
GAS_LIMIT = 21000  # для простой отправки ETH

def send_tx(w3: Web3, name: str):
    try:
        nonce = w3.eth.get_transaction_count(ADDRESS)
        gas_price = w3.eth.gas_price

        tx = {
            'nonce': nonce,
            'to': ADDRESS,
            'value': w3.to_wei(AMOUNT_ETH, 'ether'),
            'gas': GAS_LIMIT,
            'gasPrice': gas_price,
            'chainId': w3.eth.chain_id
        }

        signed_tx = w3.eth.account.sign_transaction(tx, PRIVATE_KEY)
        tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
        print(f"[{name}] Tx sent: {tx_hash.hex()}")
    except Exception as e:
        print(f"[{name}] Error: {e}")

def main():
    w3_clients = {name: Web3(Web3.HTTPProvider(rpc)) for name, rpc in NETWORKS.items()}

    while True:
        for name, w3 in w3_clients.items():
            if w3.is_connected():
                send_tx(w3, name)
            else:
                print(f"[{name}] Not connected")
        time.sleep(90)

if __name__ == "__main__":
    main()
