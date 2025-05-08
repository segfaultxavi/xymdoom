import time
import os
import subprocess
import keyboard
import re
import json
import math
import urllib.request
from dotenv import load_dotenv

from symbolchain.CryptoTypes import PrivateKey
from symbolchain.facade.SymbolFacade import SymbolFacade
from symbolchain.symbol.Network import NetworkTimestamp
from symbolchain.symbol.IdGenerator import generate_mosaic_alias_id
from symbolchain.sc import Amount

load_dotenv()

NODE_URL = os.getenv('NODE_URL')
TREASURY_PRIVATE_KEY = os.getenv('TREASURY_PRIVATE_KEY')
treasury_key_pair = SymbolFacade.KeyPair(PrivateKey(TREASURY_PRIVATE_KEY))
PLAYER_ADDRESS = os.getenv('PLAYER_ADDRESS')

facade = SymbolFacade('testnet')

timestamp = 0
fee_mult = 0

def fetch_config():
    global timestamp
    global fee_mult
    # Fetch current network time
    time_path = '/node/time'
    print(f'Fetching current network time from {time_path}')
    with urllib.request.urlopen(f'{NODE_URL}{time_path}') as response:
        response_json = json.loads(response.read().decode())
        timestamp = NetworkTimestamp(int(
            response_json['communicationTimestamps']['receiveTimestamp']))
        print(f'  Network time: {timestamp.timestamp} ms since nemesis')

    # Fetch recommended fees
    fee_path = '/network/fees/transaction'
    print(f'Fetching recommended fees from {fee_path}')
    with urllib.request.urlopen(f'{NODE_URL}{fee_path}') as response:
        response_json = json.loads(response.read().decode())
        median_mult = response_json['medianFeeMultiplier']
        minimum_mult = response_json['minFeeMultiplier']
        fee_mult = max(median_mult, minimum_mult)
        print(f'  Fee multiplier: {fee_mult}')

def send_xym(amount):
    global timestamp
    global fee_mult
    # Build the transaction
    transaction = facade.transaction_factory.create({
        'type': 'transfer_transaction_v1',
        'signer_public_key': treasury_key_pair.public_key,
        'deadline': timestamp.add_hours(2).timestamp,
        'recipient_address': PLAYER_ADDRESS,
        'mosaics': [{
            'mosaic_id': generate_mosaic_alias_id('symbol.xym'),
            'amount': amount * 1_000_000
        }]
    })
    transaction.fee = Amount(fee_mult * transaction.size)
    timestamp = timestamp.add_seconds(1) # So next tx does not have the same hash

    # Sign transaction and generate final payload
    signature = facade.sign_transaction(treasury_key_pair, transaction)
    json_payload = facade.transaction_factory.attach_signature(
        transaction, signature)

    # Announce the transaction
    announce_path = '/transactions'
    print(f'Announcing transaction to {announce_path}')
    announce_request = urllib.request.Request(
        f'{NODE_URL}{announce_path}',
        data=json_payload.encode(),
        headers={ 'Content-Type': 'application/json' },
        method='PUT'
    )
    with urllib.request.urlopen(announce_request) as response:
        print(f'  Response: {response.read().decode()}')

    # Wait for confirmation
    status_path = (
        f'/transactionStatus/{facade.hash_transaction(transaction)}')
    print(f'Waiting for confirmation from {status_path}')
    for attempt in range(60):
        time.sleep(1)
        try:
            with urllib.request.urlopen(
                f'{NODE_URL}{status_path}'
            ) as response:
                status = json.loads(response.read().decode())
                print(f"  Transaction status: {status['group']}")
                if status['group'] == 'confirmed':
                    print(f'Transaction confirmed in {attempt} seconds')
                    break
                if status['group'] == 'failed':
                    print(f"Transaction failed: {status['code']}")
                    break
        except urllib.error.HTTPError as e:
            print(f'  Transaction status: unknown | Cause: ({e.msg})')
    else:
        print('Confirmation took too long.')

def fetch_balance():
    balance_path = f'/accounts/{PLAYER_ADDRESS}'
    print(f'Fetching player balance from {balance_path}')
    with urllib.request.urlopen(f'{NODE_URL}{balance_path}') as response:
        response_json = json.loads(response.read().decode())
        balance = int(response_json['account']['mosaics'][0]['amount'])
        balance = math.trunc(balance / 1_000_000)
        print(f'  Balance: {balance} XYM')
        return balance

def send_keystroke(key):
    keyboard.press(key)
    time.sleep(0.050)
    keyboard.release(key)
    time.sleep(0.050)

def send_int(value, count):
    while count:
        count -= 1
        send_keystroke('K' if ((value >> count) & 1) else 'J')

def send_balance():
    balance = fetch_balance()
    send_int(1, 4)
    send_int(balance, 8)

def process_line(line):
    if line == "Balance request":
        print("Balance requested")
        send_balance()
        return
    match = re.match(r"Collected (\d+) coins", line)
    if match:
        count = int(match.group(1))
        print(f"Requesting {count} coins")
        send_xym(count)
        send_int(0, 4) # Send confirmation command
        return

def monitor_log_file(file_path):
    try:
        with open(file_path, 'r') as file:
            # Move to the end of the file
            file.seek(0, 2)
            while process.poll() is None:
                line = file.readline()
                if line:
                    process_line(line.strip())
                else:
                    time.sleep(0.5)  # Wait before checking for new lines
            print("Doom exited")
    except KeyboardInterrupt:
        print("\nMonitoring stopped.")

if __name__ == "__main__":
    try:
        fetch_config()
        log_file_path = "log.txt"
        # Delete previous log
        print("Deleting old log")
        if os.path.exists(log_file_path):
            os.remove(log_file_path)
        # Launch a new process in a portable way
        print("Launching Doom")
        process = subprocess.Popen([
            os.getenv('GZDOOM_BINARY'),
            "-iwad", os.getenv('DOOM2_WAD'),
            "-file", "xymres/", os.getenv('MAP_WAD'),
            "+map", os.getenv('MAP_NAME')],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        # Wait for the log file to be created
        print("Waiting for log file")
        while not os.path.exists(log_file_path):
            time.sleep(1)
        # Start monitoring the log file
        print("Monitoring")
        monitor_log_file(log_file_path)

    except Exception as e:
        print(f"Error: {e}")
