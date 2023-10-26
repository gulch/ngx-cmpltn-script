#!/bin/bash

# Nginx Compilation Script for Debian-based amd64 OS
# Source: https://github.com/xddxdd/dockerfiles/blob/master/dockerfiles/nginx/template.Dockerfile
# Run: bash ngx.sh
# Dependencies: checkinstall git autoconf automake libtool wget tar unzip patch libpcre3-dev zlib1g-dev libatomic-ops-dev libpcre2-dev
#
# Patches: 
#  - 
#  - https://github.com/kn007/patch
#  - https://github.com/xddxdd/dockerfiles/tree/master/dockerfiles/nginx

NGINX_VERSION="1.25.4-QUIC"

CURRENT_DATE=$(date +'%Y%m%d')

DIR_NAME=nginx-${CURRENT_DATE}

PROJECT_DIR=/tmp/${DIR_NAME}

echo ">>"
echo ">>>>>  Clone nginx repository  >>>>> "
echo ">>"

hg clone https://hg.nginx.org/nginx ${DIR_NAME}

cd ${PROJECT_DIR}

echo ">>"
echo ">>>>>  Patch nginx: use_openssl_md5_sha1.patch  >>>>> "
echo ">>"
wget -q https://raw.githubusercontent.com/kn007/patch/master/use_openssl_md5_sha1.patch
patch -p1 < use_openssl_md5_sha1.patch


echo ">>"
echo ">>>>>  Patch nginx: Dynamic TLS Record Support  >>>>> "
echo ">>"
wget -q https://raw.githubusercontent.com/kn007/patch/master/nginx_dynamic_tls_records.patch
patch -p1 < nginx_dynamic_tls_records.patch

echo ">>"
echo ">>>>>  Patch nginx: nginx-start-time.patch  >>>>> "
echo ">>"
wget -q https://raw.githubusercontent.com/gulch/ngx-cmpltn-script/master/nginx-start-time.patch
patch -p1 < nginx-start-time.patch


echo ">>"
echo ">>>>>  Zlib  >>>>> "
echo ">>"
git clone https://github.com/cloudflare/zlib.git
cd zlib && make -f Makefile.in distclean && cd ..


echo ">>"
echo ">>>>>  nginx module: Brotli  >>>>> "
echo ">>"
git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli
cd ngx_brotli/deps/brotli && mkdir out && cd out
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..
cmake --build . --config Release --target brotlienc
cd ${PROJECT_DIR}


echo ">>"
echo ">>>>>  nginx module: Headers More  >>>>> "
echo ">>"
git clone https://github.com/openresty/headers-more-nginx-module.git


echo ">>"
echo ">>>>>  nginx module: Certificate Transparency  >>>>> "
echo ">>"
git clone https://github.com/grahamedgecombe/nginx-ct.git


echo ">>"
echo ">>>>>  BoringSSL  >>>>> "
echo ">>"
git clone https://boringssl.googlesource.com/boringssl
cd boringssl && mkdir build && cd build && cmake .. && make
# create link to includes
mkdir -p ${PROJECT_DIR}/boringssl/.openssl/lib
cd ${PROJECT_DIR}/boringssl/.openssl
ln -s ../include include
# copy the BoringSSL crypto libraries to .openssl/lib so nginx can find them
cd ${PROJECT_DIR}/boringssl
cp build/crypto/libcrypto.a .openssl/lib
cp build/ssl/libssl.a .openssl/lib

cd ${PROJECT_DIR}

echo ">>"
echo ">>>>>  Generate nginx config >>>>> "
echo ">>"
auto/configure \
--prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--user=www-data \
--group=www-data \
--without-http_autoindex_module \
--without-http_browser_module \
--without-http_empty_gif_module \
--without-http_geo_module \
--without-http_grpc_module \
--without-http_memcached_module \
--without-http_mirror_module \
--without-http_referer_module \
--without-http_scgi_module \
--without-http_split_clients_module \
--without-http_ssi_module \
--without-http_upstream_hash_module \
--without-http_upstream_ip_hash_module \
--without-http_upstream_keepalive_module \
--without-http_upstream_least_conn_module \
--without-http_upstream_random_module \
--without-http_upstream_zone_module \
--without-http_userid_module \
--without-http_uwsgi_module \
--without-poll_module \
--without-select_module \
--with-compat \
--with-threads \
--with-file-aio \
--with-http_auth_request_module \
--with-http_gzip_static_module \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_v3_module \
--with-libatomic \
--with-zlib=${PROJECT_DIR}/zlib \
--add-module=${PROJECT_DIR}/ngx_brotli \
--add-module=${PROJECT_DIR}/headers-more-nginx-module \
--add-module=${PROJECT_DIR}/nginx-ct \
--with-openssl-opt="zlib no-tests" \
--with-cc-opt="-I $PROJECT_DIR/boringssl/include -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC -DTCP_FASTOPEN=23" \
--with-ld-opt="-L $PROJECT_DIR/boringssl/build/ssl -L $PROJECT_DIR/boringssl/build/crypto -Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie"

read -p "Press ENTER to start compilation..." && make -j$(nproc)

echo ">>"
echo ">>>>>  Create DEB package >>>>>"
echo ">>"
checkinstall -y --type=debian --pkgname=nginx --pkgversion=${NGINX_VERSION}-${CURRENT_DATE} --nodoc --install=no

echo ">>"
echo ">>>>>  DONE 🎉 >>>>>"
echo ">>
