# Basic WebSocket Server

This repository contains a simple Python application that functions as a WebSocket server, capable of receiving messages from both WebSocket clients and socket clients.

## Getting Started

### Prerequisites

Before running the server, ensure you have Python installed on your machine.

```bash
# Install required Python libraries
pip install websockets
```

## Running the Server

***Clone this repository:***

```bash
git clone https://github.com/your-username/basic-websocket-server.git
cd basic-websocket-server
```

***Run the server:***

```bash
git clone https://github.com/your-username/basic-websocket-server.git
cd basic-websocket-server
```

The server will start and listen for WebSocket connections on `ws://localhost:8765` and socket connections on `localhost:8888`.

## Usage

### WebSocket Communication

Connect to the WebSocket server using a WebSocket client and send/receive messages.

***Example using JavaScript and [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API):***

```bash
var socket = new WebSocket('ws://localhost:8765');

socket.onmessage = function(event) {
    console.log('Received message:', event.data);
};

socket.onopen = function(event) {
    console.log('WebSocket connection opened:', event);
};

// Send a message
socket.send('Hello, WebSocket!');

```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

This project is licensed under the [MIT License](https://chat.openai.com/c/LICENSE).
