#!/bin/bash

# Variables FTP #
srv_ftp="XXX"
user_ftp="XXX"
passwd_ftp="XXX"
dir_ftp="XXX" # Laissez vide pour enregistrer a la racine (Ne pas mettre le dernier /
db_user="XXX"
db_name="XXX"
dir_of_file="XXX" # Ne pas mettre le dernier /
ciph_key="XXX"
#################

# Creation du dump file #
id_pg=$(docker ps | grep "postgres" | awk '{print $1}')
docker exec $id_pg pg_dump --username=$db_user --file="/dump_db/$db_name_`date +"%Y-%m-%d_%H:%m:%S"`.sql" -C -d $db_name
file_ftp=$(ls $dir_of_file)
#########################
# Chiffrement du fichier #
openssl enc -e -aes-256-cbc -in $dir_of_file/$file_ftp -out /tmp/$file_ftp -pass pass:"$ciph_key"
##########################

# Envoie sur le serveur FTP #
ftp -n $srv_ftp <<END_SCRIPT
quote USER $user_ftp
quote PASS $passwd_ftp
cd $dir_ftp
send /tmp/$file_ftp $dir_ftp/$file_ftp
END_SCRIPT
#############################

rm /tmp/$file_ftp
mv $dir_of_file/$file_ftp /root/db_backup/$file_ftp

# Suppression des fichiers vieux de plus de 30 jours #
for i in $(ls /root/db_backup/);do
	        dif_date=$(echo "$((($(date +%s) - $(date -d $(echo $i | grep -Eo "[0-9]{4}(-[0-9]{2}){2}") '+%s'))/86400))")
		        if [ $dif_date -ge 30 ];then
				                rm /root/db_backup/$i
						ftp -n $srv_ftp <<END_SCRIPT
quote USER $user_ftp
quote PASS $passwd_ftp
cd $dir_ftp
delete dir_ftp/$i
END_SCRIPT
        fi
done
########################################################
exit 0
