#!/bin/bash


#--SELINUX
setenforce 0 #-- SELINUX PER,  

#--YUM UPDATE && EPEL && REMI INSTALL
yum update -yq #-- YUM UPDATE
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
yum install -y epel-release #-- EPEL-RELEASE INSTALL
yum -y groupinstall 'Development Tools'
yum -y install yum-utils
yum install -y  http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php74 #--PHP 7.4 SETUP

#--DOCKER
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable --now docker
docker ps 

#--DOCKER-COMPOSE
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
chmod +x ./docker-compose-latest&&./docker-compose-latest

#--DOCKER-COMPOSE - NPM
/usr/local/bin/docker-compose up -d

#--DOCKER-COMPOSE - MYSQL 5.7 
cd mysql 
/usr/local/bin/docker-compose up -d

#--YUM PHP INSTALL

yum -y install httpd mod_ssl php php-zip php-fpm php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-pecl-apc php-mbstring php-mcrypt php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli httpd-devel php-fpm php-intl php-imagick php-pspell wget

#--APACHE SETUP
echo "RequestHeader unset Proxy early" >> /etc/httpd/conf/httpd.conf

#Apache 내부 포트 변경 필요 NPM에서 80이랑 443 사용중
sed -i 's/Listen 80/Listen 10080/g' /etc/httpd/conf/httpd.conf

#apache 포트 10080으로 변경 및 443 제외
mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.bak #--443 사용중인 NPM이 존재 하므로 SSL의 conf를 따로 백업 후 제외
systemctl enable --now httpd #-- 재시작시 자동 실행 
systemctl restart httpd

#--PHP INFO #--소유자 확인 및 PHP info 
echo "<?php echo '実行中のユーザーは '.exec('whoami');  phpinfo();?>" > /var/www/html/info.php


#--PHP-FPM SETUP
mkdir /etc/php-fpm.d/sites-enabled    #--PHP-FPM에서 사용할 conf 저장 폴더
mkdir /etc/php-fpm.d/sites-available  #--PHP-FPM에서 사용 예정 conf 저장 폴더

cp /etc/php-fpm.conf /etc/php-fpm.conf.backup #--설정 오류 대응을 위해 백업 진행 

sed -i 's#include=/etc/php-fpm.d/#include=/etc/php-fpm.d/sites-enabled/#g' /etc/php-fpm.conf  #--원래는 php-fpm.d 의 conf를 확인 했으나 enabled의 하위 conf만으로 설정

mv /etc/php-fpm.d/www.conf /etc/php-fpm.d/sites-available #--기본 www.conf를 사용 예정인 폴더로 이동
ln -s /etc/php-fpm.d/sites-available/www.conf /etc/php-fpm.d/sites-enabled/www.conf #--심볼릭 링크로 enabled에 지정 해서 사용 원본은 available 폴더에 존재 

mkdir /var/run/php-fpm #--www의 소유의 sock파일 저장용 디렉토리
 
sed -i 's#127.0.0.1:9000#/var/run/php-fpm/default.sock#g' /etc/php-fpm.d/sites-available/www.conf #--Tcp가 아닌 UNIX의 소켓을 사용
sed -i 's#;listen.owner = nobody#listen.owner = apache#g' /etc/php-fpm.d/sites-available/www.conf #--오너를 apache로 변경
sed -i 's#;listen.group = nobody#listen.group = apache#g' /etc/php-fpm.d/sites-available/www.conf #--그룹도 apache로 변경
sed -i 's#;listen.mode = 0660#listen.mode = 0660#g' /etc/php-fpm.d/sites-available/www.conf       #--소유권 관련 권한 설정도 주석 해제
sed -i 's#;php_value#php_value#g' /etc/php-fpm.d/sites-available/www.conf                         #--php-value를 주석 해제 해서 사용 가능하게 설정 

wget -O /etc/httpd/conf.d/default.conf https://raw.githubusercontent.com/krsuhjunho/Php-fpm/main/default.conf #--기본 접속시의 default.conf를 git에서 다운로드 후 저장
systemctl restart php-fpm #-- PHP-FPM 재시작
systemctl restart httpd   #-- APACHE 재시작

#-- WORDPRESS 저장
cd /home
wget https://ko.wordpress.org/latest-ko_KR.tar.gz #--최신 워드프레스 다운로드
tar -zxvf latest-ko_KR.tar.gz #-- 워드프레스 압축 해제 
