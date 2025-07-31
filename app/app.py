#!/usr/bin/env python3
"""
Basic Python Flask Demo Application
A simple web application that demonstrates deployment to Azure App Service with Docker
"""

import os
import platform
import socket
import time
from datetime import datetime
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)

# Get the port from environment variable or default to 80
PORT = int(os.environ.get('PORT', 80))

# HTML template for the main page
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Python Demo App - Azure App Service</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 {
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .info-card {
            background: rgba(255, 255, 255, 0.2);
            padding: 20px;
            margin: 15px 0;
            border-radius: 10px;
            border-left: 4px solid #4CAF50;
        }
        .info-card h3 {
            margin-top: 0;
            color: #4CAF50;
        }
        .api-links {
            text-align: center;
            margin-top: 30px;
        }
        .api-links a {
            display: inline-block;
            margin: 10px;
            padding: 10px 20px;
            background: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.3s;
        }
        .api-links a:hover {
            background: #45a049;
        }
        .status {
            display: inline-block;
            padding: 5px 15px;
            background: #4CAF50;
            border-radius: 20px;
            font-weight: bold;
        }
        .demo-value {
            display: inline-block;
            padding: 5px 15px;
            background: #FF6B35;
            border-radius: 20px;
            font-weight: bold;
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐍 Python Demo App</h1>
        <div class="info-card">
            <h3>Application Status</h3>
            <p>Status: <span class="status">Running</span></p>
            <p>Timestamp: {{ timestamp }}</p>
            <p>Environment: {{ environment }}</p>
            <p>Demo Value: <span class="demo-value">{{ demo_value }}</span></p>
        </div>
        
        <div class="info-card">
            <h3>System Information</h3>
            <p><strong>Hostname:</strong> {{ hostname }}</p>
            <p><strong>Platform:</strong> {{ platform }}</p>
            <p><strong>Python Version:</strong> {{ python_version }}</p>
            <p><strong>Architecture:</strong> {{ architecture }}</p>
        </div>
        
        <div class="info-card">
            <h3>Azure App Service Demo</h3>
            <p>This is a simple Python Flask application running on Azure App Service with Docker.</p>
            <p>The application demonstrates:</p>
            <ul>
                <li>Python Flask web framework</li>
                <li>Docker containerization</li>
                <li>Azure Container Registry integration</li>
                <li>Health check endpoints</li>
                <li>Environment configuration</li>
                <li>Environment variable display (DEMO_VALUE)</li>
            </ul>
        </div>
        
        <div class="api-links">
            <a href="/health">Health Check</a>
            <a href="/api/info">System Info API</a>
            <a href="/api/status">Status API</a>
        </div>
    </div>
</body>
</html>
"""

@app.route('/')
def home():
    """Main page with system information"""
    demo_value = os.environ.get('DEMO_VALUE', 'Not Set')
    return render_template_string(HTML_TEMPLATE,
        timestamp=datetime.now().isoformat(),
        environment=os.environ.get('FLASK_ENV', 'production'),
        hostname=socket.gethostname(),
        platform=f"{platform.system()} {platform.release()}",
        python_version=platform.python_version(),
        architecture=platform.machine(),
        demo_value=demo_value
    )

@app.route('/health')
def health_check():
    """Health check endpoint for Azure App Service"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'python-demo-app'
    }), 200

@app.route('/api/info')
def api_info():
    """API endpoint with system information"""
    return jsonify({
        'hostname': socket.gethostname(),
        'platform': platform.system(),
        'platform_release': platform.release(),
        'architecture': platform.machine(),
        'python_version': platform.python_version(),
        'python_implementation': platform.python_implementation(),
        'uptime': time.time(),
        'environment': os.environ.get('FLASK_ENV', 'production'),
        'port': PORT,
        'demo_value': os.environ.get('DEMO_VALUE', 'Not Set')
    })

@app.route('/api/status')
def api_status():
    """Simple status API endpoint"""
    return jsonify({
        'message': 'Hello from Azure App Service with Python and Docker!',
        'timestamp': datetime.now().isoformat(),
        'environment': os.environ.get('FLASK_ENV', 'production'),
        'version': '1.0.0',
        'framework': 'Flask',
        'language': 'Python',
        'demo_value': os.environ.get('DEMO_VALUE', 'Not Set')
    })

@app.errorhandler(404)
def not_found(error):
    """404 error handler"""
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested endpoint was not found',
        'status_code': 404
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """500 error handler"""
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An internal server error occurred',
        'status_code': 500
    }), 500

if __name__ == '__main__':
    print(f"Starting Python Demo App on port {PORT}")
    print(f"Environment: {os.environ.get('FLASK_ENV', 'production')}")
    print(f"Platform: {platform.system()} {platform.release()}")
    print(f"Demo Value: {os.environ.get('DEMO_VALUE', 'Not Set')}")
    
    # Run the Flask app
    app.run(
        host='0.0.0.0',
        port=PORT,
        debug=os.environ.get('FLASK_ENV') == 'development'
    )
