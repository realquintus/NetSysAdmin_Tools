#!/bin/bash
nbline=1;
while read line
do
	if [[ $(echo "$line" | awk '{print $1}') = $(echo "$line" | sed 's/;//g' | awk '{print $3}') ]];then
		sed "$nbline d" $1;
	fi;
	nbline=$(($nbline + 1));
done < $1
