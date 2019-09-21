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
trace_init=$(traceroute $dst | sed 's/*/#/g' | sed 's/$/\\n/g');
echo -e $trace_init;
