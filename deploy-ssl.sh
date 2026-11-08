
#!/bin/bash

set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

DOMAIN="vikkychi.site"
EMAIL="victoronwuka07@gmail.com"

echo "======================================"
echo " BLOOMY AUTOMATED SSL DEPLOYMENT"
echo "======================================"

# Ensure required directories exist
mkdir -p nginx certbot/conf certbot/www

# Check required files
for file in nginx/init.conf nginx/prod.conf docker-compose.yml; do
    if [ ! -f "$file" ]; then
        echo "ERROR: Missing $file"
        exit 1
    fi
done

# Check whether SSL certificates already exist
if [ -f "certbot/conf/live/$DOMAIN/fullchain.pem" ] && \
   [ -f "certbot/conf/live/$DOMAIN/privkey.pem" ]; then

    echo "[1/5] Existing SSL certificate found."

else

    echo "[1/5] Preparing HTTP configuration..."

    # Apply temporary HTTP configuration
    cp nginx/init.conf nginx/current.conf

    # Start/recreate Nginx only
    sudo docker compose up -d --force-recreate nginx

    echo "[2/5] Waiting for Nginx..."

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

    echo "[3/5] Requesting SSL certificate..."

    sudo docker run --rm \
        -v "$PROJECT_DIR/certbot/conf:/etc/letsencrypt" \
        -v "$PROJECT_DIR/certbot/www:/var/www/certbot" \
        certbot/certbot certonly \
        --webroot \
        -w /var/www/certbot \
        -d "$DOMAIN" \
        -d "www.$DOMAIN" \
        -d "app.$DOMAIN" \
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

# Apply HTTPS configuration
echo "[4/5] Switching to HTTPS configuration..."

cp nginx/prod.conf nginx/current.conf

# Recreate Nginx only (application containers remain untouched)
echo "Applying production Nginx configuration..."

sudo docker compose up -d --force-recreate nginx

# Validate Nginx configuration
echo "Validating Nginx configuration..."

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

# Verify Nginx container
echo "[5/5] Checking Nginx container..."

if [ "$(sudo docker inspect -f '{{.State.Running}}' bloomy-nginx)" != "true" ]; then

    echo "ERROR: Nginx is not running."

    sudo docker logs bloomy-nginx --tail 50 || true
    exit 1
fi

echo "======================================"
echo " SSL DEPLOYMENT SUCCESSFUL!"
echo "======================================"

echo "Frontend: https://$DOMAIN"
echo "WWW:      https://www.$DOMAIN"
echo "Backend:  https://app.$DOMAIN"

echo "======================================"
echo " Application containers were not restarted."
echo "======================================"
