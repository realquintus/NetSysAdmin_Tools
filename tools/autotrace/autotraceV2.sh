#!/bin/bash

usage (){
	echo -e "Autorace is a bash script that will try to get a answer from every router in traceroute to the host. To do that, it will try many protocols and ports.\nOptions:\n\t-a : This option is required, enter the host IPv4 address after.\n\t-v : Verbosee option\n\t-h : Show this help message."
}

while getopts "hva:" option;do
	echo $option $OPTARG;
	case $option in
		h)
			usage
			;;
		v)
			verb="true";
			;;
		a)
			dst=$OPTARG;
			;;
	esac;
done

	# On test si l'argument 1 existe
#dst=${1:?$(usage)};
# On test si l'hôte est joignable
if ! [[ $(ping $dst -c1 | grep "%" | cut -d "," -f3 | sed "s/ //g" | cut -c1) == "0" ]]; then
	usage;
	echo -e "\n L'hôte $dst est injoignable";
	exit 1;
fi
echo -e "L'hôte $dst est joignable lancement de traceroute...\n";

	# On lance un traceroute initial afin de déterminer les routeurs qui répondent pas, on remplace les * par des # et on ajoute \n a la fin de chaque pour que echo afin correctement la réponse
#trace_init=$(traceroute -n $dst | sed 's/*/#/g' | sed 's/$/\\n/g');
	# On test si tout les routeurs ont répondus, dans ce cas on affiche la réponse et on arrète le script

#if [[ $(echo -e $trace_init | grep "# # #") == "" ]];then
#	echo -e "Tout les routeurs ont répondus du premier coup... Trop facile :\n\n";
#	echo -e $trace_init;
#	exit 0;
#fi
compteur=1;
methods=("" " -I" " -T -p 25" " -T -p 123" " -T -p 22" " -T -p 80" " -T -p 443" " -U -p 21" " -U -p 53" " -U -p 68" " -U -p 69" " -U -p 179");


for compteur in $(seq 1 30);do #Boucle principale
	for method in "${methods[@]}";do 	
		rep=$(traceroute -n $method -f $compteur -m $compteur $dst | sed 's/*/#/g' | sed -n "2p");
		if ! [[ $(echo $rep | grep "# # #") ]];then
			rep=$(echo "$rep" | awk '{print $2}');
			break;
		elif [[ $method = " -U -p 179"  ]];then
			rep="#";
		fi;
	done;
	compteur=$(($compteur + 1));
	if [[ -n $(echo -e $rep | grep $dst) ]];then
		./mkgraph.sh "NetMap_to_$dst.dot" $rep 1
		break;
	else
		./mkgraph.sh "NetMap_to_$dst.dot" $rep;
	fi;	
	done;
