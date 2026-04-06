#!/bin/sh
PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/STB_UNION"
TAR_URL="https://github.com/ilyasM6/Plugins/raw/main/STB_UNION%20E2.tar.gz"
SERVERS_URL="https://github.com/ilyasM6/Plugins/raw/main/STB_UNION_servers.json"
SERVERS_FILE="/etc/enigma2/STB_UNION_servers.json"
BACKUP_DIR="/etc/enigma2/backups"

# Nettoyage ancienne installation si existante
rm -rf "$PLUGIN_DIR"

# Sauvegarde du fichier serveurs s'il existe
if [ -f "$SERVERS_FILE" ]; then
    echo "📦 Sauvegarde du fichier serveurs existant..."
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/STB_UNION_servers_$(date +%Y%m%d_%H%M%S).json"
    cp "$SERVERS_FILE" "$BACKUP_FILE"
    echo "✅ Sauvegarde créée : $BACKUP_FILE"
else
    echo "ℹ️ Aucun fichier serveurs existant trouvé."
fi

# Téléchargement et extraction directe dans /tmp
echo "📥 Téléchargement du plugin STB_UNION..."
wget -q --show-progress "$TAR_URL" -O /tmp/STB_UNION_E2.tar.gz

# Extraction vers le répertoire des extensions
echo "📦 Extraction vers $PLUGIN_DIR..."
mkdir -p "$PLUGIN_DIR"
tar -xzf /tmp/STB_UNION_E2.tar.gz -C /usr/lib/enigma2/python/Plugins/Extensions/

# Ajout du fichier serveurs (seulement s'il n'existe pas ou si forcé)
if [ ! -f "$SERVERS_FILE" ]; then
    echo "➕ Ajout du fichier serveurs..."
    mkdir -p /etc/enigma2
    wget -q -O "$SERVERS_FILE" "$SERVERS_URL"
    echo "✅ Fichier serveurs installé"
else
    echo "⚠️ Le fichier serveurs existe déjà et a été sauvegardé."
    echo "   Pour installer la nouvelle version, supprimez-le d'abord :"
    echo "   rm $SERVERS_FILE"
fi

# Nettoyage
rm -f /tmp/STB_UNION_E2.tar.gz

# Vérification
if [ ! -d "$PLUGIN_DIR" ]; then
    echo "❌ Erreur : le plugin n'a pas été installé correctement."
    exit 1
fi

sync
echo "╔════════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                                ║"
echo "║     ███████╗████████╗██████╗     ██╗   ██╗███╗   ██╗██╗ ██████╗ ███╗   ██╗"
echo "║     ██╔════╝╚══██╔══╝██╔══██╗    ██║   ██║████╗  ██║██║██╔═══██╗████╗  ██║"
echo "║     ███████╗   ██║   ██████╔╝    ██║   ██║██╔██╗ ██║██║██║   ██║██╔██╗ ██║"
echo "║     ╚════██║   ██║   ██╔══██╗    ██║   ██║██║╚██╗██║██║██║   ██║██║╚██╗██║"
echo "║     ███████║   ██║   ██████╔╝    ╚██████╔╝██║ ╚████║██║╚██████╔╝██║ ╚████║"
echo "║     ╚══════╝   ╚═╝   ╚═════╝      ╚═════╝ ╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝"
echo "║                                                                                 ║"
echo "║                            SCRIPT D'INSTALLATION V1.1                           ║"
echo "║                                 INTERFACE ENIGMA2                               ║"
echo "╚═════════════════════════════════════════════════════════════════════════════════╝"
echo "#########################################################"
echo "#       STB_UNION E2 INSTALLED SUCCESSFULLY            #"
echo "#                 by ilyasM6 / electroyassine           #"
echo "#########################################################"

# Afficher les sauvegardes existantes
if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR)" ]; then
    echo "#           Sauvegardes disponibles :                 #"
    ls -1 "$BACKUP_DIR" | sed 's/^/#           - /'
    echo "#########################################################"
fi

echo "#           your Device will RESTART Now                #"
echo "#########################################################"
sleep 3
init 4 && sleep 2 && init 3
exit 0
