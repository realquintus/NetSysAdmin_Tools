#!/bin/bash

usage (){
	echo -e "Autorace is a bash script that will try to get a answer from every router in traceroute to the host entered. To do that, it will try many protocols and ports. After receiving an answer from a router execute mkgraph.sh that add it to .dot file.\n\nOptions:\n\t-a : This option is required, enter the host's address after(FQDN or IPv4). You can also enter several hosts separated by ':'. In this case, the file will contain all the routes.\n\t-f : This option is used to enter the file .dot. Be careful if this file already exist, it will be erased. If this option is not entered, this file will be CURRENT_DIR/NetMap_HOST.dot\n\t-v : Verbose option\n\t-h : Show this help message.";
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
			if ! [[ $(echo $OPTARG | grep ":") == "" ]];then
				multiple_hosts="true";
				nbr_host=$(($(echo $OPTARG | grep -o ":" | wc -l)+1));
				list_host=$OPTARG				
			else
				nbr_host=1;
				dst=$OPTARG;
			fi;
			;;
		f)
			file=$OPTARG;
			;;
	esac;
done
#${nbr_host:?$(usage;exit 1)};
	# Set a default value to $file
if [ -z $file ];then
	file="NetMap_to_$dst.dot"
fi;
echo "" > $file;	
methods=("" " -I" " -T -p 25" " -T -p 123" " -T -p 22" " -T -p 80" " -T -p 443" " -U -p 21" " -U -p 53" " -U -p 68"); #This array contain all options and arguments that will be used with traceroute

for i in $(seq 1 $nbr_host);do
	if [[ $multiple_hosts = "true" ]];then
		dst=$(echo $list_host | cut -d":" -f1);
		list_host=$(echo $list_host | cut -d":" -f2-);
		if [[ $verb="true" ]];then
			echo -e "\nHost n°$i:\n";
		fi;
	fi;
	compteur=1;
	if ! [[ $(echo $dst | grep -E '[a-z]|[A-Z]') = "" ]];then
		echo $dst
		dst_fqdn=$dst;
		dst=$(host $dst | sed -n '1p' | awk '{print $4}');
	fi;
	for compteur in $(seq 1 30);do #Main loop
		for method in "${methods[@]}";do 	
			if [[ $verb = "true" ]];then
				echo -e "Trying: traceroute -q1 -n $method -f $compteur -m $compteur $dst"
			fi;
			rep=$(traceroute -A -z 500 -q1 -n $method -f $compteur -m $compteur $dst | sed 's/*/#/g' | sed -n "2p");# Traceroute command, replace * with # and print second line
			if [[ $(echo $rep | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}') ]];then # Check if there is a IPv4 address in traceroute answer
				if [[ $verb = "true" ]];then
					echo -e "Answer received:\n\t$rep";
				fi;
				AS=$(echo $rep | awk '{print $3}' | sed 's/\[//' | sed 's/\]//'); # Store the AS number and delete "[" and "]" because it can it will interpreted by grep in mkgraph.sh
				rep=$(echo "$rep" | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}'); # Store IPv4 address
				break;
			elif [[ $method = " -U -p 68"  ]];then # Check if it is the last method available
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
			if ! [[ $dst_fqdn = "" ]];then
				rep=$(echo "$rep:$dst_fqdn");
			fi
			if [ $i -eq $nbr_host ];then
				./mkgraph.sh -f $file -a $rep -A $AS -e file; # End of file
			else
				./mkgraph.sh -f $file -a $rep -A $AS -e route; # End of route
			fi;
			break;
		elif [ $compteur -eq 30 ];then
			rep="Max hopes reached for host $dst"
			./mkgraph.sh -f $file -a $rep -A $AS -e route
		else
			./mkgraph.sh -f $file -a $rep -A $AS;
		fi;	
	done;

done
