FROM php:8.4-apache

ENV DB_HOST=mysql-service
ENV DB_USER=ecomuser
ENV DB_PASSWORD=ecompassword
ENV DB_NAME=ecomdb
ENV FEATURE_DARK_MODE=false

# Configure Apache DirectoryIndex to include index.php
RUN echo 'DirectoryIndex index.php index.html' > /etc/apache2/conf-enabled/index.conf

COPY . /var/www/html/
RUN docker-php-ext-install mysqli

WORKDIR /var/www/html/

EXPOSE 80