#!/bin/bash

usage (){
	echo -e "Autorace is a bash script that will try to get a answer from every router in traceroute to the host entered. To do that, it will try many protocols and ports. After receiving an answer from a router execute mkgraph.sh that add it to .dot file.\nOptions:\n\t-a : This option is required, enter the host IPv4 address after.\n\t-f : This option is used to enter the file .dot. Be careful if this file already exist, it will be erased. If this option is not entered, this file will be CURRENT_DIR/NetMap_HOST.dot\n\t-v : Verbose option\n\t-h : Show this help message.";
}

while getopts "hva:f:" option;do
	case $option in
		h)
			usage
			exit 0;
			;;
		v)
			verb="true";
			;;
		a)
			dst=$OPTARG;
			;;
		f)
			file=$OPTARG;
			;;
	esac;
done

	# Set a default value to $file
if [ -z $file ];then
	file="NetMap_to_$dst.dot"
fi;
	# Verify that the host adresse has been entered
if [ -z $dst ];then
	usage;
	exit 1;
fi;
	# Verify that the host is reachable
ping -c1 $dst > /dev/null;
	if [ $? -eq 1 ];then
	echo -e "\n L'hôte $dst est injoignable";
	exit 1;
fi;

if [[ $verb = "true" ]];then echo -e "L'hôte $dst est joignable lancement de traceroute...\n";fi;

	## On lance un traceroute initial afin de déterminer les routeurs qui répondent pas, on remplace les * par des # et on ajoute \n a la fin de chaque pour que echo afin correctement la réponse
#trace_init=$(traceroute -n $dst | sed 's/*/#/g' | sed 's/$/\\n/g');
	## On test si tout les routeurs ont répondus, dans ce cas on affiche la réponse et on arrète le script

#if [[ $(echo -e $trace_init | grep "# # #") == "" ]];then
#	echo -e "Tout les routeurs ont répondus du premier coup... Trop facile :\n\n";
#	echo -e $trace_init;
#	exit 0;
#fi
compteur=1;
methods=("" " -I" " -T -p 25" " -T -p 123" " -T -p 22" " -T -p 80" " -T -p 443" " -U -p 21" " -U -p 53" " -U -p 68" " -U -p 69" " -U -p 179");

for compteur in $(seq 1 30);do #Main loop
	for method in "${methods[@]}";do 	
		if [[ $verb = "true" ]];then
			echo -e "Trying: traceroute -n $method -f $compteur -m $compteur $dst"
		fi;
		rep=$(traceroute -n $method -f $compteur -m $compteur $dst | sed 's/*/#/g' | sed -n "2p");
		if ! [[ $(echo $rep | grep "# # #") ]];then
			if [[ $verb = "true" ]];then
				echo -e "Answer received:\n\t$rep";	
			fi;
			rep=$(echo "$rep" | awk '{print $2}');
			break;
		elif [[ $method = " -U -p 179"  ]];then
			rep="#";
			if [[ $verb = "true" ]];then
				echo "Routeur n°$compteur is unreachable";
			fi;
		fi;
	done;
	compteur=$(($compteur + 1));
	
	if [[ $verb = "true" ]];then
		echo -e "Adding $rep to the .dot file\n";
	fi;
	
	if [[ -n $(echo -e $rep | grep $dst) ]];then
		./mkgraph.sh $file $rep 1;
		break;
	else
		./mkgraph.sh $file $rep;
	fi;	
	done;
