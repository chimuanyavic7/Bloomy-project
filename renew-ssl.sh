#!/bin/bash

set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "======================================"
echo " BLOOMY SSL CERTIFICATE RENEWAL"
echo "======================================"

echo "[1/3] Checking SSL certificate renewal..."

sudo docker run --rm \
    -v "$PROJECT_DIR/certbot/conf:/etc/letsencrypt" \
    -v "$PROJECT_DIR/certbot/www:/var/www/certbot" \
    certbot/certbot renew

echo "[2/3] Validating Nginx configuration..."

sudo docker exec bloomy-nginx nginx -t

echo "[3/3] Reloading Nginx..."

sudo docker exec bloomy-nginx nginx -s reload

echo "======================================"
echo " SSL RENEWAL CHECK COMPLETED!"
echo "======================================"