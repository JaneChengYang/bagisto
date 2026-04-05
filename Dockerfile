FROM php:8.3-cli

RUN apt-get update && apt-get install -y \
    git curl zip unzip libpng-dev libonig-dev \
    libxml2-dev libzip-dev libicu-dev libwebp-dev \
    && docker-php-ext-configure gd --with-webp \
    && docker-php-ext-install \
    pdo pdo_mysql mbstring xml zip gd bcmath intl opcache calendar

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /var/www/html
COPY . .

RUN composer install --optimize-autoloader --no-dev --no-interaction --ignore-platform-reqs
RUN composer require league/flysystem-aws-s3-v3 --no-interaction --ignore-platform-reqs

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
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=4dcd092b37f8d0a3ecf5696e084943bc
AWS_SECRET_ACCESS_KEY=aea553e3934fa34dfda118bceb2518e5778211b6b9fc2eb6374e71af6ee58054
AWS_DEFAULT_REGION=auto
AWS_BUCKET=bagisto-storage
AWS_ENDPOINT=https://dcf82d8068cc6364132b9f15397e7d82.r2.cloudflarestorage.com
AWS_USE_PATH_STYLE_ENDPOINT=true
EOF

RUN php artisan key:generate --force

RUN printf '#!/bin/bash\nset -e\nphp artisan migrate --force\nrm -f /var/www/html/public/storage\nln -s /var/www/html/storage/app/public /var/www/html/public/storage\nchmod -R 777 /var/www/html/storage\nexec php artisan serve --host=0.0.0.0 --port=8080\n' \
    > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 8080
CMD ["/entrypoint.sh"]
