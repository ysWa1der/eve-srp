#!/bin/sh
set -e

# Create required directories with proper permissions
echo "Creating required directories..."
mkdir -p /app/storage/doctrine
mkdir -p /app/storage/compilation_cache
mkdir -p /app/storage/logs
mkdir -p /app/vendor
mkdir -p /app/web/dist

# Fix permissions for all writable directories
echo "Fixing permissions for /app..."
chmod -R 777 /app/vendor /app/storage /app/web/dist 2>/dev/null || true

# Set ownership for storage directories
chown -R www-data:www-data /app/storage /app/web/dist 2>/dev/null || true

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
