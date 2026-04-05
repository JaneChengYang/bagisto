FROM php:8.3-apache

RUN apt-get update && apt-get install -y \
    git curl zip unzip libpng-dev libonig-dev \
    libxml2-dev libzip-dev libicu-dev \
    && docker-php-ext-install \
    pdo pdo_mysql mbstring xml zip gd bcmath intl opcache calendar \
    && a2dismod mpm_event \
    && a2enmod mpm_prefork rewrite

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN composer install --optimize-autoloader --no-dev --no-interaction --ignore-platform-reqs

RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf

RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo 'echo "APP_NAME=Bagisto" > /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "APP_ENV=production" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "APP_KEY=" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "APP_URL=$APP_URL" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "DB_CONNECTION=mysql" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "DB_HOST=$DB_HOST" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "DB_PORT=$DB_PORT" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "DB_DATABASE=$DB_DATABASE" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "DB_USERNAME=$DB_USERNAME" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "DB_PASSWORD=$DB_PASSWORD" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "CACHE_DRIVER=file" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "SESSION_DRIVER=file" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "QUEUE_CONNECTION=sync" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'echo "LOG_CHANNEL=stderr" >> /var/www/html/.env' >> /entrypoint.sh && \
    echo 'php artisan key:generate --force' >> /entrypoint.sh && \
    echo 'php artisan migrate --force --seed' >> /entrypoint.sh && \
    echo 'exec apache2-foreground' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 80
CMD ["/entrypoint.sh"]
