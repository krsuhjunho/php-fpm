#!/bin/bash

BANNER() 
{
	echo ""
    msg="# $* #"
    edge=$(echo "$msg" | sed 's/./#/g')
    echo "$edge"
    echo "$msg"
    echo "$edge"
	echo ""
}

#--	SELINUX_PERMISSIVE
SELINUX_PERMISSIVE()
{
BANNER "SELINUX_PERMISSIVE"
setenforce 0	#-- SELINUX permissive  
}

#-- YUM UPDATE && EPEL && REMI INSTALL && PHP 7.4 SETUP
PHP_UPDATE_INSTALL()
{
BANNER "PHP_UPDATE_INSTALL"

yum update -yq 									#-- YUM UPDATE
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
yum install -y epel-release 					#-- EPEL-RELEASE INSTALL
yum -y groupinstall 'Development Tools' 		#-- Development Tools INSTALL
yum -y install yum-utils 						#-- Development Tools INSTALL
yum install -y  http://rpms.remirepo.net/enterprise/remi-release-7.rpm #-- REMI REPO INSTALL
yum-config-manager --enable remi-php74 			#-- PHP 7.4 BASE SETUP

#-- YUM PHP 7.4 INSTALL

yum -y install  httpd \
				mod_ssl \
				php \
				php-zip \
				php-fpm \
				php-devel \
				php-gd \
				php-imap \
				php-ldap \
				php-mysql \
				php-odbc \
				php-pear \
				php-xml \
				php-xmlrpc \
				php-pecl-apc \
				php-mbstring \
				php-mcrypt \
				php-soap \
				php-tidy \
				curl \
				curl-devel \
				perl-libwww-perl \
				ImageMagick \
				libxml2 \
				libxml2-devel \
				mod_fcgid \
				php-cli \
				httpd-devel \
				php-fpm \
				php-intl \
				php-imagick \
				php-pspell \
				wget
}

#-- DOCKER INSTALL
DOCKER_INSTALL()
{

BANNER "DOCKER_INSTALL"

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

systemctl enable --now docker

BANNER "DOCEKR PROCESS CHECK"
#-- DOCKER Process Check
docker ps 

#--DOCKER-COMPOSE

BANNER "DOCKER-COMPOSE_INSTALL"
echo '
#!/bin/bash 

# get latest docker compose released tag 
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4) 

# Install docker-compose 
sh -c "curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose" 
chmod +x /usr/local/bin/docker-compose 

# Output compose version 
/usr/local/bin/docker-compose -v 

exit 0' > docker-compose-latest
chmod +x ./docker-compose-latest&&./docker-compose-latest


BANNER "MKDIR DOCKER DIRECTORY"
mkdir /docker/
cp -R mysql /docker/
cp -R npm /docker/

BANNER "COPY NPM DOCKER COMPOSE"

cd /docker/npm
/usr/local/bin/docker-compose up -d

BANNER "COPY MYSQL DOCKER COMPOSE"

cd /docker/mysql 
/usr/local/bin/docker-compose up -d

}

#-- APACHE SETUP
APACHE_SETUP()
{
BANNER "APACHE SETUP"
echo "RequestHeader unset Proxy early" >> /etc/httpd/conf/httpd.conf

BANNER "APACHE PORT CHANGE 80 TO 10080"
sed -i 's/Listen 80/Listen 10080/g' /etc/httpd/conf/httpd.conf
#Apache 내부 포트 변경 필요 NPM에서 80이랑 443 사용중
#apache 포트 10080으로 변경 및 443 제외
mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.bak
systemctl enable --now httpd

BANNER "APACHE CONFIG CHECK"
apachectl configtest

BANNER "APACHE STATUS CHECK"
systemctl status httpd
}

#-- PHP-FPM SETUP
PHP_FPM_SETUP()
{
#-- PHP INFO

BANNER "SAVE PHP INFO FILE"
echo "<?php echo '実行中のユーザーは '.exec('whoami');  phpinfo();?>" > /var/www/html/info.php

#-- PHP-FPM SETUP
BANNER "PHP-FPM CONF FILE CREATE DIRECTORY"

BANNER "mkdir /etc/php-fpm.d/sites-enabled"
mkdir /etc/php-fpm.d/sites-enabled

BANNER "mkdir /etc/php-fpm.d/sites-available"
mkdir /etc/php-fpm.d/sites-available

BANNER "cp /etc/php-fpm.conf /etc/php-fpm.conf.backup"
cp /etc/php-fpm.conf /etc/php-fpm.conf.backup

BANNER "PHP-FPM CONF CHANGE - sites-enabled"
sed -i 's#include=/etc/php-fpm.d/#include=/etc/php-fpm.d/sites-enabled/#g' /etc/php-fpm.conf
mv /etc/php-fpm.d/www.conf /etc/php-fpm.d/sites-available
ln -s /etc/php-fpm.d/sites-available/www.conf /etc/php-fpm.d/sites-enabled/www.conf


BANNER "mkdir /var/run/php-fpm"
mkdir /var/run/php-fpm

BANNER "PHP-FPM TCP TO UNIX SOCK"
sed -i 's#127.0.0.1:9000#/var/run/php-fpm/default.sock#g' /etc/php-fpm.d/sites-available/www.conf

BANNER "PHP-FPM CHANGE OWNER to APACHE"
sed -i 's#;listen.owner = nobody#listen.owner = apache#g' /etc/php-fpm.d/sites-available/www.conf
BANNER "PHP-FPM CHANGE GROUP to APACHE"
sed -i 's#;listen.group = nobody#listen.group = apache#g' /etc/php-fpm.d/sites-available/www.conf
sed -i 's#;listen.mode = 0660#listen.mode = 0660#g' /etc/php-fpm.d/sites-available/www.conf
sed -i 's#;php_value#php_value#g' /etc/php-fpm.d/sites-available/www.conf

BANNER "APACHE PHP-FPM CONF DOWNLOAD"
wget -O /etc/httpd/conf.d/default.conf https://raw.githubusercontent.com/krsuhjunho/php-fpm/main/conf.d/default.conf

BANNER "PHP-FPM STATUS CHECK"
systemctl restart php-fpm
systemctl status php-fpm

BANNER "APACHE STATUS CHECK"
systemctl restart httpd
systemctl status httpd
}

#-- WORDPRESS LATEST DOWNLOAD
WORDPRESS_LATEST_DOWNLOAD()
{
cd /home
wget https://ko.wordpress.org/latest-ko_KR.tar.gz
tar -zxf latest-ko_KR.tar.gz
}

MAIN()
{
SELINUX_PERMISSIVE
PHP_UPDATE_INSTALL
DOCKER_INSTALL
APACHE_SETUP
PHP_FPM_SETUP
WORDPRESS_LATEST_DOWNLOAD
}

MAIN
