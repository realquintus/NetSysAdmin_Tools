#!/bin/bash

# Fonctions #
execFTP(){
ftp -n $srv_ftp <<END_SCRIPT
quote USER $user_ftp
quote PASS $passwd_ftp
cd /backup_moodle
$1
close
END_SCRIPT
}
sendFTP(){
        execFTP "put $file_ftp $(echo $file_ftp | rev | cut -d "/" -f1 | rev)"
}
rmFTP(){
        execFTP "delete /backup_moodle/$file_ftp"
}
#############

# Variables #
srv_ftp="###"
user_ftp="###"
passwd_ftp="###"
date=$(date +"%Y-%m-%d_%H-%m-%S")
ciph_key="###"
#################

# Creation du dump file et l'archive contenant datadir et dtb #
pg_dump --username=moodle39 --file="/root/backup/moodle_${date}.sql" -C -d moodle39
chown postgres:postgres /root/backup/moodle_${date}.sql
chmod +x /root/backup/moodle_${date}.sql
tar --selinux -czf /root/backup/moodle_${date}.tar.gz --absolute-names /var/moodledata /root/backup/moodle_${date}.sql
#####################################

# Chiffrement du fichier (datadir et dtb) #
file_ftp="moodle_${date}.tar.gz"
openssl enc -e -aes-256-cbc -in /root/backup/$file_ftp -out /root/backup/${file_ftp}.ciph -pass pass:"$ciph_key" > /dev/null
###########################################

# Envoie sur le serveur FTP #
file_ftp="/root/backup/"$(echo $file_ftp".ciph")
sendFTP
rm -rf /root/backup/*.ciph /root/backup/*.sql
#############################

# Suppression des fichiers vieux de plus de 30 jours #
# datadir et dtb #
for i in $(ls /root/backup/);do
        dif_date=$(echo "$((($(date +%s) - $(date -d $(echo $i | grep -Eo "[0-9]{4}(-[0-9]{2}){2}") '+%s'))/86400))")
                if [ $dif_date -ge 30 ];then
                        rm /root/backup/$i
                        file_ftp="$(echo ${i}.ciph)"
                        rmFTP
                fi
done
########################################################

#### Sauvegarde du code de moodle ####
tar --selinux -czf /tmp/moodle_code_${date}.tar.gz --absolute-names /var/www/html/moodle
# On verifie si le code a change depuis la derniere sauvegarde #
if [[ $(md5sum /root/moodle_code.bak/$(ls /root/moodle_code.bak/ | sort | tail -n1) | awk '{print $1}') == $(md5sum /tmp/moodle_code_${date}.tar.gz | awk '{print $1}') ]];then
        rm /tmp/moodle_code_${date}.tar.gz
else
        mv /tmp/moodle_code_${date}.tar.gz /root/moodle_code.bak/
        file_ftp="/root/moodle_code.bak/moodle_code_${date}.tar.gz"
        openssl enc -e -aes-256-cbc -in $file_ftp -out ${file_ftp}.ciph -pass pass:"$ciph_key" > /dev/null
        file_ftp="${file_ftp}.ciph"
        sendFTP
        rm -f $file_ftp
fi
######################################
# Suppression des fichiers vieux de plus de 30 jours #
for i in $(ls /root/moodle_code.bak);do
        dif_date=$(echo "$((($(date +%s) - $(date -d $(echo $i | grep -Eo "[0-9]{4}(-[0-9]{2}){2}") '+%s'))/86400))")
        last_file=$(execFTP "dir" | grep moodle_code_ | awk '{print $9}' | sort | tail -n1)
        if [ $dif_date -ge 30 ] && [[ $i != $last_file ]];then
                rm /root/moodle_code.bak/$i
                file_ftp=$1
                rmFTP
        fi
done
######################################################
exit 0
