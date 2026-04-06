#!/bin/sh
PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/STB_UNION"
TAR_URL="https://github.com/ilyasM6/Plugins/raw/main/STB_UNION%20E2.tar.gz"
SERVERS_URL="https://github.com/ilyasM6/Plugins/raw/main/STB_UNION_servers.json"

# Nettoyage ancienne installation si existante
rm -rf "$PLUGIN_DIR"

# Téléchargement et extraction directe dans /tmp
echo "Téléchargement du plugin STB_UNION..."
wget -q --show-progress "$TAR_URL" -O /tmp/STB_UNION_E2.tar.gz

# Extraction vers le répertoire des extensions
echo "Extraction vers $PLUGIN_DIR..."
mkdir -p "$PLUGIN_DIR"
tar -xzf /tmp/STB_UNION_E2.tar.gz -C /usr/lib/enigma2/python/Plugins/Extensions/

# Ajout du fichier serveurs (si nécessaire)
echo "Ajout des serveurs..."
mkdir -p /etc/enigma2
wget -q -O /etc/enigma2/STB_UNION_servers.json "$SERVERS_URL"

# Nettoyage
rm -f /tmp/STB_UNION_E2.tar.gz

# Vérification
if [ ! -d "$PLUGIN_DIR" ]; then
    echo "Erreur : le plugin n'a pas été installé correctement."
    exit 1
fi

sync
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║     ███████╗████████╗██████╗     ██╗   ██╗███╗   ██╗██╗ ██████╗ ███╗   ██╗"
echo "║     ██╔════╝╚══██╔══╝██╔══██╗    ██║   ██║████╗  ██║██║██╔═══██╗████╗  ██║"
echo "║     ███████╗   ██║   ██████╔╝    ██║   ██║██╔██╗ ██║██║██║   ██║██╔██╗ ██║"
echo "║     ╚════██║   ██║   ██╔══██╗    ██║   ██║██║╚██╗██║██║██║   ██║██║╚██╗██║"
echo "║     ███████║   ██║   ██████╔╝    ╚██████╔╝██║ ╚████║██║╚██████╔╝██║ ╚████║"
echo "║     ╚══════╝   ╚═╝   ╚═════╝      ╚═════╝ ╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝"
echo "║                                                                      ║"
echo "║                    SCRIPT D'INSTALLATION V1.0                        ║"
echo "║                     INTERFACE ENIGMA2                                ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo "#########################################################"
echo "#       STB_UNION E2 INSTALLED SUCCESSFULLY            #"
echo "#                 by ilyasM6 / electroyassine           #"
echo "#########################################################"
echo "#           your Device will RESTART Now                #"
echo "#########################################################"
sleep 3
init 4 && sleep 2 && init 3
exit 0
