#!/bin/sh
### BEGIN INIT INFO
# Provides:          Build-BEMS2-test-AllInOne
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Build_BEMS at boot time
# Description:       Build_BEMS at boot time.
### END INIT INFO

#release Web Server Script

# umask 007
# Use random name to avoid conflict with other process.
genRandomName() {
    echo $(cat /dev/urandom | od -x | tr -d ' ' | head -n 1)
    return
}
TEMPDIR=$(mktemp -d /tmp/`genRandomName`$$XXXXXX) ;
#export TEMPDIR
trap "exit 1" HUP INT PIPE QUIT TERM
# Delet temporary file while exit.
trap "rm -r $TEMPDIR" EXIT
# In case of ls is an alias for "ls --color"
alias ls="$(which ls)";

# mkdir /tmp/hs/
cp /package/*.nc "$TEMPDIR/."
sync


cd "$TEMPDIR"
/usr/sbin/med_dec ./CoreModules.zip.nc
sync

/usr/sbin/med_dec ./BEMS_2.0.zip.nc
sync

unzip ./CoreModules.zip > /dev/null
sync

unzip ./BEMS_2.0.zip > /dev/null
sync

rm ./*.zip
rm ./*.nc
sync

# Move the GlobalWorkers to the /webserv
cd "$TEMPDIR"/CoreModules
test -e "./zeroMQ" && rm -r ./zeroMQ
test -e "./med" && rm -r ./med
mv ./GlobalWorkers "$TEMPDIR"/

# Change the .htaccecc of WebService by condition
cd "$TEMPDIR"/BEMS_2.0/BulidScript/initial/apache/htaccess
cp ./htaccess-WebService "$TEMPDIR"/BEMS_2.0/WebService/.htaccess
cp ./htaccess-gw2cs "$TEMPDIR"/BEMS_2.0/GatewayCloudComm/.htaccess

cd "$TEMPDIR"/BEMS_2.0/WebUI/WebScript/www2/dist/img
cp ./logo_xms.png ./logo.png

cd "$TEMPDIR"
rm -R ./BEMS_2.0/BulidScript
# rm -R ./BEMS_2.0/WebService
# rm -R ./BEMS_2.0/JobWorkers
# rm -R ./BEMS_2.0/GatewayCloudComm
# rm -R ./BEMS_2.0/ProjectLib
# rm -R ./BEMS_2.0/WebUI/WebScript/www
rm -R ./BEMS_2.0/WebUI/WebScript/www2/assets
rm -R ./BEMS_2.0/WebUI/WebScript/www_dealer/assets
rm -R ./BEMS_2.0/WebUI/WebScript/www_smo/assets
sync

# Add the temp folder for smo AD cropper
if test ! -e ./BEMS_2.0/WebUI/WebScript/www2/dist/temp ;then
    mkdir -p ./BEMS_2.0/WebUI/WebScript/www2/dist/temp
    chmod 777 ./BEMS_2.0/WebUI/WebScript/www2/dist/temp
fi

if test ! -e ./BEMS_2.0/WebUI/WebScript/www_smo/dist/temp ;then
    mkdir -p ./BEMS_2.0/WebUI/WebScript/www_smo/dist/temp
    chmod 777 ./BEMS_2.0/WebUI/WebScript/www_smo/dist/temp
fi

cp -R ./* /webserv/.
sync
chown -R www-data:www-data /webserv


cd /webserv/BEMS_2.0/Conf
cp ./global.conf /webserv/GlobalWorkers/conf/global.conf

cd /webserv/BEMS_2.0/Conf/ini
cp ./global.test.ini ./global.ini
cp ./global.test.ini /webserv/GlobalWorkers/conf/ini/global.ini
rm -rf `ls -I global.ini`


sync

#rm -R /tmp/hs
# rm -R "$TEMPDIR"
apache_log_path="/var/log/apache2"
if test ! -e "$apache_log_path" ;then
   mkdir "$apache_log_path"
fi
chmod -R 777 "$apache_log_path"
#/etc/init.d/apache2 restart

# Kill all worker proccess
#echo "Kill all worker proccess"
#ps aux | awk '/JobWorkers\/.*\.php$/ {print $2;}' | xargs kill
#ps aux | awk '/GlobalWorkers\/.*\.php$/ {print $2;}' | xargs kill

