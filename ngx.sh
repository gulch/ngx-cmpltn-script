#!/bin/bash

# Nginx Compilation Script for Debian-based amd64 OS
# source: https://github.com/xddxdd/dockerfiles/blob/master/dockerfiles/nginx/template.Dockerfile
# Run: bash ngx.sh
# dependencies: checkinstall build-base git autoconf automake libtool wget tar gd-dev pcre-dev zlib-dev libatomic_ops-dev unzip patch linux-headers openldap-dev util-linux binutils

NGINX_VERSION="1.17.9"
OPENSSL_VERSION="1.1.1d"

cd /tmp \
&& mkdir ngx-${NGINX_VERSION} \
&& cd ngx-${NGINX_VERSION} \
&& wget -q http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
&& tar xf nginx-${NGINX_VERSION}.tar.gz \
&& cd nginx-${NGINX_VERSION} \
&& echo " ===== Nginx $NGINX_VERSION downloaded =====" \
&& wget -q https://raw.githubusercontent.com/kn007/patch/master/nginx_with_spdy.patch \
&& patch -p1 < nginx_with_spdy.patch \
&& echo " ===== Nginx Patched =====" \
&& wget -q https://github.com/hakasenyang/openssl-patch/raw/master/nginx_strict-sni_1.15.10.patch \
&& patch -p1 < nginx_strict-sni_1.15.10.patch \
&& echo " ===== Nginx Patched by SNI patch =====" \
&& wget -q https://gist.github.com/CarterLi/f6e21d4749984a255edc7b358b44bf58/raw/4a7ad66a9a29ffade34d824549ed663bc4b5ac98/use_openssl_md5_sha1.diff \
&& patch -p1 < use_openssl_md5_sha1.diff \
&& echo " ===== Nginx Patched by MD5 SHA1 patch =====" \
&& cd .. \
&& git clone https://github.com/eustas/ngx_brotli.git \
&& cd ngx_brotli \
&& git submodule update --init \
&& cd .. \
&& echo " ===== Nginx Brotli Module Downloaded =====" \
&& git clone https://github.com/cloudflare/zlib.git \
&& cd zlib && make -f Makefile.in distclean && cd .. \
&& echo " ===== Zlib Downloaded =====" \
&& wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
&& tar xf openssl-${OPENSSL_VERSION}.tar.gz \
&& echo " ===== OpenSSL $OPENSSL_VERSION Downloaded =====" \
&& cd openssl-${OPENSSL_VERSION} \
&& wget -q https://github.com/hakasenyang/openssl-patch/raw/master/openssl-equal-1.1.1d.patch \
&& patch -p1 < openssl-equal-1.1.1d.patch \
&& echo " ===== OpenSSL Patched =====" \
&& wget -q https://github.com/hakasenyang/openssl-patch/raw/master/openssl-1.1.1d-chacha_draft.patch \
&& patch -p1 < openssl-1.1.1d-chacha_draft.patch \
&& echo " ===== OpenSSL Patched by ChaCha Patch =====" \
&& cd .. \
&& git clone https://github.com/openresty/headers-more-nginx-module.git \
&& echo " ===== Nginx Headers More Module Downloaded =====" \
&& git clone https://github.com/grahamedgecombe/nginx-ct.git \
&& echo " ===== Nginx CT Module Downloaded =====" \
&& cd nginx-${NGINX_VERSION} \
&& ./configure \
--prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--user=www-data \
--group=www-data \
--with-threads \
--with-file-aio \
--with-http_addition_module \
--with-http_auth_request_module \
--with-http_gzip_static_module \
--with-http_realip_module \
--with-http_spdy_module \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_sub_module \
--with-http_v2_module \
--with-http_v2_hpack_enc \
--with-libatomic \
--with-zlib=/tmp/ngx-${NGINX_VERSION}/zlib \
--add-module=/tmp/ngx-${NGINX_VERSION}/ngx_brotli \
--add-module=/tmp/ngx-${NGINX_VERSION}/headers-more-nginx-module \
--add-module=/tmp/ngx-${NGINX_VERSION}/nginx-ct \
--with-openssl=/tmp/ngx-${NGINX_VERSION}/openssl-1.1.1d \
--with-openssl-opt="zlib no-tests enable-ec_nistp_64_gcc_128 enable-tls1_3" \
--with-cc-opt="-O3 -flto -fPIC -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wno-deprecated-declarations -Wno-strict-aliasing" \
&& echo " ===== Nginx Configured =====" \
&& make -j4 \
&& echo " ===== Nginx Compiled =====" \
&& checkinstall --pkgname=nginx --pkgversion=${NGINX_VERSION}-47GULCH --nodoc --install=no \
&& echo " ===== Nginx Package Created ====="
