from datetime import datetime


def get_signals():
    with open('signals.csv') as fr:
        rows = [row.replace('\n', '') for row in fr.readlines()]
        signals = list()
        for row in rows:
            tokens = row.split(',')
            signal_id = tokens[0]
            signal_date = datetime.strptime(tokens[1], '%d.%m.%Y %H:%M:%S')
            symbol = tokens[2]
            operation = tokens[3]
            price = float(tokens[4])
            tp_1 = float(tokens[5])
            # tp_2 = float(tokens[6])
            # tp_3 = float(tokens[7])
            sl = float(tokens[8])

            if datetime.today().year == signal_date.year:
                if datetime.today().month == signal_date.month:
                    if datetime.today().day == signal_date.day:
                        signals.append({
                            'id': int(signal_id),
                            'symbol': symbol,
                            'operation': operation,
                            'price': price,
                            'tp_1': tp_1,
                            'sl': sl
                        })

    return signals
