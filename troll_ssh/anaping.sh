#!/bin/bash
usage(){
	echo -e "This script scan the network to find the hosts that respond to the ping in the network and put it in the file machine.txt use the name of the network interface as first argument"
}

addr_masq=$(ip a s $1 | grep "inet " | cut -d " " -f6);
masque=$(echo $addr_masq| cut -d"/" -f2);
addr_host=$(echo $addr_masq | cut -d"/" -f1);
((nb_delim=masque/8));
addr_reseau=$(echo $addr_host | cut -d "." -f 1-$nb_delim)".";

for i in $(seq 1 20); do

	if [ $(ping "$addr_reseau$i.1" -c1 | grep "%" | cut -d "," -f3 | sed "s/ //g" | cut -c1) != 0 ]; then
	echo "$addr_reseau$i.1" >> machines.txt;
fi
done
machines=$(cat ./machines.txt);
nb_machines=$(cat machines.txt | wc -l);
echo -e "$nb_machines as respond to ping";
