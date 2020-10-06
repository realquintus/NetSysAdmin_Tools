#!/bin/bash

tool=$(dialog --backtitle "What do you want to do?" --title "Please choose your destiny" --menu "What tool do you want to use?" 20 61 5 "Autotrace" "A tool to automatize traceroute discovery by varying protocol and ports, it can also generate a beautily dot graph" "Mkgraph" "Another tool used by autotrace to create graphs, you can also use it to combine" --output-fd 1)
if [[ $tool == "Autotrace" ]];then
	host=$(dialog --backtitle "AutotraceV2 GUI" --title "Hosts" --inputbox "Enter the host's address (FQDN or IPv4). You can also enter several hosts separated by ':'" 10 60 --output-fd 1)
	cmd="./autotrace.sh -a "$host
	dialog --backtitle "AutotraceV2 GUI" --title "Generate a graph ?" --yesno "\nThis will create a .dot file that can be open with xdot\n\nDo you accept?" 10 30
	if [ $? -eq 0 ];then
		cmd=$cmd" -g"
		file=$(dialog --backtitle "AutotraceV2 GUI" --title "File name" --inputbox "Enter the name of the file with .dot at the end. If empty the file will be called NetMap.dot" 10 60 --output-fd 1)
		if [[ $file != "" ]];then
			cmd=$cmd" -f $file"
		fi
		dialog --backtitle "AutotraceV2 GUI" --title "Generate a graph ?" --yesno "\nDisplay the dot file after?\n" 10 30 --output-fd 1
		disp=$?
		nbr_host=$(($(echo $host | grep ":" | wc -l)+1))
		eval $cmd >> /tmp/autotrace_output.tmp &
		sleep 0.5
		while (true)
		do
			line=$(wc -l $file | awk '{print $1}')
			perce_per_line=$((100/(15*$nbr_host)))
			if [ $nbr_host -gt 1 ] && [ $line -ne 0 ];then
				line=$(($line-2*$nbr_host))
			fi
			progress=$(($line*$perce_per_line))
			if [[ $progress -ge 100 ]];then
				progress=99
			fi
			if [[ $(tail -n 1 $file) == "}" ]];then
				echo "test"
				break
			fi
			dialog --title "Retrieving routers" --gauge "Answer received $(tail -n 1 /tmp/autotrace_output.tmp)" 10 70 $progress &
			sleep 0.5
		done
		clear
		if [ $disp -eq 0 ];then
			xdot $file
		fi
		sudo rm /tmp/autotrace_output.tmp
	fi
else
	message=""
	while (true);do
		file1=$(dialog --colors --backtitle "Combine dot files" --title "File n°1" --inputbox "Enter the path to the first file\n\Z1 $message" 10 60 --output-fd 1)
		if [[ -e $file1 ]];then
			if [[ $file1 == $(echo $file1 | grep -E "*.dot") ]];then
				cmd="./mkgraph.sh -f $file1"
				break
			else
				message="The file you entered is not a *.dot file"
			fi
		else
			message="The file you entered does not exist"
		fi
	done
	message=""
	while (true);do
		file2=$(dialog --colors --backtitle "Combine dot files" --title "File n°2" --inputbox "Enter the path to the second file\n\Z1 $message" 10 60 --output-fd 1)
		if [[ -e $file2 ]];then
			if [[ $file2 == $(echo $file2 | grep -E "*.dot") ]];then
				cmd=$cmd" -c $file2"
				break
			else
				message="The file you entered is not a *.dot file"
			fi
		else
			message="The file you entered does not exist"
		fi
	done
	eval $cmd
fi
#rm /tmp/autotrace_gui.tmp 2> /dev/null
#clear
