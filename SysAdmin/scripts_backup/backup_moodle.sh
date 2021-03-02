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
        execFTP "put $1 $(echo $file_ftp | rev | cut -d "/" -f1 | rev)"
}
rmFTP(){
        execFTP "delete $1"
}
#############
cipher_key=""
dir_data_backup=""
dir_code_backup=""
# Variables FTP #
srv_ftp=""
user_ftp=""
passwd_ftp=""
date=$(date +"%Y-%m-%d_%H-%m-%S")
#################

# Creation du dump file et l'archive contenant datadir et dtb #
pg_dump --username=moodle39 --file="$dir_data_backup/moodle_${date}.sql" -C -d moodle39
chown postgres:postgres $dir_data_backup/moodle_${date}.sql
chmod +x $dir_data_backup/moodle_${date}.sql
tar --selinux -czf $dir_data_backup/moodle_${date}.tar.gz --absolute-names /var/moodledata $dir_data_backup/moodle_${date}.sql
#####################################

# Chiffrement du fichier (datadir et dtb) #
file_ftp="moodle_${date}.tar.gz"
openssl enc -e -aes-256-cbc -in $dir_data_backup/$file_ftp -out $dir_data_backup/${file_ftp}.ciph -pass pass:"$cipher_key" > /dev/null
###########################################

# Envoie sur le serveur FTP #
file_ftp="$dir_data_backup/"$(echo $file_ftp".ciph")
sendFTP $file_ftp
rm -rf $dir_data_backup/*.ciph $dir_data_backup/*.sql
#############################

# Suppression des fichiers vieux de plus de 15 jours #
# datadir et dtb #
for i in $(ls $dir_data_backup);do
        dif_date=$(echo "$((($(date +%s) - $(date -d $(echo $i | grep -Eo "[0-9]{4}(-[0-9]{2}){2}") '+%s'))/86400))")
                if [ $dif_date -ge 15 ];then
                        rm $dir_data_backup/$i
                        file_ftp="$(echo ${i}.ciph)"
                        rmFTP $file_ftp
                fi
done
########################################################

#### Sauvegarde du code de moodle ####
tar --selinux -czf /tmp/moodle_code_${date}.tar.gz --absolute-names /var/www/html/moodle
# On verifie si le code a change depuis la derniere sauvegarde #
if [[ $(md5sum $dir_code_backup/$(ls $dir_code_backup/ | sort | tail -n1) | awk '{print $1}') == $(md5sum /tmp/moodle_code_${date}.tar.gz | awk '{print $1}') ]];then
        echo "same"
        rm /tmp/moodle_code_${date}.tar.gz
else
        echo "dif"
        mv /tmp/moodle_code_${date}.tar.gz $dir_code_backup/
        file_ftp="$dir_code_backup/moodle_code_${date}.tar.gz"
        openssl enc -e -aes-256-cbc -in $file_ftp -out ${file_ftp}.ciph -pass pass:"$cipher_key" > /dev/null
        file_ftp="${file_ftp}.ciph"
        sendFTP $file_ftp
        rm -f $file_ftp
fi

######################################
# Suppression des fichiers vieux de plus de 15 jours #
for i in $(ls $dir_code_backup);do
        dif_date=$(echo "$((($(date +%s) - $(date -d $(echo $i | grep -Eo "[0-9]{4}(-[0-9]{2}){2}") '+%s'))/86400))")
        last_file=$(execFTP "dir" | grep moodle_code_ | awk '{print $NF}' | sort | tail -n1)
        if [ $dif_date -ge 15 ] && [[ ${i}.ciph != $last_file ]];then
                rm $dir_code_backup/$i
                rmFTP "${i}.ciph"
        fi
done
######################################################
exit 0
