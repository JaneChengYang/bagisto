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

COPY .env.example .env

RUN php artisan key:generate --force

RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf

RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'php artisan migrate --force --seed' >> /entrypoint.sh && \
    echo 'exec apache2-foreground' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 80
CMD ["/entrypoint.sh"]
