#!/bin/bash

set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

DOMAIN="vikkychi.site"
EMAIL="victoronwuka07@gmail.com"

echo "======================================"
echo " BLOOMY AUTOMATED SSL DEPLOYMENT"
echo "======================================"

# Ensure directories exist
mkdir -p nginx certbot/conf certbot/www

# Check required files
for file in nginx/init.conf nginx/prod.conf docker-compose.yml; do
    if [ ! -f "$file" ]; then
        echo "ERROR: Missing $file"
        exit 1
    fi
done

# Start application containers
echo "[1/7] Starting application containers..."

sudo docker compose up -d java myportfolio

# Check existing certificate
if [ -f "certbot/conf/live/$DOMAIN/fullchain.pem" ] && \
   [ -f "certbot/conf/live/$DOMAIN/privkey.pem" ]; then

    echo "[2/7] Existing SSL certificate found."

else

    echo "[2/7] Preparing HTTP configuration..."

    cp nginx/init.conf nginx/current.conf

    sudo docker compose up -d --force-recreate nginx

    echo "[3/7] Waiting for Nginx..."

    READY=0

    for i in $(seq 1 30); do
        if sudo docker exec bloomy-nginx nginx -t >/dev/null 2>&1; then
            READY=1
            break
        fi
        sleep 2
    done

    if [ "$READY" -ne 1 ]; then
        echo "ERROR: Nginx failed to start."
        sudo docker logs bloomy-nginx --tail 50 || true
        exit 1
    fi

    echo "[4/7] Requesting SSL certificate..."

    sudo docker run --rm \
        -v "$PROJECT_DIR/certbot/conf:/etc/letsencrypt" \
        -v "$PROJECT_DIR/certbot/www:/var/www/certbot" \
        certbot/certbot certonly \
        --webroot \
        -w /var/www/certbot \
        -d vikkychi.site \
        -d www.vikkychi.site \
        -d app.vikkychi.site \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email

    # Verify certificate generation
    if [ ! -f "certbot/conf/live/$DOMAIN/fullchain.pem" ] || \
       [ ! -f "certbot/conf/live/$DOMAIN/privkey.pem" ]; then
        echo "ERROR: SSL certificate was not generated."
        exit 1
    fi

fi

# Switch to HTTPS configuration
echo "[5/7] Switching to HTTPS configuration..."

cp nginx/prod.conf nginx/current.conf

# Restart Nginx with production configuration
echo "[6/7] Applying production configuration..."

sudo docker compose up -d --force-recreate nginx

# Wait for Nginx and validate
READY=0

for i in $(seq 1 30); do
    if sudo docker exec bloomy-nginx nginx -t >/dev/null 2>&1; then
        READY=1
        break
    fi
    sleep 2
done

if [ "$READY" -ne 1 ]; then
    echo "ERROR: Production Nginx configuration is invalid."
    sudo docker logs bloomy-nginx --tail 50 || true
    exit 1
fi

# Verify container
echo "[7/7] Checking Nginx container..."

if [ "$(sudo docker inspect -f '{{.State.Running}}' bloomy-nginx)" != "true" ]; then
    echo "ERROR: Nginx is not running."
    sudo docker logs bloomy-nginx --tail 50
    exit 1
fi

echo "======================================"
echo " SSL DEPLOYMENT SUCCESSFUL!"
echo "======================================"

echo "Frontend: https://vikkychi.site"
echo "WWW:      https://www.vikkychi.site"
echo "Backend:  https://app.vikkychi.site"