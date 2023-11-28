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
  region = "eu-west-1"
}

resource "aws_apprunner_connection" "github" {
  connection_name = "github"
  provider_type   = "GITHUB"

  tags = {
    Name = "github"
  }
}

resource "aws_apprunner_service" "websocketserver" {
  service_name = "websocket-server"

  source_configuration {
    authentication_configuration {
      connection_arn = aws_apprunner_connection.github.arn
    }
    code_repository {
      code_configuration {
        code_configuration_values {
          build_command = "python install websockets"
          port          = "8765"
          runtime       = "PYTHON_3"
          start_command = "python app.py"
        }
        configuration_source = "API"
      }
      repository_url = "git@github.com:arongate/basic-websocket-server.git"
      source_code_version {
        type  = "BRANCH"
        value = "main"
      }
    }
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
