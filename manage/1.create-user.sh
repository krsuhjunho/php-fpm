#!/bin/bash

#Var
UserName=${1}
UserHome=/home/${UserName}
UserHomePublic=${UserHome}/public_html
UserHomeSSHDir=${UserHome}/.ssh
UserPhpSessionDir=${UserHome}/var/lib/php/session
UserPhpAvailableDir=/etc/php-fpm.d/sites-available
UserPhpAvailableConf=${UserPhpAvailableDir}/${UserName}.conf
UserPhpEnableDir=/etc/php-fpm.d/sites-enabled
UserPhpEnableConf=${UserPhpEnableDir}/${UserName}.conf 
PhpFpmExamDir=/etc/php-fpm.d/sites-available
PhpFpmExamConf=${PhpFpmExamDir}/www.conf
UserApacheExampleDir=/etc/httpd/conf.d
UserApacheExampleConf=${UserApacheExampleDir}/${UserName}.conf
DefaultPhpInfo=/var/www/html/info.php
SSHD_CONFIG=/etc/ssh/sshd_config
VirtualHostDir=/home
WordpressDir=wordpress

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

USERCHECK()
{
BANNER "Check User Exist"
if [ -d "$UserHome" ]; then
  # Take action if $UserHome exists. #
  echo "User Exist, Exit UserAdd Process"
  echo "Please Check UserName"
  exit;
fi
}

USERADD()
{
BANNER "UserAdd => ${UserName}"
#유저 등록 및 권한 설정
adduser ${UserName}

BANNER "Create User Public folder"
#유저 홈 폴더 생성
sudo -u ${UserName} mkdir ${UserHomePublic}
chmod -R +s ${UserHome}
chmod -R 0755 ${UserHome}

BANNER "Copy User SSH Keygen Shell"
#유저 SSH 키 생성 
mkdir -p ${UserHomeSSHDir}
chown ${UserName}:${UserName} ${UserHomeSSHDir}
#키 생성 쉘 복사 
cp ./create-key.sh ${UserHomeSSHDir}
}

PHP-FPM_SETUP()
{
BANNER "Create User PHP-FPM Session Directory"
#유저 전용 PHP-FPM 세션 설정
sudo -u ${UserName} mkdir -p ${UserPhpSessionDir}

BANNER "Copy User PHP-FPM Config"
#PHP-FPM config파일 복사 
cp ${PhpFpmExamConf} ${UserPhpAvailableConf}

BANNER "PHP-FPM Permission Change To User"
#PHP-FPM Config 파일 소유자 유저로 권한 수정
sed -i "4s#www#${UserName}#g" ${UserPhpAvailableConf}
sed -i "s#user = apache#user = ${UserName}#g" ${UserPhpAvailableConf}
sed -i "s#group = apache#group = ${UserName}#g" ${UserPhpAvailableConf}
sed -i "s#/var/run/php-fpm/default.sock#/var/run/php-fpm/${UserName}.sock#g" ${UserPhpAvailableConf}
sed -i "s#/var/lib/php/session#${UserPhpSessionDir}#g" ${UserPhpAvailableConf}

#PHP-FPM 실행 가능 상태로 설정
BANNER "PHP-FPM Config Link To Available to Enable"
ln -s ${UserPhpAvailableConf}  ${UserPhpEnableConf}

BANNER "Reload PHP-FPM"
#PHP-FPM Process Reload
systemctl reload php-fpm

BANNER "Check PHP-FPM"
# PHP-FPM 프로세스 현황 체크
ps ax | grep php-fpm
}

APACHE_SETUP()
{
BANNER "Download Example.conf From Git"
#기본 Apache Conf 파일 다운로드 및 설정 
wget -O ${UserApacheExampleConf} https://raw.githubusercontent.com/krsuhjunho/php-fpm/main/conf.d/example.conf

BANNER "Change Example.com to UserDomain"
#유저 이름 기반으로 도메인 설정 기본 유저 도메인 및 www 포함
sed -i "s#example.com#${UserName}#g" ${UserApacheExampleConf}

BANNER "Apache Config Test"
#Apache Config Test
apachectl configtest

BANNER "Apache Graceful"
#Apache Graceful
apachectl graceful

BANNER "Apache Status Check"
#Apache Status check
systemctl status httpd

BANNER "Copy PHP Info file to User Pulbic Directory"
#PHP Info File Copy to UserHomePublicDir
cp ${DefaultPhpInfo} ${UserHomePublic}

BANNER "Change Permission UserHome"
#소유권 변경 하기 
chown -R ${UserName}:${UserName} ${UserHome}
}

CHROOT_SETUP()
{
BANNER "Chroot Setup"
#Chroot 설정

BANNER "Backup SSHD_CONFIG"
#SSHD_CONFIG 파일 백업
cp ${SSHD_CONFIG} ${SSHD_CONFIG}.backup


BANNER "Insert Sftp Chroot Setup Config"
#SSHD_CONFIG에 Sftp Chroot 설정 추가 
echo ""  >> ${SSHD_CONFIG}
echo "#Match User ${UserName} " >> ${SSHD_CONFIG}
echo "#     ChrootDirectory ${UserHome}" >> ${SSHD_CONFIG}
echo "#     ForceCommand internal-sftp" >> ${SSHD_CONFIG}
echo "#     X11Forwarding no" >> ${SSHD_CONFIG}
echo "#     AllowTCPForwarding no" >> ${SSHD_CONFIG}
echo ""
echo "##CHECK CONFIG##"
tail -6 ${SSHD_CONFIG}
echo ""

BANNER "Chroot Permission change Home Directory, Root Permission"
#Chroot 사용을 위한 홈폴더 루트권한 설정
chown root:root ${UserHome} 
chmod 755 ${UserHome}

BANNER "CHECK SSHD_CONFIG CHROOT UNCOMENT"
BANNER "vi /etc/ssh/sshd_config"
}

WORDPRESS_SETUP()
{
BANNER "Wordpress Setup"
#Wordpress Copy
cp -R ${VirtualHostDir}/${WordpressDir}/* ${UserHomePublic}
chown -R ${UserName}:${UserName} ${UserHomePublic}
find ${UserHomePublic} -type d -exec chmod 0775 {} \;
find ${UserHomePublic} -type f -exec chmod 0664 {} \;
}

MAIN()
{
USERCHECK
USERADD
PHP-FPM_SETUP
APACHE_SETUP
CHROOT_SETUP
WORDPRESS_SETUP
}

MAIN
