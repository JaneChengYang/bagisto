FROM php:8.3-apache

RUN apt-get update && apt-get install -y \
    git curl zip unzip libpng-dev libonig-dev \
    libxml2-dev libzip-dev libicu-dev \
    && docker-php-ext-install \
    pdo pdo_mysql mbstring xml zip gd bcmath intl opcache calendar \
    && a2dismod mpm_event mpm_worker mpm_prefork \
    && a2enmod mpm_prefork rewrite

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

RUN composer install --optimize-autoloader --no-dev --no-interaction --ignore-platform-reqs

RUN cat > /var/www/html/.env << 'EOF'
APP_NAME=Bagisto
APP_ENV=production
APP_KEY=
APP_URL=https://bagisto-production-893c.up.railway.app
DB_CONNECTION=mysql
DB_HOST=mysql.railway.internal
DB_PORT=3306
DB_DATABASE=railway
DB_USERNAME=root
DB_PASSWORD=ssOHJjBuikGQvqNyGtSmSaSFseFxIvna
CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync
LOG_CHANNEL=stderr
EOF

RUN php artisan key:generate --force

RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf

RUN printf '#!/bin/bash\nset -e\nphp artisan migrate --force\nexec apache2-foreground\n' \
    > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 80
CMD ["/entrypoint.sh"]
