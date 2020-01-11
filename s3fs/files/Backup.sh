#!/bin/bash

BACKUPdir="/backup"
PASSWDfile="/etc/.s3fs_pass"
BUCKET="trafficterminal-backup"
BAKsrv=$(mktemp /tmp/backup_service.XXXXXXXXXX)
DATE=`date +"%m-%d-%Y"`
METAfile="/etc/zabbix/conf.d/metadata.conf"
HOSTNAME=`hostname -f`
IPadress=`facter | grep ipaddress_eth0 | awk '{print $3}'`
#Check BACKUPdir. If s3fs not mounted, scrypt tryed to mount backup folder and
#check again. If after mount BACKUPdir doesnt mount, scrypt aborted with exit code 1

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
  xtrabackup --defaults-extra-file=~/.my.cnf --backup --no-lock --databases-file=$BAKdb --compress --target-dir=$BACKUPdir/"$HOSTNAME"/"$DATE"/mysql/
  cp $BAKdb $BACKUPdir/"$HOSTNAME"/"$DATE"/mysql/DB_to_backup.txt

  #Check backup files
  DATAdir=`cat /etc/my.cnf | grep datadir | sed 's/.*=//'`
  if [[ $DATAdir == "" ]]; then
    DATAdir="/var/lib/mysql"
  fi
  while read DB
  do
    ORIGINfiles=`ls $DATAdir/"$DB"/ | grep -c "\."`
    BACKUPfiles=`ls $BACKUPdir/"$HOSTNAME"/"$DATE"/mysql/"$DB" | grep -c "\."`
    if [[ $ORIGINfiles != $BACKUPfiles ]]; then
      echo "somesing go wrong with $DB database"
    else
      echo "Master, I found all files for $DB database"
    fi
  done < $BAKdb

  rm -f $BAKdb
}

#START SCRYPT
#------------
rpm -q --quiet bzip2 || yum install -y bzip2
CHECK=`mount | grep "$BACKUP"`
if [[ $CHECK != *"s3fs"* ]]; then
  echo "$BACKUPdir doesnt mount"
  if [[ -d $BACKUPdir ]]; then
    {
      s3fs $BUCKET $BACKUPdir -o passwd_file=$PASSWDfile
    } || {
      echo "Pizdets"
      exit 1
    }
  else
    {
      mkdir $BACKUPdir
      s3fs $BUCKET $BACKUPdir -o passwd_file=$PASSWDfile
    } || {
      echo "Pizdets 1"
      exit 1
    }
  fi
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
      echo -e "hamster\nsystem" >> $BAKsrv
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
      mkdir -p $BACKUPdir/"$HOSTNAME"/"$DATE"/web
      tar -cjvf $BACKUPdir/"$HOSTNAME"/"$DATE"/web/web-"$DATE".tar.bz2 /var/www
    ;;
    "hamster")
      mkdir -p $BACKUPdir/"$HOSTNAME"/"$DATE"/hamster
      tar -cjvf $BACKUPdir/"$HOSTNAME"/"$DATE"/hamster/home_folder-"$DATE".tar.bz2 /home /root
    ;;
    "system")
      mkdir -p $BACKUPdir/"$HOSTNAME"/"$DATE"/system
      tar -cjvf $BACKUPdir/"$HOSTNAME"/"$DATE"/system/etc_folder-"$DATE".tar.bz2 /etc
    ;;
    "mysql")
      mkdir -p $BACKUPdir/"$HOSTNAME"/"$DATE"/mysql
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

rm -f $BAKsrv
