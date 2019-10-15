#!/bin/bash

file=${1:?Please enter a file as first argument};
host=${2:?Please enter a IPv4 address as second argument};
AS=${3:-#};
end=${4:-0};
colors=("chocolate" "crimson" "darkorange" "darkorchid4" "firebrick" "blueviolet" "red4" "salmon" "slateblue3"); # Color array
if [[ $(cat $file) = "" ]];then # Write begining of .dot file and style informations
	echo "digraph NetMap{" > $file;
	echo -e "\tbgcolor=azure;" >> $file;
	echo -e "\tnode [shape=box, color=lightblue2, style=filled];" >> $file;
	echo -e "\tedge [arrowsize=2, color=gold];" >> $file;
	echo -e "\tlocalhost [color=blue]" >> $file;
	echo -e "\tlocalhost -> " >> $file;
fi;

if [[ $AS = "#" ]];then #Check if the AS is known
	AS="AS?";
	AScolor="lightblue2";

elif ! [[ $(cat AS.tmp | grep "$AS") = "" ]];then # Check if the AS number is written in AS.tmp
	AScolor=${colors[$(cat -n AS.tmp | grep $AS | awk '{print $1}')]}; #Use the line number of AS number in color array

else
	echo $AS >> AS.tmp; # Write the AS number in AS.tmp
	AScolor=${colors[$(cat AS.tmp | wc -l)]};
fi;

if [[ $(echo $host | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}') = $host ]];then
	sed -i 's/ $/'" \"$host [$AS]\";\"$host [$AS]\" [color=$AScolor];"'/' $file;
else
	sed -i 's/ $/'" \"$host [$AS]\";\"$host [$AS]\" [color=red];"'/' $file;
fi

if [ $end -eq 0 ];then	
	echo -e "\t\"$host [$AS]\" -> " >> $file;
else
	echo -e "\t\"$host [$AS]\" [color=blue];" >> $file;
	echo "}" >> $file;
fi;
