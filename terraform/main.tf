terraform {
  required_version = "~> 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_apprunner_connection" "github" {
  connection_name = "github"
  provider_type   = "GITHUB"

  tags = {
    Name = "github"
  }
}

resource "aws_apprunner_observability_configuration" "xray" {
  observability_configuration_name = "xray"

  trace_configuration {
    vendor = "AWSXRAY"
  }
}

resource "aws_apprunner_service" "websocketserver" {
  service_name = "websocket-server"

  observability_configuration {
    observability_configuration_arn = aws_apprunner_observability_configuration.xray.arn
    observability_enabled           = true
  }

  source_configuration {
    authentication_configuration {
      connection_arn = aws_apprunner_connection.github.arn
    }
    code_repository {
      code_configuration {
        code_configuration_values {
          build_command = "pip install -r requirements.txt"
          port          = "8765"
          runtime       = "PYTHON_3"
          start_command = "python app.py"
          runtime_environment_variables = {
            PORT = "8765"
          }
        }
        configuration_source = "API"
      }
      repository_url = "https://github.com/arongate/tiny-websocket-app"
      source_code_version {
        type  = "BRANCH"
        value = "main"
      }
      source_directory = "server"
    }
  }

  health_check_configuration {
    interval            = 1
    healthy_threshold   = 1
    path                = "/health"
    protocol            = "HTTP"
    unhealthy_threshold = 3
  }

  network_configuration {
    ingress_configuration {
      is_publicly_accessible = true
    }
    egress_configuration {
      egress_type = "DEFAULT"
    }
  }

  tags = {
    Name = "websocket-server"
  }
}

output "service_url" {
  value = aws_apprunner_service.websocketserver.service_url
}
