#!/bin/bash

# Nginx Compilation Script for Debian-based amd64 OS
# Source: https://github.com/xddxdd/dockerfiles/blob/master/dockerfiles/nginx/template.Dockerfile
# Run: bash ngx.sh
# Dependencies: checkinstall build-base git autoconf automake libtool wget tar gd-dev pcre-dev zlib-dev libatomic_ops-dev unzip patch linux-headers openldap-dev util-linux binutils
# Patches: 
#  - 
#  - https://github.com/hakasenyang/openssl-patch

NGINX_VERSION="1.21.3"
OPENSSL_VERSION="3.0.0"
PCRE_VERSION="10.38"
CURRENT_DATE=$(date +'%Y%m%d')

cd /tmp \
&& mkdir ngx-${NGINX_VERSION} \
&& cd ngx-${NGINX_VERSION} \
&& wget -q http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
&& tar xf nginx-${NGINX_VERSION}.tar.gz \
&& cd nginx-${NGINX_VERSION} \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx $NGINX_VERSION downloaded " \
&& echo "  *" \
&& echo "*" \
&& wget -q https://raw.githubusercontent.com/kn007/patch/master/nginx.patch \
&& patch -p1 < nginx.patch \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx Patched by kn007 " \
&& echo "  *" \
&& echo "*" \
&& wget -q https://raw.githubusercontent.com/kn007/patch/master/use_openssl_md5_sha1.patch \
&& patch -p1 < use_openssl_md5_sha1.patch \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx Patched by MD5 SHA1 patch " \
&& echo "  *" \
&& echo "*" \
&& cd .. \
&& git clone https://github.com/openresty/headers-more-nginx-module.git \
&& git clone https://github.com/grahamedgecombe/nginx-ct.git \
&& git clone https://github.com/eustas/ngx_brotli.git \
&& cd ngx_brotli \
&& git submodule update --init \
&& cd .. \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx Modules Downloaded " \
&& echo "  *" \
&& echo "*" \
&& git clone https://github.com/cloudflare/zlib.git \
&& cd zlib && make -f Makefile.in distclean && cd .. \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Zlib Downloaded & Compiled " \
&& echo "  *" \
&& echo "*" \
&& wget -q https://github.com/PhilipHazel/pcre2/releases/download/pcre2-${PCRE_VERSION}/pcre2-${PCRE_VERSION}.tar.gz \
&& tar xf pcre2-${PCRE_VERSION}.tar.gz \
&& echo "*" \
&& echo "  *" \
&& echo "    *  PCRE Downloaded " \
&& echo "  *" \
&& echo "*" \
&& wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
&& tar xf openssl-${OPENSSL_VERSION}.tar.gz \
&& echo "*" \
&& echo "  *" \
&& echo "    *  OpenSSL $OPENSSL_VERSION Downloaded " \
&& echo "  *" \
&& echo "*" \
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
--with-openssl=/tmp/ngx-${NGINX_VERSION}/openssl-${OPENSSL_VERSION} \
--with-openssl-opt="zlib no-tests enable-ec_nistp_64_gcc_128 enable-tls1_3" \
--with-cc-opt="-O3 -flto -fPIC -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wno-deprecated-declarations -Wno-strict-aliasing" \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx Configured " \
&& echo "  *" \
&& echo "*" \
&& make -j4 \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx Compiled " \
&& echo "  *" \
&& echo "*" \
&& checkinstall --pkgname=nginx --pkgversion=${NGINX_VERSION}-${CURRENT_DATE} --nodoc --install=no \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx DEB Package Created " \
&& echo "  *" \
&& echo "*"
