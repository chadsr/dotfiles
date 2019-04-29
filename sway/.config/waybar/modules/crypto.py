#!/usr/bin/env python3

import configparser
import sys
import os
import requests
from decimal import Decimal

config = configparser.ConfigParser()
abs_dir = os.path.dirname(os.path.abspath(__file__)) # Get the absolute path of this script
with open(f'{abs_dir}/crypto.ini', 'r', encoding='utf-8') as f:
	config.read_file(f)

coins = [x for x in config.sections() if x != 'general'] # All coin sections from the config
base_currency = config['general']['base_currency'] # The fiat currency used in the trading pair
params = {'convert': base_currency}
headers = {'X-CMC_PRO_API_KEY': config['general']['api_key']}

for coin in coins:
	icon = config[coin]['icon']
	json = requests.get(f'https://pro-api.coinmarketcap.com/v1/{currency}', params=params, headers=headers).json()[0]
	local_price = round(Decimal(json[f'price_{base_currency.lower()}']), 2)
	change_24 = float(json['percent_change_24h'])

	display_opt = config['general']['display']
	if display_opt == 'both' or display_opt == None:
		sys.stdout.write(f'{icon} {local_price}/{change_24:+}% ')
	elif display_opt == 'percentage':
		sys.stdout.write(f'{icon} {change_24:+}%')
	elif display_opt == 'price':
		sys.stdout.write(f'{icon} {local_price}')
