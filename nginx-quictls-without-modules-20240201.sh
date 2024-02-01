#!/bin/bash

# Nginx Compilation Script for Debian-based amd64 OS
# Source: https://github.com/xddxdd/dockerfiles/blob/master/dockerfiles/nginx/template.Dockerfile
# Run: bash ngx.sh
# Dependencies: mercurial git checkinstall autoconf automake libtool wget unzip patch libpcre3-dev zlib1g-dev libatomic-ops-dev libpcre2-dev libtalloc2 libtalloc-dev
#
# Patches: 
#  - 
#  - https://github.com/kn007/patch
#  - https://github.com/xddxdd/dockerfiles/tree/master/dockerfiles/nginx

print_message () {
	echo -e "\e[33m>"
  	echo ">>>"
	echo ">>>>>  $1  >>>>> "
	echo ">>>"
	echo -e ">\e[0m"
}

NGINX_VERSION="1.25.4-QUIC"

CURRENT_DATE=$(date +'%Y%m%d')

TMP_DIR=/tmp

DIR_NAME=nginx-${CURRENT_DATE}

PROJECT_DIR=${TMP_DIR}/${DIR_NAME}


cd ${TMP_DIR} \
&& print_message "Download Nginx" \
&& hg clone https://hg.nginx.org/nginx ${DIR_NAME} \
&& cd ${PROJECT_DIR} \
&& print_message "Nginx Patch: use_openssl_md5_sha1.patch" \
&& wget -q https://raw.githubusercontent.com/kn007/patch/master/use_openssl_md5_sha1.patch \
&& patch -p1 < use_openssl_md5_sha1.patch \
&& print_message "Nginx Patch: Dynamic TLS Record Support" \
&& wget -q https://raw.githubusercontent.com/kn007/patch/master/nginx_dynamic_tls_records.patch \
&& patch -p1 < nginx_dynamic_tls_records.patch \
&& print_message "Nginx Patch: nginx-start-time.patch" \
&& wget -q https://raw.githubusercontent.com/gulch/ngx-cmpltn-script/master/nginx-start-time.patch \
&& patch -p1 < nginx-start-time.patch \
&& print_message "Nginx Module: Headers More" \
&& git clone https://github.com/openresty/headers-more-nginx-module.git \
&& print_message "Nginx Module: Certificate Transparency" \
&& git clone https://github.com/grahamedgecombe/nginx-ct.git \
&& print_message "Nginx Module: Brotli" \
&& git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli \
&& cd ngx_brotli/deps/brotli && mkdir out && cd out \
&& cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed .. \
&& cmake --build . --config Release --target brotlienc \
&& cd ${PROJECT_DIR} \
&& print_message "Zlib" \
&& git clone https://github.com/cloudflare/zlib.git \
&& cd zlib && make -f Makefile.in distclean && cd .. \
&& print_message "QuicTLS" \
&& git clone --branch openssl-3.1.5+quic https://github.com/quictls/openssl \
&& print_message "Nginx Configure" \
&& mkdir -p /var/cache/nginx/client_temp \
&& sed -i -e 's@<hr><center>nginx</center>@@g' ${PROJECT_DIR}/src/http/ngx_http_special_response.c \
&& auto/configure \
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
--with-pcre-jit \
--with-libatomic \
--with-zlib=${PROJECT_DIR}/zlib \
--add-module=${PROJECT_DIR}/ngx_brotli \
--add-module=${PROJECT_DIR}/headers-more-nginx-module \
--add-module=${PROJECT_DIR}/nginx-ct \
--with-openssl=${PROJECT_DIR}/openssl \
--with-openssl-opt="no-tests no-ssl3 zlib enable-ktls enable-ec_nistp_64_gcc_128" \
--with-cc-opt="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -DTCP_FASTOPEN=23 -fPIC -m64 -falign-functions=32 -flto -funsafe-math-optimizations --param=ssp-buffer-size=4 -Wimplicit-fallthrough=0 -Wno-error=strict-aliasing -Wno-error=pointer-sign -Wno-implicit-function-declaration -Wno-int-conversion -Wno-error=unused-result -Wno-unused-result -fcode-hoisting -Wno-deprecated-declarations" \
--with-ld-opt="-Wl,-Bsymbolic-functions -Wl,--as-needed -pie -Wl,-z,relro -Wl,-z,now -lrt -ltalloc -lpcre" \
&& read -p "Press ENTER to start compilation..." \
&& make -j $(nproc) \
&& print_message "Make DEB package" \
&& checkinstall -y --type=debian --pkgname=nginx --pkgversion=${NGINX_VERSION}-${CURRENT_DATE} --nodoc --install=no \
&& print_message "DONE 🎉"
