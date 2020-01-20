#!/bin/bash

BACKUPdir="/var/backup"
BUCKET="trafficterminal-backup"

BAKsrv=$(mktemp /tmp/backup_service.XXXXXXXXXX)
MYSQLbakDIR="/var/backup"
DATE=`date +"%m-%d-%Y"`
METAfile="/etc/zabbix/conf.d/metadata.conf"
HOSTNAME=`hostname -f`
ERRORbak='0'
EXCLUDEdir=''
IPadress=`facter | grep ipaddress_eth0 | awk '{print $3}'`


#In this block described all functions, who use in script
function MYSQLbackup () {
  BAKdb=$(mktemp /tmp/backup_database.XXXXXXXXXX)
  PERCONAsrv=`rpm -qa | grep Percona.*serv`
  BAKstatus=""
  mysql -e "show databases;" | head | egrep -v "Database|_schema" >> $BAKdb

  if [[ $PERCONAsrv == *"server-56"* ]]; then
    rpm -q --quiet "percona-xtrabackup-23" || yum install -y percona-xtrabackup-23 --nogpgcheck
  elif [[ $PERCONAsrv == *"server-57"* ]]; then
    rpm -q --quiet "percona-xtrabackup-24" || yum install -y percona-xtrabackup-24 --nogpgcheck
  fi

  #Try to backup database
  if [[ -d $MYSQLbakDIR ]]; then
    xtrabackup --defaults-extra-file=~/.my.cnf \
      --backup \
      --stream=xbstream \
      --databases-file=$BAKdb \
      --no-lock --compress | \
      gzip - > $MYSQLbakDIR/mysql-compress-xbstream_"$DATE".tar.gz
    cp $BAKdb $MYSQLbakDIR/Backuped_DataBASE.txt
    /usr/bin/s3cmd put --add-header=x-amz-tagging:"$TAG" $MYSQLbakDIR/mysql-compress-xbstream_"$DATE".tar.gz $MYSQLbakDIR/Backuped_DataBASE.txt s3://"$BUCKET"/"$HOSTNAME"/"$DATE"/mysql/
    xtrabackup --defaults-extra-file=~/.my.cnf --backup --stream=xbstream --extra-lsndir=/tmp |  xbcloud --storage=s3 --s3-access-key='AKIAURXRZKUN4IB5VR2O' --s3-secret-key='YoGG5vGpxq6V8lABm/a0JLNxsm3OmALJmZ6Rrnl0p' --s3-bucket='trafficterminal-backup' put full_bak.tgz
  else
    xtrabackup --defaults-extra-file=~/.my.cnf \
      --backup \
      --stream=xbstream \
      --databases-file=$BAKdb \
      --no-lock --compress | \
      gzip - | /usr/bin/s3cmd put --add-header=x-amz-tagging:"$TAG" - s3://"$BUCKET"/"$HOSTNAME"/"$DATE"/mysql/mysql-compress-xbstream_"$DATE".tar.gz
    /usr/bin/s3cmd put --add-header=x-amz-tagging:"$TAG" $BAKdb s3://"$BUCKET"/"$HOSTNAME"/"$DATE"/mysql/Backuped_DataBASE.txt
  fi
  if [[ $? == "0" ]]; then
    echo $HOSTNAME s3.backup.status $LINE OK | /usr/local/sbin/zabbix_send
  else
    ERRORbak='1'
    echo $HOSTNAME s3.backup.status $LINE ERROR | /usr/local/sbin/zabbix_send
  fi
}

function FOLDERbackup() {
  #try backup create
  if [[ $LINE == "web" ]]; then
    s3cmd sync --add-header=x-amz-tagging:"sync=web" $1 s3://"$BUCKET"/"$HOSTNAME"/"$LINE"/
  else
    tar czvf - $1 $2 $EXCLUDEdir | /usr/bin/s3cmd put --add-header=x-amz-tagging:"$TAG" - s3://"$BUCKET"/"$HOSTNAME"/"$DATE"/"$LINE"/"$LINE"-"$DATE".tar.gz &>/dev/null
  fi
  if [[ $? == "0" ]]; then
    echo "$HOSTNAME s3.backup.status $LINE OK" | /usr/local/sbin/zabbix_send
  else
    ERRORbak='1'
    echo "$HOSTNAME s3.backup.status $LINE ERROR" | /usr/local/sbin/zabbix_send
  fi
}

#START SCRYPT
#------------
set -o pipefail

sleep $(( RANDOM % 10 ))
#Daily weekly Monthly and e.g. tags
MARKday=`date +"%u"`
MARKmonth=`date +"%d"`
TAG=''
if [[ ( $MARKday == "6" || $MARKday == "7" ) && $MARKmonth < "29" ]]; then
    TAG='weekly=week'
#    BUCKET+="-weekly"
fi
if [[ ( $MARKmonth == "30" || $MARKmonth == "31" ) && `date +"%m"` != "2" ]]; then
    TAG='monthly=month'
