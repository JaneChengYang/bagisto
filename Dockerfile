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

RUN printf '#!/bin/bash\nset -e\n\
cp .env.example .env\n\
echo "APP_KEY=" >> .env\n\
echo "DB_CONNECTION=mysql" >> .env\n\
echo "DB_HOST=$DB_HOST" >> .env\n\
echo "DB_PORT=$DB_PORT" >> .env\n\
echo "DB_DATABASE=$DB_DATABASE" >> .env\n\
echo "DB_USERNAME=$DB_USERNAME" >> .env\n\
echo "DB_PASSWORD=$DB_PASSWORD" >> .env\n\
echo "APP_URL=$APP_URL" >> .env\n\
echo "CACHE_DRIVER=file" >> .env\n\
echo "SESSION_DRIVER=file" >> .env\n\
php artisan key:generate --force\n\
php artisan migrate --force --seed\n\
exec apache2-foreground\n' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

EXPOSE 80
CMD ["/entrypoint.sh"]
