import asyncio
from aiohttp import web, WSMsgType
import os


async def websocket_handler(request):
    ws = web.WebSocketResponse()
    await ws.prepare(request)

    remote_addr = request.transport.get_extra_info('peername')
    print(f"WebSocket connection from {remote_addr}")

    # Add the WebSocket connection to a set to keep track of clients
    app = request.app
    app['websockets'].add(ws)

    # Receive and handle messages from the client
    async for msg in ws:
        if msg.type == WSMsgType.TEXT:
            print(f"Received WebSocket message: {msg.data}")

            # Send a response back to the client
            await ws.send_str(f"Received your message: {msg.data}")
        elif msg.type == WSMsgType.ERROR:
            break

    # Remove the WebSocket connection from the set when the connection is closed
    app['websockets'].remove(ws)
    print('f"WebSocket connection from {remote_addr} closed')

    return ws


async def health_check(request):
    return web.Response(text="OK", status=200)


async def main():
    print(f"Running main function...")
    # server configuration
    server_address = "0.0.0.0"
    server_port = int(os.environ.get("PORT", "8080"))

    app = web.Application()
    app.router.add_get('/ws', websocket_handler)
    app.router.add_get('/health', health_check)

    # Create a set to keep track of WebSocket connections
    app['websockets'] = set()

    runner = web.AppRunner(app)
    await runner.setup()

    site = web.TCPSite(runner, server_address, server_port)
    await site.start()

    print(
        f"Server started. Listening on http://{server_address}:{server_port}")

    # Keep the server running
    await asyncio.Event().wait()

if __name__ == "__main__":
    print(f"Starting application...")
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
