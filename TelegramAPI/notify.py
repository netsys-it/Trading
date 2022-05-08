import asyncio
import json
from telethon.sync import TelegramClient


loop = asyncio.new_event_loop()
asyncio.set_event_loop(loop)
for signal in signals:
    message = "{} Opened new order: {} - {} - {:.5f} - {:.2f}".format(signal.date, signal.symbol, json_data['signals'][signal_id]['signal_type'], signal.price, signal.lots)
    loop.run_until_complete(notify_telegram(message))
loop.close()


async def notify_telegram(message):
    async with TelegramClient('session', app.config['TELEGRAM_API_ID'], app.config['TELEGRAM_API_HASH']) as client:
        await client.send_message('me', message)
        
