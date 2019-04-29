#!/usr/bin/env python3

import configparser
import sys
import os
import requests
import json
from decimal import Decimal

API_URL = 'https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest'

config = configparser.ConfigParser()
abs_dir = os.path.dirname(os.path.abspath(__file__)) # Get the absolute path of this script
with open(f'{abs_dir}/crypto.ini', 'r', encoding='utf-8') as f:
	config.read_file(f)

coins = [section for section in config.sections() if section != 'general'] # Any section that isn't general, is a coin
currency = config['general']['currency'].upper() # The fiat currency used in the trading pair
currency_symbol = config['general']['currency_symbol']

params = {
	'convert': currency.upper(),
	'symbol': ','.join(coin.upper() for coin in coins)
}

headers = {'X-CMC_PRO_API_KEY': config['general']['api_key']}

# Request the chosen price pairs
response = requests.get(API_URL, params=params, headers=headers, timeout=2)
if response.status_code != 200:
	print("Coinmarketcap API returned non 200 response:\n", response.content)
	sys.exit(1)

# Get a list of the chosen display options
display_options = config['general']['display'].split(',')

# For each coin, write to stdout, formatted according to the chosen settings

output_obj = {
	'text': '',
	'tooltip': "Cryptocurrency metrics from Coinmarketcap:\n",
	'class': 'crypto'
}

for coin in coins:
	icon = config[coin]['icon']
	
	# Extract the object relevant to our coin/currency pair
	pair_info = response.json()['data'][coin.upper()]['quote'][currency]

	output = f'{icon}'
	# Shows price by default
	if 'price' in display_options or not display_options:
		current_price = round(Decimal(pair_info['price']), 2)
		output += f'{currency_symbol}{current_price} '
	if 'volume' in display_options:
		percentage_change = round(Decimal(pair_info['volume_24']), 2)
		output += f'24h:{currency_symbol}{percentage_change:+} '
	if 'change24' in display_options:
		percentage_change = round(Decimal(pair_info['percent_change_24h']), 2)
		output += f'24h:{percentage_change:+}% '
	if 'change1h' in display_options:
		percentage_change = round(Decimal(pair_info['percent_change_1h']), 2)
		output += f'1h:{percentage_change:+}% '
	if 'change7d' in display_options:
		percentage_change = round(Decimal(pair_info['percent_change_7d']), 2)
		output += f'7d:{percentage_change:+}% '

	output_obj['text'] += output
	output_obj['tooltip'] += output

sys.stdout.write(json.dumps(output_obj))