#!/bin/bash

# Nginx Compilation Script for Debian-based amd64 OS
# Source: https://github.com/xddxdd/dockerfiles/blob/master/dockerfiles/nginx/template.Dockerfile
# Run: bash ngx.sh
# Dependencies: checkinstall build-base git autoconf automake libtool wget tar gd-dev pcre-dev zlib-dev libatomic_ops-dev unzip patch linux-headers util-linux binutils libunwind-dev golang
# Patches: 
#  - 
#  - https://github.com/kn007/patch
#  - https://github.com/xddxdd/dockerfiles/tree/master/dockerfiles/nginx

NGINX_VERSION="1.21.3-quic"
CURRENT_DATE=$(date +'%Y%m%d')


cd /tmp \
&& git clone https://boringssl.googlesource.com/boringssl \
&& cd boringssl \
&& mkdir build && cd build \
&& cmake -GNinja .. \
&& ninja -j2 \
&& echo "*" \
&& echo "  *" \
&& echo "    *  BoringSSL downloaded & compiled " \
&& echo "  *" \
&& echo "*" \
&& cd /tmp \
&& git clone https://github.com/VKCOM/nginx-quic.git \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx QUIC downloaded " \
&& echo "  *" \
&& echo "*" \
&& cd nginx-quic \
&& wget -q https://raw.githubusercontent.com/kn007/patch/master/use_openssl_md5_sha1.patch \
&& patch -p1 < use_openssl_md5_sha1.patch \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx patched: use_openssl_md5_sha1.patch " \
&& echo "  *" \
&& echo "*" \
&& wget -q https://raw.githubusercontent.com/kn007/patch/master/Enable_BoringSSL_OCSP.patch \
&& patch -p1 < Enable_BoringSSL_OCSP.patch \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx patched: Enable_BoringSSL_OCSP.patch " \
&& echo "  *" \
&& echo "*" \
&& wget -q https://raw.githubusercontent.com/xddxdd/dockerfiles/master/dockerfiles/nginx/patches/patch-nginx/nginx-hpack-dyntls.patch \
&& patch -p1 < nginx-hpack-dyntls.patch \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx patched: nginx-hpack-dyntls.patch " \
&& echo "  *" \
&& echo "*" \
&& git clone https://github.com/eustas/ngx_brotli.git \
&& cd ngx_brotli \
&& git submodule update --init \
&& cd .. \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx Brotli module downloaded " \
&& echo "  *" \
&& echo "*" \
&& git clone https://github.com/cloudflare/zlib.git \
&& cd zlib && make -f Makefile.in distclean && cd .. \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Zlib downloaded & compiled " \
&& echo "  *" \
&& echo "*" \
&& git clone https://github.com/openresty/headers-more-nginx-module.git \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx Headers More module downloaded " \
&& echo "  *" \
&& echo "*" \
&& git clone https://github.com/grahamedgecombe/nginx-ct.git \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx CT module downloaded " \
&& echo "  *" \
&& echo "*" \
&& auto/configure \
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
--with-http_v3_module \
--with-libatomic \
--with-zlib=/tmp/nginx-quic/zlib \
--add-module=/tmp/nginx-quic/ngx_brotli \
--add-module=/tmp/nginx-quic/headers-more-nginx-module \
--add-module=/tmp/nginx-quic/nginx-ct \
--with-cc-opt="-I/tmp/boringssl/include" \
--with-ld-opt="-L/tmp/boringssl/build/ssl -L/tmp/boringssl/build/crypto" \
&& make \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx configured & compiled " \
&& echo "  *" \
&& echo "*" \
&& checkinstall --pkgname=nginx --pkgversion=${NGINX_VERSION}-${CURRENT_DATE} --nodoc --install=no \
&& echo "*" \
&& echo "  *" \
&& echo "    *  Nginx deb package created " \
&& echo "  *" \
&& echo "*"
