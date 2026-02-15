FROM php:8.1-fpm
WORKDIR /var/www/html
RUN apt-get update && apt-get install -y libpng-dev libonig-dev libxml2-dev zip unzip git && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY . /var/www/html
RUN composer install --no-interaction --prefer-dist --optimize-autoloader
CMD ["php-fpm"]
EXPOSE 9000
