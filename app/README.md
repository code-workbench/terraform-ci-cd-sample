# Python Demo App

A simple Python Flask application designed for deployment to Azure App Service with Docker.

## Features

- **Flask Web Framework**: Lightweight and powerful Python web framework
- **Docker Support**: Containerized application ready for Azure App Service
- **Health Checks**: Built-in health check endpoints for monitoring
- **System Information**: Displays system and environment information
- **Responsive UI**: Clean, modern web interface
- **Production Ready**: Uses Gunicorn as WSGI server for production deployment

## Endpoints

- `/` - Main page with system information and demo interface
- `/health` - Health check endpoint (returns JSON status)
- `/api/info` - System information API endpoint
- `/api/status` - Application status API endpoint

## Local Development

### Prerequisites

- Python 3.11 or higher
- pip (Python package installer)

### Setup

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the application:
   ```bash
   python app.py
   ```

3. Open your browser and navigate to `http://localhost:80`

### Development Mode

For development with auto-reload:
```bash
export FLASK_ENV=development
python app.py
```

## Docker Deployment

### Build the Docker image:
```bash
docker build -t python-demo-app .
```

### Run the container:
```bash
docker run -p 80:80 python-demo-app
```

## Azure Deployment

This application is designed to work with the Terraform configuration in the parent directory. Use the deployment script:

```bash
# From the project root
./scripts/deploy-docker-app.sh build-push ./app
```

## Environment Variables

- `PORT`: Port number for the application (default: 80)
- `FLASK_ENV`: Flask environment mode (development/production)

## Dependencies

- **Flask 2.3.3**: Web framework
- **Werkzeug 2.3.7**: WSGI utilities
- **Gunicorn 21.2.0**: Production WSGI server

## Security Features

- Runs as non-root user in Docker container
- Production-grade WSGI server (Gunicorn)
- Error handling and proper HTTP status codes
- Health check endpoints for monitoring