#    BUCKET+="-monthly"
fi
if [[ ( $MARKmonth == "28" || $MARKmonth == "29" ) && `date +"%m"` = "2" ]]; then
    TAG='monthly=month'
#    BUCKET+="-monthly"
fi
if [[ ( $MARKmonth == "30" || $MARKmonth == "31" ) && `date +"%m"` = "12" ]]; then
    TAG='yearly=year'
#    BUCKET+="-yearly"
fi
if [[ $TAG == "" ]]; then
  TAG='daily=day'
#  BUCKET+="-dayly"
fi
#Backup storage structure:
#/var/backup/
#            HOSTNAME/
#                     Date/
#                          Service/
# SERVICES:
#   MySQL   - /var/lib/mysql
#   WEB     - /var/www
#   APACHE  - /etc/httpd
#   NGINX   - /etc/nginx
#   HAMSTER - /home && /root
#   SYSTEM  - /etc

#search service to backup (home directory backup permanently)
for i in $(cat $METAfile | sed 's/.*=//' | sed 's/,/ /'g)
do
  case $i in
    "nginx")
      echo -e "nginx\nweb" >> $BAKsrv
    ;;
    "apache")
      echo -e "apache\nweb" >> $BAKsrv
    ;;
   "mysql_slave")
      echo -e "mysql" >> $BAKsrv
    ;;
    "mysql_server")
       echo -e "mysql" >> $BAKsrv
     ;;
    *)
      echo -e "home_folder\nsystem" >> $BAKsrv
    ;;
  esac
done

#remove duplicate services
sed -n 'G; s/\n/&&/; /^\([ -~]*\n\).*\n\1/d; s/\n//; h; P' -i $BAKsrv

#Starting BACKup
while read LINE
do
  case $LINE in
#    "nginx")
#      mkdir -p $BACKUPdir/"$HOSTNAME"/"$DATE"/nginx
#      tar -cjvf $BACKUPdir/"$HOSTNAME"/"$DATE"/nginx/nginx-"$DATE".tar.bz2 /etc/nginx
#    ;;
#    "apache")
#      mkdir -p $BACKUPdir/"$HOSTNAME"/"$DATE"/apache
#      tar -cjvf $BACKUPdir/"$HOSTNAME"/"$DATE"/apache/apache-"$DATE".tar.bz2 /etc/httpd
#    ;;
    "web")
      FOLDERbackup /var/www
      #tar czvf - /var/www | s3cmd put --add-header=x-amz-tagging:"$TAG" - s3://"$BUCKET"/"$HOSTNAME"/"$DATE"/web/web-"$DATE".tar.gz
    ;;
    "home_folder")
      FOLDERbackup /home /root
      #tar czvf - /home /root | s3cmd put --add-header=x-amz-tagging:"$TAG" - s3://"$BUCKET"/"$HOSTNAME"/"$DATE"/home_folder/home_folder-"$DATE".tar.gz
    ;;
    "system")
      FOLDERbackup /etc
      #tar czvf - /etc | s3cmd put --add-header=x-amz-tagging:"$TAG" - s3://"$BUCKET"/"$HOSTNAME"/"$DATE"/system/etc_folder-"$DATE".tar.gz
    ;;
    "mysql")
      #scrypt check mysql server status (master or slave). Backup made only
      #from slave or  standalone server
      #Does the server have "mysql_slave" metadata?
      if [[ `cat $METAfile` == *"mysql_slave"* ]]; then
        IMslave=1
        MYSQLbackup
      else
        IMslave=0
      fi
      #If server doesn't have "slave" metadata, ve tried to search the true in maxscale
      if [[ `rpm -qa maxscale` == *"maxscale"* && $IMslave == 0 ]]; then
        MAXSCALEslave=`maxctrl --tsv list servers | grep Slave | awk '{print $1 " "$2}'`
        if [[ $MAXSCALEslave == *$(hostname)* || $MAXSCALEslave == *$IPadress* ]]; then
          MYSQLbackup
          IMslave=1
        fi
      fi
      #Checked "show slave status" output. Backup can't be make if MasterIP < ServerIP.
      if [[ $IMslave == 0 ]]; then
        MASRERip=`mysql -e "show slave status \G;" | grep "Master_Host:" | awk '{print $2}'`
        SLAVEstatus=`mysql -e "show slave status \G;" | grep "Slave_SQL_Running:" | awk '{print $2}'`
        if [[ $SLAVEstatus == "" ]]; then
          MYSQLbackup
          IMslave=1
        elif [[ $SLAVEstatus == "Yes" && `sed 's/.*\.//' <<< $MASRERip` < `sed 's/.*\.//' <<< $IPadress` ]]; then
          MYSQLbackup
          IMslave=1
        elif [[ $SLAVEstatus != "Yes" ]]; then
          MYSQLbackup
          IMslave=1
        fi
      fi
    ;;
  esac
done < $BAKsrv

if [[ $ERRORbak == '1' ]]; then
  echo $HOSTNAME s3.backup.status SOME_BACKUP_ERROR | /usr/local/sbin/zabbix_send
fi

rm -f $BAKsrv
