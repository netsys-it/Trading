from datetime import datetime


def get_signals():
    with open('signals.csv') as fr:
        rows = [row.replace('\n', '') for row in fr.readlines()]
        signals = list()
        now = datetime.now()
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

            if now.year == signal_date.year:
                if now.month == signal_date.month:
                    if now.day == signal_date.day:
                        if now.hour - 4 <= signal_date.hour:
                            signals.append({
                                'id': int(signal_id),
                                'signal_date': str(signal_date),
                                'symbol': symbol,
                                'operation': operation,
                                'price': price,
                                'tp_1': tp_1,
                                'sl': sl
                            })

    return signals
