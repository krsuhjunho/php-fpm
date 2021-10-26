#!/bin/bash


setenforce 0 
yum update -y
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
yum install -y epel-release
yum -y groupinstall 'Development Tools'
yum -y install yum-utils
yum install -y  http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php74

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable --now docker
docker ps 
echo '
#!/bin/bash 

# get latest docker compose released tag 
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4) 

# Install docker-compose 
sh -c "curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose" 
chmod +x /usr/local/bin/docker-compose 
sh -c "curl -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose" 

# Output compose version 
docker-compose -v 

exit 0' > docker-compose-latest
chmod +x docker-compose-latest&&./docker-compose-latest

docker-compose up -d

yum -y install httpd mod_ssl php php-zip php-fpm php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-pecl-apc php-mbstring php-mcrypt php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli httpd-devel php-fpm php-intl php-imagick php-pspell wget
echo "RequestHeader unset Proxy early" >> /etc/httpd/conf/httpd.conf
sed -i 's/Listen 80/Listen 10080/g' /etc/httpd/conf/httpd.conf
#Apache 내부 포트 변경 필요 NPM에서 80이랑 443 사용중
#apache 포트 10080으로 변경 및 443 제외
mv ssl.conf ssl.conf.bak
systemctl enable --now httpd
systemctl restart httpd

echo "<?php echo '実行中のユーザーは '.exec('whoami');  phpinfo();?>" > /var/www/html/info.php

mkdir /etc/php-fpm.d/sites-enabled
mkdir /etc/php-fpm.d/sites-available

cp /etc/php-fpm.conf /etc/php-fpm.conf.backup
sed -i 's#include=/etc/php-fpm.d/#include=/etc/php-fpm.d/sites-enabled/#g' /etc/php-fpm.conf

mv /etc/php-fpm.d/www.conf /etc/php-fpm.d/sites-available
ln -s /etc/php-fpm.d/sites-available/www.conf /etc/php-fpm.d/sites-enabled/www.conf

mkdir /var/run/php-fpm

sed -i 's#127.0.0.1:9000#/var/run/php-fpm/default.sock#g' /etc/php-fpm.d/sites-available/www.conf

sed -i 's#;listen.owner = nobody#listen.owner = apache#g' /etc/php-fpm.d/sites-available/www.conf
sed -i 's#;listen.group = nobody#listen.group = apache#g' /etc/php-fpm.d/sites-available/www.conf
sed -i 's#;listen.mode = 0660#listen.mode = 0660#g' /etc/php-fpm.d/sites-available/www.conf
sed -i 's#;php_value#php_value#g' /etc/php-fpm.d/sites-available/www.conf

wget https://raw.githubusercontent.com/krsuhjunho/Php-fpm/main/default.conf
systemctl restart httpd

