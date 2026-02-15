FROM php:8.1-fpm
WORKDIR /var/www/html
RUN apt-get update && apt-get install -y git unzip && rm -rf /var/lib/apt/lists/*
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY . /var/www/html
RUN composer install --no-dev --no-interaction --optimize-autoloader
CMD ["php-fpm"]
EXPOSE 9000
