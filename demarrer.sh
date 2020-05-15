#!/bin/bash

# Fonction pour vérifier le status de l'identification
checkLogin() {
	compte=$(/usr/bin/nordvpn account)
	[[ "$compte" != *"You are not logged in."* ]] && echo "true"
}

# Fonction pour effectuer le login
doLogin() {
if [[ "$(checkLogin)" != "true" ]]
	then
		echo "Identification en cours"
		identifiants=`zenity --password --username --title="Identification requise"`

		case $? in
	         0)
		 	nom=`echo $identifiants | cut -d'|' -f1`
		 	mdp=`echo $identifiants | cut -d'|' -f2`
		 	/usr/bin/nordvpn login --username $nom --password $mdp
		 	[[ "$(checkLogin)" != "true" ]] && doLogin
			;;
	         1)
	                echo "Login annulé."
	                zenity --info --title="Connexion au vpn impossible" --text="L'identification a échoué." --width=200 --height=100
	                exit 0
	                ;;
	        -1)
	                echo "Une erreur est survenue."
	                zenity --erreur --title="Erreur d'identification" --text="Une erreur est survenue durant l'identification" --width=200 --height=100
	                exit 0
	                ;;
		esac
	else
		echo "Identification valide"
fi
}

# Vérifier / faire le login
doLogin

# Récupération de la liste des pays disponibles
pays_disponibles=( $(/usr/bin/nordvpn countries) )
# Filtrage des élements reçus (pour éviter les valeurs en "-" au début de la liste)
liste_filtree=()
for value in "${pays_disponibles[@]}";
	do
		[[ $value != *"-"* ]] && liste_filtree+=($value);
done
IFS=$'\n' liste_ordonnee=($(sort <<<"${liste_filtree[*]}"))
unset IFS
echo "Liste des pays chargée"

# Vérification du statut actuel de la connexion
status_raw=$(/usr/bin/nordvpn status)
# Nettoyage du résultat (on vire les "-" encore)
status=${status_raw//-}
# On vire les espaces / lignes en début du statut
status=$(echo "$status" | xargs) 

# Fonction pour ouvrir la modale de connexion
showConnectModal() {
	title="Connexion à nordvpn"
					prompt="Choisissez un pays"
					opt=$(zenity --title="$title" --text="$prompt" --list --width=600 --height=400 \
			        	            --column="Pays disponibles" "${liste_ordonnee[@]}")
					echo "Choix : $opt"
					[ ! -z "$opt" ] && /usr/bin/nordvpn connect $opt
					/usr/bin/firefox --new-window https://www.whatismyip.com/fr/
}

# Connexion au vpn
if [[ "$status" == *"Connected"* ]]
	then
		echo "Déjà connecté"
		message_deconnexion="Une connexion au vpn est déjà en cours.\n\n$status \n\n\nSouhaitez-vous vous déconnecter?"
		if zenity --question --title="Déjà connecté" --text="$message_deconnexion" --width=250 --height=200
				then
					/usr/bin/nordvpn disconnect
					zenity --info --title="Déconnexion" --text="Déconnexion en cours" --timeout=1 --width=150 --height=100
					showConnectModal
		fi
	else
		echo "Aucune connexion trouvée"
		showConnectModal
fi
