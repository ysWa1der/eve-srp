#!/bin/sh
set -e

# Create required directories
echo "Creating required directories..."
mkdir -p /app/storage/doctrine
mkdir -p /app/storage/compilation_cache
mkdir -p /app/storage/logs
mkdir -p /app/vendor            # ← 추가: vendor 디렉터리 강제 생성
mkdir -p /app/web/dist

# Relax permissions on /app so composer can write into vendor
echo "Fixing permissions for /app..."
chmod -R a+rwX /app/vendor /app/storage /app/web/dist

# Set ownership for storage directories (웹 실행 계정 기준으로 유지)
chown -R www-data:www-data /app/storage /app/web/dist || true

# Install composer dependencies if vendor directory doesn't exist or is empty
if [ ! -d "/app/vendor" ] || [ -z "$(ls -A /app/vendor 2>/dev/null)" ]; then
    echo "Installing composer dependencies..."
    # Run composer as root (container runs as root for Synology NAS compatibility)
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-interaction --optimize-autoloader
fi

# Wait for database to be ready
echo "Waiting for database to be ready..."
timeout=60
counter=0
while ! nc -z eve_srp_db 3306 2>/dev/null; do
    counter=$((counter + 1))
    if [ $counter -ge $timeout ]; then
        echo "Database connection timeout after ${timeout} seconds"
        break
    fi
    sleep 1
done

# Generate Doctrine proxies if not exists
if [ ! -d "/app/storage/doctrine" ] || [ -z "$(ls -A /app/storage/doctrine 2>/dev/null)" ]; then
    echo "Generating Doctrine proxy classes..."
    php /app/bin/doctrine orm:generate-proxies || echo "Warning: Failed to generate proxies"
    chown -R www-data:www-data /app/storage/doctrine || true
fi

# Run database migrations
if [ -f "/app/vendor/bin/doctrine-migrations" ]; then
    echo "Running database migrations..."
    php /app/vendor/bin/doctrine-migrations migrations:migrate --no-interaction || echo "Warning: Migration failed"
fi

# Execute the original command (php-fpm)
exec "$@"
