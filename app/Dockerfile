FROM php:8.4-apache

ENV DB_HOST=mysql-service
ENV DB_USER=ecomuser
ENV DB_PASSWORD=ecompassword
ENV DB_NAME=ecomdb
ENV FEATURE_DARK_MODE=false

COPY . /var/www/html/
RUN docker-php-ext-install mysqli

#unnecessary?
#RUN cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
#RUN sed -i 's/;extension=mysqli/extension=mysqli/' $PHP_INI_DIR/php.ini

WORKDIR /var/www/html/

EXPOSE 80

#legacy, troubleshooting
#CMD ["tail", "-f", "/dev/null"]