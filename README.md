# WebSocket App with AWS App Runner Deployment

This repository contains a WebSocket application with a client, server, and Terraform code for deploying the server on AWS App Runner.

## Project Structure

### Client

The `client` folder contains a minimalist WebSocket client written in HTML.

- **File:**
  - `index.html`: HTML file for the WebSocket client.

### Server

The `server` folder contains a minimalist WebSocket server written in Python.

- **File:**
  - `app.py`: Python script for the WebSocket server.

### Terraform

The `terraform` folder contains Terraform code for deploying the solution:

- Backend

  With in any of the following ways
  - in App Runner
  - as an ECS Task in an ECS cluster behind a load balancer

- Frontend

  - as a Static Single page application uploaded in an s3 bucket and distributed using a Cloudfront distribution.

## Getting Started

Follow the instructions in each folder to set up and run the WebSocket client, WebSocket server, and deploy the server on AWS App Runner.

- [Client Setup](./client/README.md)
- [Server Setup](./server/README.md)
- [AWS App Runner Deployment](./terraform/apprunner/README.md)
- [ECS Deployment](./terraform/ecs/README.md)
- [Cloudfront Distribution Deployment](./terraform/cloudfront/README.md)

## Contributing

Contributions are welcome! If you find issues or want to enhance the project, feel free to open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).
