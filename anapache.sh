#!/bin/bash

usage(){
	echo -e "Anapache est un script analysant les logs de apache, entrez le nom du fichier .txt à analyser en premier argument du script"
}

if ! [[ -s $1 && $1 == *.txt ]] ; then
	usage
	exit 1
fi

echo -e "\n"
date_first=$(cat $1 | head -n 1 | awk -F "[" '{print substr($2,1,26)}')
date_last=$(cat $1 | tail -n 1 | awk -F "[" '{print substr($2,1,26)}')
heure_first=$(echo $date_first | awk -F ":" '{printf("%s:%s:%s",$2,$3,$4)}' | cut -d " " -f 1)
heure_last=$(echo $date_last | awk -F ":" '{printf("%s:%s:%s",$2,$3,$4)}' | cut -d " " -f 1)
date_first=$(echo $date_first | cut -d ":" -f 1)
date_first=$(echo $date_last | cut -d ":" -f 1)
echo -e "Date du premier enregistrement: $date_first à $heure_first\nDate du dernier enregistrement: $date_last à $heure_last\n"

nbrLigne=$(cat $1 | grep -ivE ".txt|.gif|.jpg|.png" | wc -l)

echo -e "Nombre de pages vues:    $nbrLigne  (hits sans graphiques ni textes)\n"
echo "Nombre de bytes transférés: $(awk '{sum += $10} END {print sum}' logs-www-complet-last.ano.txt)";
echo "Les dix pages les plus populaires: $(cat logs-www-complet-last.ano.txt | awk '{print $7}' "$1" | grep -ivE '.png|.gif|.js|.jpg|.ico|.css|.userImg' | \
sed -E 's/(.*)\/$/\1/' | \
sort | \
uniq -c | sort -rn | head -10)";
