import asyncio
import logging
import os
from aiohttp import web, WSMsgType

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

async def websocket_handler(request):
    ws = web.WebSocketResponse()
    await ws.prepare(request)

    remote_addr = request.transport.get_extra_info('peername')
    logging.info(f"WebSocket connection from {remote_addr}")

    app = request.app
    app['websockets'].add(ws)

    try:
        async for msg in ws:
            if msg.type == WSMsgType.TEXT:
                logging.info(f"Received WebSocket message: {msg.data}")
                await ws.send_str(f"Received your message: {msg.data}")
            elif msg.type == WSMsgType.ERROR:
                logging.error(f"WebSocket error: {ws.exception()}")
                break
    except Exception as e:
        logging.error(f"WebSocket error: {e}")
    finally:
        app['websockets'].remove(ws)
        logging.info(f"WebSocket connection from {remote_addr} closed")

    return ws

async def health_check(request):
    return web.Response(text="OK", status=200)

async def main():
    logging.info("Starting application...")

    # Load configuration from environment variables
    server_address = os.environ.get("SERVER_ADDRESS", "0.0.0.0")
    server_port = int(os.environ.get("SERVER_PORT", "8080"))

    app = web.Application()
    app.router.add_get('/ws', websocket_handler)
    app.router.add_get('/health', health_check)

    app['websockets'] = set()

    runner = web.AppRunner(app)
    await runner.setup()

    site = web.TCPSite(runner, server_address, server_port)
    await site.start()

    logging.info(f"Server started. Listening on http://{server_address}:{server_port}")

    # Keep the server running
    await asyncio.Event().wait()

if __name__ == "__main__":
    asyncio.run(main())
