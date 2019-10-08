#!/bin/bash

usage (){
	echo -e "Autotrace est un script automatisant l'utilisation de traceroute en essayant d'obtenir une réponse de tout les routeurs en faisant varier le port de destination ou le protocole. Entrez l'adresse IP destination en premier argument"
}
	# On test si l'argument 1 existe
if [[ -z $1 ]]; then
	usage
	exit 1
fi
	# On test si l'hôte est joignable
if ! [[ $(ping $1 -c1 | grep "%" | cut -d "," -f3 | sed "s/ //g" | cut -c1) == "0" ]]; then
	usage;
	echo -e "\n L'hôte $1 est injoignable";
	exit 1;
fi
dst=$1;
echo -e "L'hôte $dst est joignable lancement de traceroute...\n";
	# On lance un traceroute initial afin de déterminer les routeurs qui répondent pas, on remplace les * par des # et on ajoute \n a la fin de chaque pour que echo afin correctement la réponse
trace_init=$(traceroute -n $dst | sed 's/*/#/g' | sed 's/$/\\n/g');
	# On test si tout les routeurs ont répondus, dans ce cas on affiche la réponse et on arrète le script
if [[ $(echo -e $trace_init | grep "# # #") == "" ]];then
	echo -e "Tout les routeurs ont répondus du premier coup... Trop facile :\n\n";
	echo -e $trace_init;
	exit 0;
fi
	# On récupère le ttl des routeurs qui ne répondent pas
compteur=1;

while [ true  ];do #Boucle principale
	echo "Testing default conf";
	rep=$(traceroute -n -f $compteur -m $compteur $dst | sed 's/*/#/g' | sed 's/$/\\n/g');
	if [[ $(echo $rep | grep "# # #") == "" ]];then
		echo -e $rep | grep -v "traceroute";
	# Test si le routeur $compteur réponds a une trame tarceroute par défaut
	else
		echo "Testing ICMP";
		rep=$(traceroute -n -f $compteur -m $compteur -I $dst | sed 's/*/#/g' | sed 's/$/\\n/g');
		if [[ $(echo -e  $rep | grep "# # #") == "" ]];then
			echo -e $rep | grep -v "traceroute";
		# Test si le routeur répond à une trame ICMP
		else
			echo "Testing TCP";
			rep=$(traceroute -n -f $compteur -m $compteur -T -p 25 $dst | sed 's/*/#/g' | sed 's/$/\\n/g');
			if [[ $(echo -e  $rep | grep "# # #") == "" ]];then
				echo -e $rep | grep -v "traceroute"
			else
				echo -e "Router $compteur is unreachable\n";
			fi;
		fi;
	fi;
	compteur=$(($compteur + 1));
	if ! [[ $(echo $rep | grep -v "hops" | grep $1) == "" ]];then
		echo "$rep";
		break;
		fi;
	echo $rep | grep "$1" | grep -v "traceroute";
	done;
