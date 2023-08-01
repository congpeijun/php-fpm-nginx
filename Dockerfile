FROM composer as composer_base
WORKDIR /app
COPY ./app /app
# RUN composer install --ignore-platform-reqs -o --no-dev
RUN cd /tmp && wget https://wenda-1252906962.file.myqcloud.com/dist/swoole-cli-v5.0.3-linux-x64.tar.xz \
    && tar -Jxvf swoole-cli-v5.0.3-linux-x64.tar.xz

FROM nginx:stable-alpine

ARG S6_OVERLAY_VERSION=3.1.5.0

WORKDIR /app

ADD docker/rootfs/ /
COPY docker/fpm /etc/fpm
COPY docker/nginx/default.conf /etc/nginx/conf.d/

COPY --from=composer_base /app /app
COPY --from=composer_base /tmp/swoole-cli /usr/local/bin/

RUN apk add --no-cache tzdata ca-certificates \
    && for TARBALL in s6-overlay-noarch.tar.xz s6-overlay-x86_64.tar.xz s6-overlay-symlinks-noarch.tar.xz s6-overlay-symlinks-arch.tar.xz; do wget -qO- https://ghproxy.com/https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/$TARBALL | tar -xpvJ -C /; done \
    && echo "daemon off;" >> /etc/nginx/nginx.conf \
    && ln -s /usr/local/bin/swoole-cli  /usr/local/bin/php \
    && mkdir -p /usr/local/var/log && ln -s /dev/stdout /usr/local/var/log/php-fpm.log

EXPOSE 80

VOLUME [ "/etc/nginx/conf.d", "/etc/fpm" ]
ENTRYPOINT ["/init"]
