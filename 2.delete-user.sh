#!/bin/bash
UserName=${1}
UserHome=/home/${UserName}
UserHomePublic=${UserHome}/public_html
UserPhpSessionDir=${UserHome}/var/lib/php/session
UserPhpAvailableDir=/etc/php-fpm.d/sites-available
UserPhpAvailableConf=${UserPhpAvailableDir}/${UserName}.conf
UserPhpEnableDir=/etc/php-fpm.d/sites-enabled
UserPhpEnableConf=${UserPhpEnableDir}/${UserName}.conf 
PhpFpmExamDir=/etc/php-fpm.d/sites-available
PhpFpmExamConf=${PhpFpmExamDir}/www.conf
UserApacheConfDir=/etc/httpd/conf.d
UserApacheUserConf=${UserApacheConfDir}/${UserName}.conf

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

DELETE_HOMEDIR()
{
BANNER "Delete Home Directory => ${UserHome}" 
echo "rm -rf ${UserHome}"
rm -rf ${UserHome}
}

DELETE_PHPAVAILABLECONF()
{

BANNER "Delete Available Config File => ${UserPhpAvailableConf}" 
echo "rm -rf ${UserPhpAvailableConf}"
rm -rf ${UserPhpAvailableConf}
echo ""
ls -ahl ${UserPhpAvailableDir}
}

DELETE_PHPENABLECONF()
{
BANNER "Delete Enable Config File => ${UserPhpEnableConf}" 
echo "rm -rf ${UserPhpEnableConf}"
rm -rf ${UserPhpEnableConf}
echo ""
ls -ahl ${UserPhpEnableDir}
}


DELETE_APACHEEXAMPLECONF()
{
BANNER "Delete Apache Config File  => ${UserApacheUserConf}" 
echo "rm -rf ${UserApacheUserConf}"
rm -rf ${UserApacheUserConf}
echo ""
ls -ahl ${UserApacheConfDir}
}


SYSTEMCTL_RELOAD()
{
BANNER "PHP-FPM RELOAD"
systemctl reload php-fpm

ps ax | grep php-fpm

BANNER "APACHE CONFIG TEST && GRACEFUL"
apachectl configtest

apachectl graceful

systemctl status httpd

}


USERDEL()
{
BANNER "Delete User  => ${UserName}" 
echo "userdel ${UserName}"
userdel ${UserName}
}

CHECK_CHROOT_SSHD()
{
BANNER "CHECK_CHROOT_SSHD"
echo ""
echo "vi /etc/ssh/sshd_config"
echo ""
echo "Delete Chroot Setup ${UserName}"
echo ""
}

MAIN()
{
DELETE_HOMEDIR
DELETE_PHPAVAILABLECONF
DELETE_PHPENABLECONF
DELETE_APACHEEXAMPLECONF
SYSTEMCTL_RELOAD
USERDEL
CHECK_CHROOT_SSHD
}

MAIN
