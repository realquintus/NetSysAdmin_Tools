#!/bin/bash

file=${1:?Please enter a file as first argument};
host=${2:?Please enter a IPv4 address as second argument};
end=${3:-0};

if ! [[ -a ./$file ]];then
	echo "digraph NetMap{" > $file;
	echo -e "\tlocalhost -> " >> $file;
fi;

sed -i 's/ $/'" \"$host\";"'/' $file;
if [ $end -eq 0 ];then	
	echo -e "\t\"$host\" -> " >> $file;
else	
	echo "}" >> $file;
fi;
