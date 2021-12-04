import json
import datetime
import os.path
from datetime import datetime
from requests import Session
from requests.exceptions import ConnectionError, Timeout, TooManyRedirects


def get_latest_listing():
    """
    Get latest market listing from coinmarketcap.com
    Save it to local export file.
    :return: Json object
    """
    url = 'https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest'
    parameters = {
        'start': '1',
        'limit': '5000',
        'convert': 'USD'
    }
    headers = {
        'Accepts': 'application/json',
        'X-CMC_PRO_API_KEY': 'XXXXX',
    }

    session = Session()
    session.headers.update(headers)

    try:
        response = session.get(url, params=parameters)
        export_path = f'export-{datetime.now().strftime("%d-%m-%Y")}.json'
        with open(export_path, 'w') as fw:
            fw.write(response.text)
        return json.loads(response.text)
    except (ConnectionError, Timeout, TooManyRedirects) as e:
        print(e)


def get_listing():
    """
    Get local export file if exist, else get latest data.
    :return: Json object
    """
    export_path = f'export-{datetime.now().strftime("%d-%m-%Y")}.json'
    if os.path.isfile(export_path):
        with open(export_path) as fr:
            data = json.loads(fr.read())
            return data
    else:
        return get_latest_listing()


def parse_response():
    """
    Select coins which have volume larger than 100 mil. to buy and sell
    :return:
    """
    buy_list = list()
    sell_list = list()
    data = get_listing()
    for row in data['data']:
        if row['quote']['USD']['market_cap'] > 100000000:
            if row['quote']['USD']['percent_change_24h'] < -10:
                buy_list.append((row['quote']['USD']['percent_change_24h'], row['symbol']))
            if row['quote']['USD']['percent_change_24h'] > 10:
                sell_list.append((row['quote']['USD']['percent_change_24h'], row['symbol']))
    print(len(buy_list), sorted(buy_list, key=lambda tup: tup[0]))
    print(len(sell_list), sorted(sell_list, key=lambda tup: tup[0]))


if __name__ == '__main__':
    parse_response()
