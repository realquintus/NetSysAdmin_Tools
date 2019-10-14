#!/bin/bash

file=${1:?Please enter a file as first argument};
host=${2:?Please enter a IPv4 address as second argument};
end=${3:-0};
if [[ $(cat $file) = "" ]];then
	echo "digraph NetMap{" > $file;
	echo -e "\tbgcolor=azure;" >> $file;
	echo -e "\tnode [shape=box, color=lightblue2, style=filled];" >> $file;
	echo -e "\tedge [arrowsize=2, color=gold];" >> $file;
	echo -e "\tlocalhost [color=blue]" >> $file;
	echo -e "\tlocalhost -> " >> $file;
fi;

if [[ $(echo $host | grep "#") = $host ]];then
	sed -i 's/ $/'" \"$host\";\"$host\" [color=red];"'/' $file;
else
	sed -i 's/ $/'" \"$host\";"'/' $file;
fi
if [ $end -eq 0 ];then	
	echo -e "\t\"$host\" -> " >> $file;
else
	echo -e "\t\"$host\" [color=blue];" >> $file;
	echo "}" >> $file;
fi;
