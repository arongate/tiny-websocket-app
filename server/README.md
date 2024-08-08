# Basic WebSocket Server

This is a simple WebSocket server application built using the `aiohttp` library in Python. The server listens for incoming WebSocket connections and echoes back any text messages received from clients.

## Features

* Handles WebSocket connections and text messages
* Logs incoming connections and messages
* Provides a health check endpoint (`/health`)
* Configurable server address and port via environment variables

## Requirements

* Python 3.7 or later
* Install python depencencies in a virutl env

  python -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt

## Usage

1. Set the following environment variables (optional):

    * `SERVER_ADDRESS`: The IP address or hostname to bind the server to (default: `0.0.0.0`)
    * `SERVER_PORT`: The port number to listen on (default: `8080`)

2. Run the server:

    python app.py

3. The server will start, and you should see a log message indicating the server address and port it's listening on.

## Testing

You can test the WebSocket server using a WebSocket client or a web browser with WebSocket support.

### Using a WebSocket Client

1. Install a WebSocket client tool like `wscat` ( `npm install -g wscat`).

2. Connect to the WebSocket server: `wscat -c ws://localhost:8080/ws`

3. Send a text message to the server, and you should see the server echo back the same message.

### Using a Web Browser

1. Open a web browser and navigate to `http://localhost:8080/ws`.

2. Open the browser's developer console.

3. Create a new WebSocket connection: `const ws = new WebSocket('ws://localhost:8080/ws');`

4. Set up event handlers for the WebSocket connection:

    ```javascript
    ws.onopen = () => {
    console.log('WebSocket connection opened');
    ws.send('Hello, server!');
    };

    ws.onmessage = (event) => {
    console.log('Received message:', event.data);
    };

    ws.onerror = (error) => {
    console.error('WebSocket error:', error);
    };

    ws.onclose = () => {
    console.log('WebSocket connection closed');
    };
    ```

5. You should see the server echo back the message you sent in the console.

## Health Check

The server provides a health check endpoint at `/health`. You can test it by sending an HTTP GET request to `http://localhost:8080/health`. The server should respond with `OK` and a `200` status code.
