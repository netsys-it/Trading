import json
from requests import Session
from requests.exceptions import ConnectionError, Timeout, TooManyRedirects


def get_latest_listing():
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
        data = json.loads(response.text)
        buy_list = list()
        sell_list = list()
        for row in data['data']:
            if row['quote']['USD']['market_cap'] > 100000000:
                if row['quote']['USD']['percent_change_24h'] < -10:
                    buy_list.append((row['quote']['USD']['percent_change_24h'], row['symbol']))
                if row['quote']['USD']['percent_change_24h'] > 10:
                    sell_list.append((row['quote']['USD']['percent_change_24h'], row['symbol']))
        print(len(buy_list), sorted(buy_list, key=lambda tup: tup[0]))
        print(len(sell_list), sorted(sell_list, key=lambda tup: tup[0]))
    except (ConnectionError, Timeout, TooManyRedirects) as e:
        print(e)


if __name__ == '__main__':
    get_latest_listing()
