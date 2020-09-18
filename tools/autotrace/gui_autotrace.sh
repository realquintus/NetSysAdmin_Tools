#!/bin/bash
echo "test"
options=""
dialog --backtitle "AutotraceV2 GUI" --title "Hosts" --inputbox "Enter the host's address (FQDN or IPv4). You can also enter several hosts separated by ':'" 10 60 2> /tmp/autotrace.tmp
options="-a "$(cat /tmp/autotrace.tmp)
dialog --backtitle "AutotraceV2 GUI" \
 	--title "Generate a graph ?" \
       --yesno "\nThis will create a .dot file that can be open with xdot\n\nDo you accept?" 10 30
if [ $? -eq 0 ];then
	options=$options" -g"
	dialog --backtitle "AutotraceV2 GUI" --title "File name" --inputbox "Enter the name of the file with .dot at the end. If empty the file will be called NetMap.dot" 10 60 2> /tmp/autotrace.tmp
	options=$options" -f $(cat /tmp/autotrace.tmp)"
	file=$(cat /tmp/autotrace.tmp)
	dialog --backtitle "AutotraceV2 GUI" \
	 	--title "Generate a graph ?" \
	       --yesno "\nDisplay the dot file after?\n" 10 30
	if [ $? -eq 0 ];then
		disp="true"
	fi
fi
./autotraceV2.sh $options -v
if [[ $disp == "true" ]];then
	xdot $file
fi
rm /tmp/autotrace.tmp
