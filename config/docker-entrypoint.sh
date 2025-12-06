#!/bin/sh
set -e

# Create required storage directories if they don't exist
mkdir -p /app/storage/doctrine
mkdir -p /app/storage/compilation_cache
mkdir -p /app/storage/logs

# Set proper ownership for storage directories
chown -R www-data:www-data /app/storage/doctrine
chown -R www-data:www-data /app/storage/compilation_cache
chown -R www-data:www-data /app/storage/logs

# Install composer dependencies if vendor directory doesn't exist or is empty
if [ ! -d "/app/vendor" ] || [ -z "$(ls -A /app/vendor 2>/dev/null)" ]; then
    echo "Installing composer dependencies..."
    su-exec www-data composer install --no-interaction --optimize-autoloader
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
    su-exec www-data php /app/bin/doctrine orm:generate-proxies || echo "Warning: Failed to generate proxies"
fi

# Run database migrations
if [ -f "/app/vendor/bin/doctrine-migrations" ]; then
    echo "Running database migrations..."
    su-exec www-data php /app/vendor/bin/doctrine-migrations migrations:migrate --no-interaction || echo "Warning: Migration failed"
fi

# Execute the original command (php-fpm)
exec "$@"
