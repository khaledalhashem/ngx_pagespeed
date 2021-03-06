#!/bin/bash
####################################
#
# Auto nginx_custom install
#
####################################


# Maintainer:  Khaled AlHashem <kalhashem@naur.us>
# Version: 0.2
# Copy and paste the following line into your cosole to auto-start the installation
# yum -y update && curl -O https://raw.githubusercontent.com/khaledalhashem/nginx_custom/master/nginx_custom_centos.sh && chmod 0700 nginx_custom_centos.sh && bash -x nginx_custom_centos.sh 2>&1 | tee nginx_custom.log

pkgname='nginx_custom'
srcdir='/usr/local/src/nginx'
NGINX_VERSION='nginx-1.15.5' # [check nginx's site http://nginx.org/en/download.html for the latest version]
NPS_VERSION='1.13.35.2-stable' # [check https://www.modpagespeed.com/doc/release_notes for the latest version]
pkgdesc='Lightweight HTTP server and IMAP/POP3 proxy server, stable release'
arch=('i686' 'x86_64')
url='https://nginx.org'
license=('custom')
depends=('pcre' 'zlib' 'openssl')
pcre='pcre-8.42'
zlib='zlib-1.2.11'
openssl='openssl-1.1.1'
fancyindex='0.4.3'

yum groupinstall -y 'Development Tools'
yum --enablerepo=extras install -y epel-release
yum --enablerepo=base clean metadata
yum -y update && yum -y install wget gcc-c++ pcre-devel zlib-devel make libuuid-devel perl perl-devel perl-ExtUtils-Embed libxslt libxslt-devel libxml2 libxml2-devel gd gd-devel GeoIP GeoIP-devel unzip
yum -y install yum-utils
useradd --system --home /var/cache/nginx --shell /sbin/nologin --comment "nginx user" --user-group nginx

# Create the source building directory and cd into it
mkdir $srcdir && cd $srcdir

# pagespeed version 1.13.35.2-stable
wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}.zip
unzip v${NPS_VERSION}.zip
nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d)
cd "$nps_dir"
NPS_RELEASE_NUMBER=${NPS_VERSION/beta/}
NPS_RELEASE_NUMBER=${NPS_VERSION/stable/}
psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz
[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
wget ${psol_url}
tar -xzvf $(basename ${psol_url})  # extracts to psol/

cd $srcdir

# Nginx version nginx-1.13.10
wget -c http://nginx.org/download/$NGINX_VERSION.tar.gz --tries=3 && tar -zxf $NGINX_VERSION.tar.gz

# PCRE version 8.40
wget -c https://ftp.pcre.org/pub/pcre/$pcre.tar.gz --tries=3 && tar -xzf $pcre.tar.gz

# zlib version 1.2.11
wget -c https://www.zlib.net/$zlib.tar.gz --tries=3 && tar -xzf $zlib.tar.gz

# OpenSSL version 1.1.0f
wget -c https://www.openssl.org/source/$openssl.tar.gz --tries=3 && tar -xzf $openssl.tar.gz

# ngx_fancyindex 0.4.2
wget -c https://github.com/aperezdc/ngx-fancyindex/archive/v$fancyindex.tar.gz --tries=3 && tar -zxf v$fancyindex.tar.gz

rm -rf *.gz

cd $srcdir/$NGINX_VERSION

./configure --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --modules-path=/usr/lib64/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --user=nginx \
            --group=nginx \
            --build=CentOS \
            --builddir=$NGINX_VERSION \
            --with-select_module \
            --with-poll_module \
            --with-threads \
            --with-file-aio \
	    --add-module=../incubator-pagespeed-ngx-$NPS_VERSION \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_realip_module \
	    --add-dynamic-module=../ngx-fancyindex-$fancyindex \
            --with-http_addition_module \
            --with-http_xslt_module=dynamic \
            --with-http_image_filter_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_degradation_module \
            --with-http_slice_module \
            --with-http_stub_status_module \
            --http-log-path=/var/log/nginx/access.log \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_geoip_module=dynamic \
            --with-stream_ssl_preread_module \
            --with-compat \
            --with-pcre=../$pcre \
            --with-pcre-jit \
            --with-zlib=../$zlib \
            --with-openssl=../$openssl \
            --with-openssl-opt=no-nextprotoneg

make
make install

wget -O /usr/lib/systemd/system/nginx.service https://raw.githubusercontent.com/khaledalhashem/nginx_custom/master/nginx.service --tries=3 && chmod +x /usr/lib/systemd/system/nginx.service

wget -O /etc/init.d/nginx https://raw.githubusercontent.com/khaledalhashem/nginx_custom/master/nginx_init.d_script_centos --tries=3 && chmod +x /etc/init.d/nginx

mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak && wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/khaledalhashem/nginx_custom/master/nginx.conf --tries=3

ln -s /usr/lib64/nginx/modules /etc/nginx/modules

wget -O /etc/nginx/dynamic-modules.conf https://raw.githubusercontent.com/khaledalhashem/nginx_custom/master/dynamic-modules.conf --tries=3

mkdir -p /etc/nginx/conf.d /usr/share/nginx/html /var/www
chown -R nginx:nginx /usr/share/nginx/html /var/www
find /usr/share/nginx/html /var/www -type d -exec chmod 755 {} \;
find /usr/share/nginx/html /var/www -type f -exec chmod 644 {} \;

wget -O /etc/nginx/conf.d/default.conf https://raw.githubusercontent.com/khaledalhashem/nginx_custom/master/default.conf --tries=3

wget -O /etc/nginx/conf.d/example.com_conf https://raw.githubusercontent.com/khaledalhashem/nginx_custom/master/example.com.conf --tries=3

mkdir -p /var/cache/nginx && nginx -t

cp /etc/nginx/html/* /usr/share/nginx/html/

systemctl start nginx.service && systemctl enable nginx.service

rm -rf /etc/nginx/koi-utf /etc/nginx/koi-win /etc/nginx/win-utf

rm -rf /etc/nginx/*.default

mkdir -p /var/ngx_pagespeed_cache
chown -R nobody:nobody /var/ngx_pagespeed_cache

systemctl restart nginx

mkdir ~/.vim/
cp -r $srcdir/$NGINX_VERSION/contrib/vim/* ~/.vim/

nginx -V

# Auto install latest version of Mariadb and run secure installation

cd

cat <<EOF>> /etc/yum.repos.d/MariaDB.repo
# MariaDB 10.1 CentOS repository list
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum -y install MariaDB-server MariaDB-client

systemctl start mariadb
systemctl enable mariadb

/usr/bin/mysql_secure_installation

mysql -V

cd

rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm

yum-config-manager --enable remi-php71
yum -y install php php-fpm php-opcache php-mysql php-cli php-curl php-zip

systemctl start php-fpm
systemctl enable php-fpm

php -v
