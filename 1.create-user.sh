
UserName=${1}
UserHome=/home/${UserName}
UserHomePublic=${UserHome}/public_html
UserHomeSSHDir=${UserHome}/.ssh
UserPhpSessionDir=${UserHome}/var/lib/php/session
UserPhpAvailableConf=/etc/php-fpm.d/sites-available/${UserName}.conf
UserPhpEnableConf=/etc/php-fpm.d/sites-enabled/${UserName}.conf 
PhpFpmExamConf=/etc/php-fpm.d/sites-available/www.conf
UserApacheExampleConf=/etc/httpd/conf.d/${UserName}.conf
DefaultPhpInfo=/var/www/html/info.php
SSHD_CONFIG=/etc/ssh/sshd_config


adduser ${UserName}
sudo -u ${UserName} mkdir ${UserHomePublic}
chmod -R +s ${UserHome}
chmod -R 0755 ${UserHome}

sudo -u ${UserName} mkdir -p ${UserPhpSessionDir}

cp ${PhpFpmExamConf} ${UserPhpAvailableConf}
sed -i "4s#www#${UserName}#g" ${UserPhpAvailableConf}

sed -i "s#user = apache#user = ${UserName}#g" ${UserPhpAvailableConf}
sed -i "s#group = apache#group = ${UserName}#g" ${UserPhpAvailableConf}
sed -i "s#/var/run/php-fpm/default.sock#/var/run/php-fpm/${UserName}.sock#g" ${UserPhpAvailableConf}
sed -i "s#/var/lib/php/session#${UserPhpSessionDir}#g" ${UserPhpAvailableConf}

ln -s ${UserPhpAvailableConf}  ${UserPhpEnableConf}

systemctl restart php-fpm

ps ax | grep php-fpm

wget -O ${UserApacheExampleConf} https://raw.githubusercontent.com/krsuhjunho/Php-fpm/main/example.conf

sed -i "s#example.com#${UserName}#g" ${UserApacheExampleConf}

apachectl configtest

apachectl graceful

systemctl status httpd

cp ${DefaultPhpInfo} ${UserHomePublic}
chown -R ${UserName}:${UserName} ${UserHome}

#유저 SSH 키 생성 
mkdir -p ${UserHomeSSHDir}
chown ${UserName}:${UserName} ${UserHomeSSHDir}
cp ./create-key.sh ${UserHomeSSHDir}

#Chroot 설정

cp ${SSHD_CONFIG} ${SSHD_CONFIG}.backup


echo ""  >> ${SSHD_CONFIG}
echo "Match User ${UserName} " >> ${SSHD_CONFIG}
echo "     ChrootDirectory ${UserHome}" >> ${SSHD_CONFIG}
echo "     ForceCommand internal-sftp" >> ${SSHD_CONFIG}
echo "     X11Forwarding no" >> ${SSHD_CONFIG}
echo "     AllowTCPForwarding no" >> ${SSHD_CONFIG}

echo "CHECK CONFIG"
tail -10 ${SSHD_CONFIG}
