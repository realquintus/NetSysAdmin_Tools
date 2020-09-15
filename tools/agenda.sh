#!/bin/bash
usage (){
	echo "This script is used to automaticaly connect to my agenda"
}
write_logs (){
	for i in $(seq 1 $(expr length "$login"));do
		temp_char=$(echo $1 | cut -c $i)
		case $temp_char in
			".")
				temp_char=0x2e
			;;
			"@")
				temp_char=0x40
			;;	
			"#")
				temp_char=0x23
			;;
		esac;
	xdotool key "$temp_char"
	done
}
while getopts "hcl:m:" option;do
	case $option in
		h)
			usage
			exit 0;
			;;
		v)
			verb="true";
			;;
		l)
			login=$OPTARG
			;;
		m)
			mdp=$OPTARG
			;;
	esac;
done
firefox https://my.epf.fr/ressourcesHelisa/emplois_du_temps/PROMOTIONS/empclajs.htm
sleep 1
write_logs $login
xdotool key Tab
write_logs $mdp
xdotool key Tab
xdotool key Tab
xdotool key Return
i3-msg "[id="$(xdotool search --desktop --name 'Firefox' | sed -n 1p)"] focus"
xdotool key Tab
xdotool key Tab
for j in $(seq 1 16);do
	xdotool key Down
done
xdotool key Return
