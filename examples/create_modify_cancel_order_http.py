import asyncio
from utils import default_example_setup
import requests
import dotenv
import os
import time
from datetime import datetime, timezone

async def main():
    client, api_client, _ = default_example_setup(config_file=os.getenv("API_CONFIG_DIR"))
    client.check_client()

    dotenv.load_dotenv()
    BASE_URL = "https://bagendhq.xyz"
    ENDPOINT = "/backend/rate-limit-report"
    DB_URL = f"{BASE_URL}{ENDPOINT}"
    DB_KEY = os.getenv("DB_KEY")

    # Note: change this to 2048 to trade spot ETH. Make sure you have at least 0.1 ETH to trade spot.
    market_index = 0

    orders_api = client.order_api
    response = await orders_api.order_book_details(market_id=market_index)
    market_price = response.order_book_details[0].last_trade_price

    bid_price = int(market_price * (0.9/100) * 100_00)

    # create order
    api_key_index, nonce = client.nonce_manager.next_nonce()
    tx, tx_hash, err = await client.create_order(
        market_index=market_index,
        client_order_index=123,
        base_amount=1000,  # 0.1 ETH
        price=bid_price,  
        is_ask=False,
        order_type=client.ORDER_TYPE_LIMIT,
        time_in_force=client.ORDER_TIME_IN_FORCE_GOOD_TILL_TIME,
        reduce_only=False,
        nonce=nonce,
        api_key_index=api_key_index,
    )
    
    payload = {
    "rate_limits": [
        {
            "exchange": "lighter",
            "account": "main",
            "ts_us": datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S.%f%z'),
            "remaining": int(tx_hash.volume_quota_remaining),
        }
    ]
}

    # db_backend auth: Bearer header, never a ?key= query param.
    headers = {"Authorization": f"Bearer {DB_KEY}"}
    resp = requests.post(DB_URL, json=payload, headers=headers)
    if err is not None:
        raise Exception(err)

    ## cancel order
    # use the same API key so the TX goes after the modify order TX
    api_key_index, nonce = client.nonce_manager.next_nonce(api_key_index)
    tx, tx_hash, err = await client.cancel_order(
        market_index=market_index,
        order_index=123,
        nonce=nonce,
        api_key_index=api_key_index,
    )
    if err is not None:
        raise Exception(err)

    await client.close()
    await api_client.close()


if __name__ == "__main__":
    asyncio.run(main())
