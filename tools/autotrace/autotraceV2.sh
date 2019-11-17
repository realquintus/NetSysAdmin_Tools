#!/bin/bash

##################################################################################################
#					AUTOTRACE SCRIPT					 #
#     Web interface available at the following link: https://phousse.fr/projects/autotrace	 #
##################################################################################################
usage (){
	echo -e "Autorace is a bash script that will try to get a answer from every router in traceroute to the host entered. To do that, it will try many protocols and ports. After receiving an answer from a router execute mkgraph.sh that add it to .dot file.\n\nOptions:\n\t-a : This option is required, enter the host's address after(FQDN or IPv4). You can also enter several hosts separated by ':'. In this case, the file will contain all the routes.\n\t-g : This option allows you to generate a graph\n\t\t-f : This option needs to be used with -g, otherwise it will be useless. -f is used to indicate the name of the graph file. Be careful if this file already exist, it will be erased. If this option is not entered, this file will be CURRENT_DIR/NetMap_HOST.dot\n\t-v : Verbose option\n\t-h : Show this help message.";
}
## loop to identify options
while getopts "hva:f:g" option;do
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
		g)
			graph="true"
			;;
	esac;
done
##
if [ -z $nbr_host ];then
	echo "Error: No host entered... Diplay usage message:"
	usage;
	exit 1;
fi
if [ -z $file ];then # Set default value to $file
	file="NetMap_to_$dst.dot"
fi;
if [[ $graph = "true" ]];then
	echo "" > $file;	
fi;
methods=("" " -I" " -T -p 25" " -T -p 123" " -T -p 22" " -T -p 80" " -T -p 443" " -U -p 21" " -U -p 53" " -U -p 68"); #This array contain all options and arguments that will be used with traceroute

### Loop for diferents hosts
for i in $(seq 1 $nbr_host);do 
	if [[ $multiple_hosts = "true" ]];then
		dst=$(echo $list_host | cut -d":" -f1); # Extracting host from the list
		list_host=$(echo $list_host | cut -d":" -f2-); # Remove the host that will be use from the list
		if [[ $verb="true" ]];then
			echo -e "\nHost n°$i:";
		fi;
	fi;
	compteur=1;
	if ! [[ $(echo $dst | grep -E '[a-z]|[A-Z]') = "" ]];then
		dst_fqdn=$dst;
		dst=$(host $dst | sed -n '1p' | awk '{print $4}'); # DNS request
	fi;
	#### Loop for number of hops
	for compteur in $(seq 1 30);do
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
			elif [[ $method = ${methods[-1]}  ]];then # Check if it is the last method available
				rep="#$compteur";
				AS="#";
				if [[ $verb = "true" ]];then
					echo "Routeur n°$compteur is unreachable";
				fi;
			fi;
		done;
		compteur=$(($compteur + 1));
		if [[ $graph = "true" ]];then
			if [[ $verb = "true" ]];then
				echo -e "Adding $rep to the .dot file\n";
			fi;
			if [[ -n $(echo -e $rep | grep $dst) ]];then # Check if the IPv4 address is $dst
				if ! [[ $dst_fqdn = "" ]];then
					rep=$(echo "$rep:$dst_fqdn");
				fi
				if [ $i -eq $nbr_host ];then # Check if it's the last host to close the file
					./mkgraph.sh -f $file -a $rep -A $AS -e file; # End of file
				else
					./mkgraph.sh -f $file -a $rep -A $AS -e route; # End of route
				fi;
			elif [ $compteur -eq 30 ];then
				rep="Max hopes reached for host $dst"
				./mkgraph.sh -f $file -a $rep -A $AS -e route
			else
				./mkgraph.sh -f $file -a $rep -A $AS;
			fi;	
		fi;
		echo "$rep [$AS]";
		if [[ -n $(echo -e $rep | grep $dst) ]];then # Check if the IPv4 address is $dst
			break;
		fi;
	done;
	####

done;
###
