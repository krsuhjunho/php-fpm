
UserName=${1}
UserHome=/home/${UserName}
UserHomePublic=${UserHome}/public_html
UserPhpSessionDir=${UserHome}/var/lib/php/session
UserPhpAvailableConf=/etc/php-fpm.d/sites-available/${UserName}.conf
UserPhpEnableConf=/etc/php-fpm.d/sites-enabled/${UserName}.conf 
PhpFpmExamConf=/etc/php-fpm.d/sites-available/www.conf
UserApacheExampleConf=/etc/httpd/conf.d/${UserName}.conf

echo ""
echo "Delete User  => ${UserName}" 
echo ""
userdel ${UserName}

echo ""
echo "Delete Home Directory => ${UserHome}" 
echo ""
rm -rf ${UserHome}

echo ""
echo "Delete Available Config File => ${UserPhpAvailableConf}" 
echo ""
rm -rf ${UserPhpAvailableConf}

echo ""
echo "Delete Enable Config File => ${UserPhpEnableConf}" 
echo ""
rm -rf ${UserPhpEnableConf}


echo ""
echo "Delete Apache Config File  => ${UserApacheExampleConf}" 
echo ""
rm -rf ${UserApacheExampleConf}



apachectl configtest

apachectl graceful

systemctl status httpd

systemctl restart php-fpm

ps ax | grep php-fpm
