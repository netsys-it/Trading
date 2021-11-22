from telethon.sync import TelegramClient
from telethon import events
from datetime import datetime, timedelta


api_id = XXXXX
api_hash = "XXXXX"
chanel_id = XXXXX
session_file_path = "login.session"
done_path = "done.txt"
export_path = "signals.csv"
take_profits_path = "take_profits.csv"
phone = "+XXXXX"
client = TelegramClient(session_file_path, api_id, api_hash)

try:
    with open(done_path) as f:
        done = [int(row.replace("\n", "")) for row in f.readlines()]
except FileNotFoundError:
    done = list()


@client.on(events.NewMessage)
async def parse_message(event):
    if event.message.to_id.channel_id == chanel_id:
        if event.message.message:
            if event.message.id not in done:
                with open(done_path, "a") as f:
                    f.write("{}\n".format(event.message.id))
            position = None
            tp_1_price = None
            tp_2_price = None
            tp_3_price = None
            sl_price = None
            symbol = None
            price = None
            for row_data in event.message.message.split("\n"):
                if "@" in row_data and "Buy" in row_data and "#" not in row_data and "Buy 2" not in row_data and "Buy 1" not in row_data:
                    tokens = row_data.split(" ")
                    symbol = tokens[1]
                    price = tokens[-1]
                    position = "BUY"
                    message_date = (event.message.date + timedelta(hours=2)).strftime("%d.%m.%Y %H:%M:%S")
                if "@" in row_data and "Sell" in row_data and "#" not in row_data and "Sell 2" not in row_data and "Sell 1" not in row_data:
                    tokens = row_data.split(" ")
                    symbol = tokens[1]
                    price = tokens[-1]
                    position = "SELL"
                    message_date = (event.message.date + timedelta(hours=2)).strftime("%d.%m.%Y %H:%M:%S")
                if "Take profit 1" in row_data:
                    tp_1_price = row_data.replace("Take profit 1 at ", "").replace(" ", "")
                if "Take profit 2" in row_data:
                    tp_2_price = row_data.replace("Take profit 2 at ", "").replace(" ", "")
                if "Take profit 3" in row_data:
                    tp_3_price = row_data.replace("Take profit 3 at ", "").replace(" ", "")
                if "Stop loss" in row_data:
                    sl_price = row_data.replace("Stop loss at ", "").replace(" ", "")
                if "Hit TP" in row_data:
                    symbol = row_data.split(" ")[0]
                    signal_date = "{} {}".format(row_data.split("( ")[1].split(" )")[0].replace(".", ""),
                                                 event.message.date.year)
                    signal_date = datetime.strptime(signal_date, "%d %b %Y")
                    hit_tp = f'TP{row_data.split("TP")[1].split(" ")[0]}'
                    with open(take_profits_path, 'a') as fw:
                        fw.write(f'{signal_date},{symbol},{hit_tp}\n')
                if "Hit SL" in row_data:
                    symbol = row_data.split(" ")[0]
                    signal_date = "{} {}".format(row_data.split("( ")[1].split(" )")[0].replace(".", ""),
                                                 event.message.date.year)
                    signal_date = datetime.strptime(signal_date, "%d %b %Y")
                    hit_tp = 'SL'
                    with open(take_profits_path, 'a') as fw:
                        fw.write(f'{signal_date},{symbol},{hit_tp}\n')
            if price:
                with open(export_path, "a", encoding="utf-8") as fw:
                    message_date = event.message.date.strftime("%d.%m.%Y %H:%M:%S")
                    print("{},{},{},{},{},{},{},{},{}\n".format(event.message.id, message_date, symbol,
                                                              position,
                                                              price,
                                                              tp_1_price,
                                                              tp_2_price,
                                                              tp_3_price,
                                                              sl_price))
                    fw.write(
                        "{},{},{},{},{},{},{},{},{}\n".format(event.message.id, message_date, symbol,
                                                              position,
                                                              price,
                                                              tp_1_price,
                                                              tp_2_price,
                                                              tp_3_price,
                                                              sl_price))


if __name__ == '__main__':
    client.connect()
    if not client.is_user_authorized():
        client.send_code_request(phone)
        client.sign_in(phone, input('Enter the code: '))
    client.start()
    client.run_until_disconnected()
