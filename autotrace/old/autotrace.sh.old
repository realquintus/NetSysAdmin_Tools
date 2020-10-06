#!/bin/bash

usage (){
	echo -e "Autotrace est un script automatisant l'utilisation de traceroute en essayant d'obtenir une réponse de tout les routeurs en faisant varier le port de destination ou le protocole. Entrez l'adresse IP destination en premier argument"
}
	# On test si l'argument 1 existe
dst=${1:?usage};	
# On test si l'hôte est joignable
if ! [[ $(ping $dst -c1 | grep "%" | cut -d "," -f3 | sed "s/ //g" | cut -c1) == "0" ]]; then
	usage;
	echo -e "\n L'hôte $dst est injoignable";
	exit 1;
fi
echo -e "L'hôte $dst est joignable lancement de traceroute...\n";

	# On lance un traceroute initial afin de déterminer les routeurs qui répondent pas, on remplace les * par des # et on ajoute \n a la fin de chaque pour que echo afin correctement la réponse
trace_init=$(traceroute -n $dst | sed 's/*/#/g' | sed 's/$/\\n/g');
	# On test si tout les routeurs ont répondus, dans ce cas on affiche la réponse et on arrète le script

if [[ $(echo -e $trace_init | grep "# # #") == "" ]];then
	echo -e "Tout les routeurs ont répondus du premier coup... Trop facile :\n\n";
	echo -e $trace_init;
	exit 0;
fi

compteur=1;

while [ true  ];do #Boucle principale
	echo "Testing default configuration";
	rep=$(traceroute -n -f $compteur -m $compteur $dst | sed 's/*/#/g' | sed 's/$/\\n/g' | sed -n "2p");
	if [[ $(echo $rep | grep "# # #") == "" ]];then
		echo -e $rep | grep -v "traceroute";
	# Test si le routeur $compteur réponds a une trame tarceroute par défaut
	else
		echo -e "\tICMP";
		rep=$(traceroute -n -f $compteur -m $compteur -I $dst | sed 's/*/#/g' | sed 's/$/\\n/g' | sed -n "2p");
		if [[ $(echo -e  $rep | grep "# # #") == "" ]];then
			echo -e $rep | grep -v "traceroute";
		# Test si le routeur répond à une trame ICMP
		else
			echo -e "\tTCP  \n\t\ton smtp port";
			rep=$(traceroute -n -f $compteur -m $compteur -T -p 25 $dst | sed 's/*/#/g' | sed 's/$/\\n/g' | sed -n "2p");
			if [[ $(echo -e  $rep | grep "# # #") == "" ]];then
				echo -e $rep | grep -v "traceroute";
			else
				echo -e "\t\ton NTP port";
				rep=$(traceroute -n -f $compteur -m $compteur -T -p 123 $dst | sed 's/*/#/g' | sed 's/$/\\n/g' | sed -n "2p");
				
				if [[ $(echo -e  $rep | grep "# # #") == "" ]];then
					echo -e $rep | grep -v "traceroute";
				else
					
					echo -e "\t\ton SSH port";
					rep=$(traceroute -n -f $compteur -m $compteur -T -p 22 $dst | sed 's/*/#/g' | sed 's/$/\\n/g' | sed -n "2p");
				
					if [[ $(echo -e  $rep | grep "# # #") == "" ]];then
						echo -e $rep | grep -v "traceroute";
					else			
			
						echo -e "\t\ton HTTP port";
						rep=$(traceroute -n -f $compteur -m $compteur -T -p 80 $dst | sed 's/*/#/g' | sed 's/$/\\n/g' | sed -n "2p");
						if [[ $(echo -e  $rep | grep "# # #") == "" ]];then
							echo -e $rep | grep -v "traceroute";
						else
							
							echo -e "\t\ton HTTPS port";
							rep=$(traceroute -n -f $compteur -m $compteur -T -p 443 $dst | sed 's/*/#/g' | sed 's/$/\\n/g' | sed -n "2p");
							if [[ $(echo -e  $rep | grep "# # #") == "" ]];then
								echo -e $rep | grep -v "traceroute";
							else
								echo -e "\tUDP";
								declare -a ports=(21 53 68 69 179);
								for i in ${ports[*]};do
									rep=$(traceroute -n -f $compteur -m $compteur -p $i $dst | sed 's/*/#/g' | sed 's/$/\\n/g' | sed -n "2p");
									echo -e "\t\t on port number $i";
									if [[ $(echo -e  $rep | grep "# # #") == "" ]];then
										echo -e $rep | grep -v "traceroute";
										break;
									fi;
								done
echo -e "Router $compteur is unreachable\n";
							fi;
						fi;
					fi;
				fi;
			fi;
		fi;
	fi;
	
	compteur=$(($compteur + 1));
	if [[ -n $(echo -e $rep | grep $dst) || $compteur == 30 ]];then
		break;
	fi;
	
	done;
