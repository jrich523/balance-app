#!/usr/bin/env python3
'''
Simple API endpoint to get latest ETH balance for an address
'''

import json
import os
import sys
import logging
from urllib.parse import urljoin
import requests
from web3 import Web3
from flask import Flask, jsonify

## Setup Logging
log_level = os.getenv('LOG_LEVEL', 'INFO').upper()
logging.basicConfig(level=getattr(logging, log_level, logging.INFO))
logger = logging.getLogger(__name__)

# Environment variable for Infura access
API_KEY = os.getenv('INFURA_API_KEY')
INFURA_API_ENDPOINT = os.getenv('INFURA_API_ENDPOINT', "https://mainnet.infura.io/v3/")

app = Flask(__name__)


@app.route('/address/balance/<address>', methods=['GET'])
def get_address_balance(address):
    '''route to GET an eth balance based on the address'''

    balance = get_eth_balance(address)
    try:
        float_value = float(balance)
        return jsonify({'balance': balance})
    except ValueError:
        return jsonify({'error': balance})


def get_eth_balance(address, block='latest'):
    '''Query Infura for Eth balance'''

    headers = {"Content-Type": "application/json"}

    data = {
        "jsonrpc": "2.0",
        "method": "eth_getBalance",
        "params": [address, block],
        "id": 1
    }

    url = urljoin(INFURA_API_ENDPOINT, API_KEY)

    response = requests.post(url, headers=headers, data=json.dumps(data), timeout=60)

    logger.debug("Status: %s Response: %s", response.status_code, response.json())

    if response.status_code == 200:
        body = response.json()
        if 'error' in body:
            return body.get('error')

        hex_wei_balance = response.json().get('result')
        balance = wei_to_eth(hex_wei_balance)
    else:
        balance = f"Error! Received status code {response.status_code}"

    return balance


def wei_to_eth(wei):
    '''convert wei to eth'''
    balance = Web3.from_wei(int(wei, 16), 'ether')
    return balance


if __name__ == '__main__':
    if API_KEY is None:
        logger.error("Environment variable INFURA_API_KEY not set!")
        sys.exit(1)

    domain = os.getenv('DOMAIN', 'localhost')
    port = int(os.getenv('PORT', '5000'))

    mode = log_level == "DEBUG"

    app.run(host=domain, port=port, debug=mode)
