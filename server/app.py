import asyncio
import websockets

async def handle_client(websocket, path):
    try:
        print(f"Client connected from {websocket.remote_address}")

        # Receive and handle messages from the client
        async for message in websocket:
            print(f"Received message: {message}")

            # Process the received message (you can add your logic here)
            response_message = f"Server received: {message}"

            # Send a response back to the client
            await websocket.send(response_message)
            print(f"Sent response: {response_message}")

    except websockets.exceptions.ConnectionClosedError:
        print(f"Connection with {websocket.remote_address} closed")

async def main():
    # WebSocket server configuration
    server_address = "localhost"
    server_port = 8765

    # Start the WebSocket server
    server = await websockets.serve(handle_client, server_address, server_port)
    print(f"WebSocket server started at ws://{server_address}:{server_port}")

    # Keep the server running
    await server.wait_closed()

if __name__ == "__main__":
    asyncio.run(main())
