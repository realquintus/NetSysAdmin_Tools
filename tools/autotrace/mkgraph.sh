#!/bin/bash
usage()
{
	echo -e "Mkgraph is a script that can create or combine dot files in order to make a net map.\n\nOptions:\n\t-f : This option is required, enter a file that will be used to create the dot file.\n\t-a : Use this option to enter the IPv4 address that will be add to the file.\n\t-A : Use this option to enter a AS number, if not entered the AS will be [AS?].\n\t-e : This option can handle two different argument which are: \n\t\troute : It indicates that this line is the last of the route.\n\t\tfile : It indicates that this line is the last of the dot file.\n\t-c : This option is used to combine 2 dot in a file named NetMap.dot. Enter the second file after. You can also choose a name different than NetMap by indicating the name after ':'.\n\t\tExample: ./mkgraph.sh -f file.dot -c other_file.dot:example.dot\n\t\t-m : This option need to by used with -c. It will add the fill entered with -c to the file entered with -f";
}
### Function that associates the AS number given as an arguments to a color
colorAS()
{
	if [[ $1 = "#" ]];then
		echo "lightblue2";
	elif ! [[ $(cat AS.txt | grep -E "^$1 ") = "" ]];then # Check if the AS number is written in AS.txt
		echo $(cat AS.txt | grep "^$1 "  | awk '{print $2}'); #Use the line number of AS number in color array
	else
		randomcolor=$(echo "#$(openssl rand -hex 3)")
		echo "$AS $randomcolor" >> AS.txt;
		echo $randomcolor;
	fi;
}	

### Loop to identify option
while getopts "hc:f:a:A:e:m" option;do
	case $option in
		h)
			usage
			exit 0;
			;;
		c)
			combine="true";
			if [[ $(echo $OPTARG | grep ":") ]];then
				file_to_combine=$(echo $OPTARG | cut -d":" -f1);
				dst_file=$(echo $OPTARG | cut -d":" -f2);
			else
				file_to_combine=$OPTARG;
				dst_file="NetMap.dot";
			fi;
			;;
		f)
			file=$OPTARG;
			;;
		a)
			if [[ $(echo $OPTARG | grep ":") ]];then
				host_fqdn=$(echo "$(echo $OPTARG | cut -d":" -f2): ");
				host=$(echo $OPTARG | cut -d":" -f1);
			else
				host=$OPTARG;
			fi;
			;;
		A)
			AS=$OPTARG;
			;;
		e)
			end="true";
			var_end=$OPTARG;
			;;
		m)
			if [[ $combine = "true" ]];then
				modify="true";
				dst_file=$file;
			else
				usage;
				exit 1;
			fi;
			;;
		esac;
done
colors=("bisque4" "darkorange4" "darkorange" "darkorchid4" "firebrick" "chocolate" "blueviolet" "red4" "salmon" "slateblue3" "goldenrod" "darkslategrey" "darkslategrey" "peru" "yellowgreen" "crimson"); # Color array

if [[ $combine = "true" ]];then ## Combine option
	if [[ $modify = "true" ]];then
		sed -i '$d' $file;
	else
		sed '$d' $file > $dst_file; 
	fi;
	nbr_routes=$(($(cat $dst_file | grep localhost | wc -l)-1)); ## Count the number of "localhost" in the file
	arrow_color=${colors[$nbr_routes]}
	echo -e "\tedge [arrowsize=2, color=$arrow_color];" >> $dst_file;
	sed '1,5d' $file_to_combine >> $dst_file;
	
else
	if ! [[ -f AS.txt ]];then
		touch AS.txt;
	fi;
	if [[ $(cat $file) = "" ]];then # Write begining of .dot file and style informations
		echo "digraph NetMap{" > $file;
		echo -e "\tbgcolor=azure;" >> $file;
		echo -e "\tnode [shape=box, color=lightblue2, style=filled];" >> $file;
		echo -e "\tedge [arrowsize=2, color=gold];" >> $file;
		echo -e "\tlocalhost [color=blue]" >> $file;
		echo -e "\tlocalhost -> " >> $file;
	fi;
	AS=$(echo $AS | tr "/" ";"); # Replace / with ; to prevent the interpretation of character by sed
	AScolor=$(colorAS $(echo $AS)); # Use AScolor() function in order to determine the color of the AS
	
	if [[ $(echo $host | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}') = $host ]];then # Check if $host is truly a IPv4 address
		sed -i 's/ $/'" \"$host_fqdn$host [$AS]\";\"$host_fqdn$host [$AS]\" [color=\"$AScolor\"];"'/' $file; # Complete the last line of the file with the new host and his color
	else
		sed -i 's/ $/'" \"$host_fqdn$host [$AS]\";\"$host [$AS]\" [color=red];"'/' $file; # Same but with red color because the router did respond
	fi;
	
	if ! [[ $end = "true" ]];then	
		echo -e "\t\"$host_fqdn$host [$AS]\" -> " >> $file; # Put the beginning of a new line in the file only if it is'nt the end
	else
		echo -e "\t\"$host_fqdn$host [$AS]\" [$(cat $file | grep "arrowsize" | sed -n '$p' | awk '{print $3}')" >> $file; # Put the destination address in blue
		if [[ $var_end = file ]];then
			echo "}" >> $file; # finish the file with "}"
		else
			nbr_routes=$(($(cat $file | grep localhost | wc -l)-1)); # Count occurences of "localhost" in order to determine the number of routes
			arrow_color=${colors[$nbr_routes]}; # Use this number of routes in color's array to define a arrow color
			echo -e "\tedge [arrowsize=2, color=$arrow_color];" >> $file; # Begin a new route
			echo -e "\tlocalhost -> " >> $file;
		fi;
	fi;
fi;
