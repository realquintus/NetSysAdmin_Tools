#!/bin/bash

usage (){
	echo -e "Autorace is a bash script that will try to get a answer from every router in traceroute to the host entered. To do that, it will try many protocols and ports. After receiving an answer from a router execute mkgraph.sh that add it to .dot file.\n\nOptions:\n\t-a : This option is required, enter the host IPv4 address after.\n\t-f : This option is used to enter the file .dot. Be careful if this file already exist, it will be erased. If this option is not entered, this file will be CURRENT_DIR/NetMap_HOST.dot\n\t-v : Verbose option\n\t-h : Show this help message.";
}
# loop to identify options
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

echo "" > $file;
	
	# Verify that the host adresse has been entered
if [ -z $dst ];then
	usage;
	exit 1;
fi;
	# Verify that the host is reachable
ping -c1 $dst > /dev/null;
if [ $? -eq 1 ];then
	echo -e "\n The host $dst is unreachable";
	exit 1;
fi;

if [[ $verb = "true" ]];then echo -e "The host $dst is reachable, traceroute is starting...\n";fi;

compteur=1;
methods=("" " -I" " -T -p 25" " -T -p 123" " -T -p 22" " -T -p 80" " -T -p 443" " -U -p 21" " -U -p 53" " -U -p 68" " -U -p 69" " -U -p 179"); #This array contain all options and arguments that will be used with traceroute

for compteur in $(seq 1 30);do #Main loop
	for method in "${methods[@]}";do 	
		if [[ $verb = "true" ]];then
			echo -e "Trying: traceroute -q1 -n $method -f $compteur -m $compteur $dst"
		fi;
		rep=$(traceroute -A -z 3 -q1 -n $method -f $compteur -m $compteur $dst | sed 's/*/#/g' | sed -n "2p");# Traceroute command, replace * with # and print second line
		if [[ $(echo $rep | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}') ]];then # Check if there is a IPv4 address in traceroute answer
			if [[ $verb = "true" ]];then
				echo -e "Answer received:\n\t$rep";
			fi;
			AS=$(echo $rep | awk '{print $3}' | sed 's/\[//' | sed 's/\]//'); # Store the AS number and delete "[" and "]" because it can it will interpreted by grep in mkgraph.sh
			rep=$(echo "$rep" | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}'); # Store IPv4 address
			break;
		elif [[ $method = " -U -p 179"  ]];then # Check if it is the last method available
			rep="#$compteur";
			AS="#";
			if [[ $verb = "true" ]];then
				echo "Routeur n°$compteur is unreachable";
			fi;
		fi;
	done;
	compteur=$(($compteur + 1));
	
	if [[ $verb = "true" ]];then
		echo -e "Adding $rep to the .dot file\n";
	fi;
	
	if [[ -n $(echo -e $rep | grep $dst) ]];then # Check if the IPv4 address is $dst
		./mkgraph.sh -f $file -a $rep -A $AS -e; # the third argument mean end of .dot file (1) or not (0)
		break;
	else
		./mkgraph.sh -f $file -a $rep -A $AS;
	fi;	
	done;
