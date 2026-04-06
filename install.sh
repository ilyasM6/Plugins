#!/bin/sh

# =============================================================================
# Script d'installation du plugin STB_UNION E2 - Version Premium
# =============================================================================
# Lien: https://github.com/ilyasM6/Plugins/raw/main/STB_UNION%20E2.tar.gz
# Compatibilité: Enigma2 (DreamOS, OpenATV, OpenPLi, OpenVision, etc.)
# =============================================================================

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Variables de configuration
PLUGIN_URL="https://github.com/ilyasM6/Plugins/raw/main/STB_UNION%20E2.tar.gz"
PLUGIN_URL_MIRROR="https://raw.githubusercontent.com/ilyasM6/Plugins/main/STB_UNION%20E2.tar.gz"
TEMP_DIR="/tmp"
PLUGIN_NAME="STB_UNION_E2"
DISPLAY_NAME="STB_UNION E2"
PLUGIN_FILE="STB_UNION_E2.tar.gz"
INSTALL_PATH="/usr/lib/enigma2/python/Plugins/Extensions"
LOG_FILE="/tmp/stb_union_install.log"
CONFIG_FILE="/etc/enigma2/stb_union.conf"
BACKUP_DIR="/etc/enigma2/backups"

# Options
AUTO_RESTART=true
CREATE_BACKUP=true
VERBOSE=false
FORCE_INSTALL=false

# Variables d'état
INSTALL_SUCCESS=false
BACKUP_CREATED=false
RESTART_NEEDED=false

# =============================================================================
# FONCTIONS D'UTILITAIRES
# =============================================================================

# Afficher l'aide
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}
${CYAN}║           STB_UNION E2 - Script d'installation v3.0                ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}

${WHITE}Utilisation:${NC} $0 [OPTIONS]

${WHITE}Options:${NC}
  ${GREEN}-h, --help${NC}           Afficher cette aide
  ${GREEN}-v, --verbose${NC}        Mode verbeux (affiche toutes les sorties)
  ${GREEN}-f, --force${NC}          Forcer l'installation même si version existante
  ${GREEN}-n, --no-restart${NC}     Ne pas redémarrer Enigma2 après installation
  ${GREEN}-b, --no-backup${NC}      Ne pas créer de sauvegarde
  ${GREEN}-d, --debug${NC}          Mode debug (sorties détaillées)
  ${GREEN}-c, --clean${NC}          Nettoyage complet avant installation
  ${GREEN}-l, --list${NC}           Lister les versions installées
  ${GREEN}-r, --remove${NC}         Désinstaller le plugin

${WHITE}Exemples:${NC}
  $0                           # Installation standard
  $0 -v -f                     # Installation forcée en mode verbeux
  $0 --no-restart --no-backup  # Installation rapide sans backup ni restart
  $0 --remove                  # Désinstallation complète
  $0 --list                    # Lister les versions

EOF
}

# Journalisation
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    if [ "$VERBOSE" = true ] || [ "$level" = "ERROR" ] || [ "$level" = "SUCCESS" ]; then
        case "$level" in
            "INFO")    echo -e "${BLUE}[INFO]${NC} $message" ;;
            "SUCCESS") echo -e "${GREEN}[SUCCÈS]${NC} $message" ;;
            "WARNING") echo -e "${YELLOW}[ATTENTION]${NC} $message" ;;
            "ERROR")   echo -e "${RED}[ERREUR]${NC} $message" ;;
            "DEBUG")   echo -e "${MAGENTA}[DEBUG]${NC} $message" ;;
            *)         echo -e "$message" ;;
        esac
    fi
}

# Détection du système
detect_system() {
    log "INFO" "Détection du système..."
    
    # Détection de l'architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        "armv7l")  SYSTEM_ARCH="ARMv7" ;;
        "aarch64") SYSTEM_ARCH="ARM64" ;;
        "mips")    SYSTEM_ARCH="MIPS" ;;
        "sh4")     SYSTEM_ARCH="SH4" ;;
        "x86_64")  SYSTEM_ARCH="x86_64" ;;
        *)         SYSTEM_ARCH="Inconnue" ;;
    esac
    
    # Détection de l'image Enigma2
    if [ -f /etc/image-version ]; then
        IMAGE_NAME=$(grep "distro" /etc/image-version | cut -d'=' -f2 | tr -d '"')
        IMAGE_VERSION=$(grep "version" /etc/image-version | cut -d'=' -f2 | tr -d '"')
    elif [ -f /etc/issue ]; then
        IMAGE_NAME=$(head -1 /etc/issue | cut -d' ' -f1)
        IMAGE_VERSION="Inconnue"
    else
        IMAGE_NAME="Inconnue"
        IMAGE_VERSION="Inconnue"
    fi
    
    # Détection de la version Python
    PYTHON_VERSION=$(python -V 2>&1 | cut -d' ' -f2 | cut -d'.' -f1-2)
    
    log "SUCCESS" "Système détecté: $IMAGE_NAME $IMAGE_VERSION"
    log "INFO" "Architecture: $SYSTEM_ARCH, Python: $PYTHON_VERSION"
}

# Vérification des droits root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}✗ Ce script doit être exécuté avec les droits root${NC}"
        echo -e "  Utilisez: ${CYAN}sudo $0${NC}"
        return 1
    fi
    return 0
}

# Vérification des dépendances
check_dependencies() {
    log "INFO" "Vérification des dépendances..."
    
    local missing=""
    
    for cmd in tar gzip wget curl; do
        if ! command -v $cmd >/dev/null 2>&1; then
            missing="$missing $cmd"
        fi
    done
    
    if [ -n "$missing" ]; then
        log "WARNING" "Dépendances manquantes:$missing"
        
        # Tentative d'installation
        if command -v opkg >/dev/null 2>&1; then
            opkg update && opkg install $missing
        elif command -v apt-get >/dev/null 2>&1; then
            apt-get update && apt-get install -y $missing
        fi
        
        # Re-vérification
        for cmd in tar gzip; do
            if ! command -v $cmd >/dev/null 2>&1; then
                log "ERROR" "Dépendance essentielle manquante: $cmd"
                return 1
            fi
        done
    fi
    
    log "SUCCESS" "Dépendances OK"
    return 0
}

# Vérification de l'espace disque
check_disk_space() {
    local required_mb=50
    local install_path="$INSTALL_PATH"
    
    log "INFO" "Vérification de l'espace disque (minimum ${required_mb}MB)..."
    
    # Trouver le point de montage
    while [ ! -d "$install_path" ] && [ "$install_path" != "/" ]; do
        install_path=$(dirname "$install_path")
    done
    
    available_space=$(df -m "$install_path" 2>/dev/null | awk 'NR==2 {print $4}')
    
    if [ -z "$available_space" ]; then
        log "ERROR" "Impossible de vérifier l'espace disque"
        return 1
    fi
    
    if [ "$available_space" -lt "$required_mb" ]; then
        log "ERROR" "Espace insuffisant: ${available_space}MB disponible, ${required_mb}MB requis"
        return 1
    fi
    
    log "SUCCESS" "Espace disque OK: ${available_space}MB disponible"
    return 0
}

# Vérification de la connexion internet
check_internet() {
    log "INFO" "Vérification de la connexion internet..."
    
    if ping -c 1 -W 2 "github.com" >/dev/null 2>&1; then
        log "SUCCESS" "Connexion internet OK"
        return 0
    else
        log "ERROR" "Pas de connexion internet détectée"
        return 1
    fi
}

# Téléchargement du plugin
download_plugin() {
    log "INFO" "Téléchargement du plugin depuis GitHub..."
    
    if command -v wget >/dev/null 2>&1; then
        log "INFO" "Utilisation de wget..."
        wget --timeout=30 --show-progress -O "$TEMP_DIR/$PLUGIN_FILE" "$PLUGIN_URL"
        result=$?
    elif command -v curl >/dev/null 2>&1; then
        log "INFO" "Utilisation de curl..."
        curl -L --progress-bar -o "$TEMP_DIR/$PLUGIN_FILE" "$PLUGIN_URL"
        result=$?
    else
        log "ERROR" "wget ou curl non installé"
        return 1
    fi
    
    if [ $result -eq 0 ] && [ -f "$TEMP_DIR/$PLUGIN_FILE" ] && [ -s "$TEMP_DIR/$PLUGIN_FILE" ]; then
        file_size=$(du -h "$TEMP_DIR/$PLUGIN_FILE" | cut -f1)
        log "SUCCESS" "Téléchargement réussi (taille: $file_size)"
        return 0
    else
        log "ERROR" "Échec du téléchargement"
        return 1
    fi
}

# Sauvegarde de l'ancienne version
backup_plugin() {
    local plugin_path="$INSTALL_PATH/$PLUGIN_NAME"
    
    if [ ! -d "$plugin_path" ]; then
        log "INFO" "Aucune version existante à sauvegarder"
        return 0
    fi
    
    if [ "$CREATE_BACKUP" = false ]; then
        log "WARNING" "Sauvegarde désactivée par l'utilisateur"
        rm -rf "$plugin_path"
        return 0
    fi
    
    log "INFO" "Création d'une sauvegarde de l'ancienne version..."
    
    mkdir -p "$BACKUP_DIR"
    local backup_name="${PLUGIN_NAME}_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if tar -czf "$backup_path" -C "$INSTALL_PATH" "$PLUGIN_NAME" 2>/dev/null; then
        backup_size=$(du -h "$backup_path" | cut -f1)
        log "SUCCESS" "Sauvegarde créée: $backup_path ($backup_size)"
        BACKUP_CREATED=true
        
        # Garder seulement les 5 dernières sauvegardes
        cd "$BACKUP_DIR" && ls -t ${PLUGIN_NAME}_backup_*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm
    else
        log "WARNING" "Impossible de créer la sauvegarde"
    fi
    
    # Supprimer l'ancienne version
    rm -rf "$plugin_path"
    return 0
}

# Installation du plugin
install_plugin() {
    log "INFO" "Installation du plugin $DISPLAY_NAME..."
    
    # Créer le répertoire d'installation
    mkdir -p "$INSTALL_PATH"
    
    # Extraire dans un répertoire temporaire
    local temp_extract="$TEMP_DIR/plugin_extract_$$"
    mkdir -p "$temp_extract"
    
    log "INFO" "Extraction de l'archive..."
    
    if ! tar -xzf "$TEMP_DIR/$PLUGIN_FILE" -C "$temp_extract" 2>/dev/null; then
        log "ERROR" "Échec de l'extraction"
        rm -rf "$temp_extract"
        return 1
    fi
    
    # Trouver le dossier du plugin
    local plugin_source=""
    
    # Recherche intelligente
    plugin_source=$(find "$temp_extract" -type d -iname "*stb*union*" | head -1)
    
    if [ -z "$plugin_source" ]; then
        plugin_source=$(find "$temp_extract" -type f -name "plugin.py" -o -name "__init__.py" | head -1 | xargs dirname 2>/dev/null)
    fi
    
    if [ -z "$plugin_source" ]; then
        plugin_source=$(find "$temp_extract" -mindepth 1 -maxdepth 2 -type d | head -1)
    fi
    
    if [ -z "$plugin_source" ] || [ ! -d "$plugin_source" ]; then
        log "ERROR" "Impossible de localiser le plugin dans l'archive"
        ls -la "$temp_extract"
        rm -rf "$temp_extract"
        return 1
    fi
    
    log "INFO" "Plugin trouvé: $plugin_source"
    
    # Copier le plugin
    cp -r "$plugin_source" "$INSTALL_PATH/$PLUGIN_NAME"
    
    if [ $? -ne 0 ]; then
        log "ERROR" "Échec de la copie du plugin"
        rm -rf "$temp_extract"
        return 1
    fi
    
    # Nettoyage
    rm -rf "$temp_extract"
    
    log "SUCCESS" "Plugin copié vers: $INSTALL_PATH/$PLUGIN_NAME"
    return 0
}

# Configuration des permissions
set_permissions() {
    local plugin_path="$INSTALL_PATH/$PLUGIN_NAME"
    
    if [ ! -d "$plugin_path" ]; then
        log "ERROR" "Dossier du plugin non trouvé"
        return 1
    fi
    
    log "INFO" "Configuration des permissions..."
    
    # Permissions standard
    find "$plugin_path" -type d -exec chmod 755 {} \; 2>/dev/null
    find "$plugin_path" -type f -exec chmod 644 {} \; 2>/dev/null
    find "$plugin_path" -name "*.sh" -exec chmod 755 {} \; 2>/dev/null
    find "$plugin_path" -name "*.so" -exec chmod 755 {} \; 2>/dev/null
    find "$plugin_path" -name "*.py" -exec chmod 644 {} \; 2>/dev/null
    
    # Plugin principal
    chmod 755 "$plugin_path" 2>/dev/null
    
    log "SUCCESS" "Permissions configurées"
    return 0
}

# Vérification post-installation
verify_installation() {
    local plugin_path="$INSTALL_PATH/$PLUGIN_NAME"
    
    log "INFO" "Vérification de l'installation..."
    
    if [ ! -d "$plugin_path" ]; then
        log "ERROR" "Plugin non trouvé dans $INSTALL_PATH"
        return 1
    fi
    
    # Statistiques
    local file_count=$(find "$plugin_path" -type f | wc -l)
    local dir_count=$(find "$plugin_path" -type d | wc -l)
    local plugin_size=$(du -sh "$plugin_path" 2>/dev/null | cut -f1)
    
    log "SUCCESS" "Plugin installé: $file_count fichiers, $dir_count dossiers"
    log "INFO" "Taille: $plugin_size"
    
    # Vérification des fichiers critiques
    if [ -f "$plugin_path/plugin.py" ] || [ -f "$plugin_path/__init__.py" ]; then
        log "SUCCESS" "Fichiers Python critiques présents"
    else
        log "WARNING" "Fichiers Python critiques manquants"
    fi
    
    return 0
}

# Redémarrage d'Enigma2
restart_enigma2() {
    if [ "$AUTO_RESTART" = false ]; then
        log "INFO" "Redémarrage automatique désactivé"
        echo -e "${YELLOW}⚠ Redémarrage manuel nécessaire:${NC}"
        echo -e "  • Via commande: ${CYAN}init 4 && init 3${NC}"
        return 0
    fi
    
    log "INFO" "Redémarrage de l'interface Enigma2..."
    
    if [ -f /etc/init.d/enigma2 ]; then
        /etc/init.d/enigma2 restart 2>/dev/null
    elif command -v systemctl >/dev/null 2>&1; then
        systemctl restart enigma2 2>/dev/null
    elif command -v init >/dev/null 2>&1; then
        log "INFO" "Redémarrage avec init..."
        init 4
        sleep 3
        init 3
    else
        log "WARNING" "Redémarrage automatique impossible"
        return 1
    fi
    
    log "SUCCESS" "Enigma2 redémarré avec succès"
    RESTART_NEEDED=false
    return 0
}

# Nettoyage complet
full_cleanup() {
    log "INFO" "Nettoyage complet des fichiers temporaires..."
    
    rm -f "$TEMP_DIR/$PLUGIN_FILE" 2>/dev/null
    rm -rf "$TEMP_DIR/plugin_extract_"* 2>/dev/null
    find "$INSTALL_PATH" -name "*.pyc" -delete 2>/dev/null
    
    log "SUCCESS" "Nettoyage terminé"
}

# Désinstallation du plugin
uninstall_plugin() {
    log "INFO" "Désinstallation de $DISPLAY_NAME..."
    
    local plugin_path="$INSTALL_PATH/$PLUGIN_NAME"
    
    if [ ! -d "$plugin_path" ]; then
        log "ERROR" "Plugin non trouvé: $plugin_path"
        return 1
    fi
    
    # Créer une sauvegarde avant désinstallation
    if [ "$CREATE_BACKUP" = true ]; then
        backup_plugin
    else
        rm -rf "$plugin_path"
    fi
    
    if [ $? -eq 0 ]; then
        log "SUCCESS" "Plugin désinstallé avec succès"
        
        # Nettoyer les caches
        find "$INSTALL_PATH" -name "*.pyc" -delete 2>/dev/null
        
        # Redémarrer si demandé
        if [ "$AUTO_RESTART" = true ]; then
            restart_enigma2
        fi
        
        return 0
    else
        log "ERROR" "Échec de la désinstallation"
        return 1
    fi
}

# Lister les versions
list_versions() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   Versions installées de $DISPLAY_NAME${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    # Version actuelle
    if [ -d "$INSTALL_PATH/$PLUGIN_NAME" ]; then
        echo -e "${GREEN}✓ Version actuelle:${NC}"
        echo -e "  • Emplacement: $INSTALL_PATH/$PLUGIN_NAME"
        echo -e "  • Taille: $(du -sh "$INSTALL_PATH/$PLUGIN_NAME" | cut -f1)"
        echo -e "  • Fichiers: $(find "$INSTALL_PATH/$PLUGIN_NAME" -type f | wc -l)"
        
        # Date de modification
        last_mod=$(stat -c %y "$INSTALL_PATH/$PLUGIN_NAME" 2>/dev/null | cut -d'.' -f1)
        echo -e "  • Dernière modification: $last_mod"
    else
        echo -e "${YELLOW}⚠ Aucune version installée${NC}"
    fi
    
    # Sauvegardes disponibles
    if [ -d "$BACKUP_DIR" ]; then
        backups=$(ls -t "$BACKUP_DIR"/${PLUGIN_NAME}_backup_*.tar.gz 2>/dev/null)
        if [ -n "$backups" ]; then
            echo -e "\n${CYAN}📦 Sauvegardes disponibles:${NC}"
            echo "$backups" | while read backup; do
                backup_name=$(basename "$backup")
                backup_size=$(du -h "$backup" | cut -f1)
                echo -e "  • $backup_name ($backup_size)"
            done
        fi
    fi
    
    echo ""
}

# Afficher le rapport final
show_report() {
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    RAPPORT D'INSTALLATION                           ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${CYAN}📋 INFORMATIONS SYSTÈME:${NC}"
    echo -e "  • Image: $IMAGE_NAME $IMAGE_VERSION"
    echo -e "  • Architecture: $SYSTEM_ARCH"
    echo -e "  • Python: $PYTHON_VERSION"
    echo -e "  • Date: $(date +"%d/%m/%Y à %H:%M:%S")"
    
    echo -e "\n${CYAN}📦 DÉTAILS DU PLUGIN:${NC}"
    echo -e "  • Nom: $DISPLAY_NAME"
    echo -e "  • Emplacement: $INSTALL_PATH/$PLUGIN_NAME"
    echo -e "  • Taille: $(du -sh "$INSTALL_PATH/$PLUGIN_NAME" 2>/dev/null | cut -f1)"
    echo -e "  • Fichiers: $(find "$INSTALL_PATH/$PLUGIN_NAME" -type f 2>/dev/null | wc -l)"
    
    if [ "$BACKUP_CREATED" = true ]; then
        echo -e "\n${GREEN}✓ Sauvegarde créée dans: $BACKUP_DIR${NC}"
    fi
    
    if [ "$RESTART_NEEDED" = true ]; then
        echo -e "\n${YELLOW}⚠ Redémarrage nécessaire:${NC}"
        echo -e "  Exécutez: ${CYAN}init 4 && init 3${NC}"
    else
        echo -e "\n${GREEN}✓ Enigma2 redémarré automatiquement${NC}"
    fi
    
    echo -e "\n${CYAN}📝 LOG:${NC} $LOG_FILE"
    echo -e "\n${GREEN}════════════════════════════════════════════════════════════════════${NC}\n"
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

main() {
    # Traitement des arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE_INSTALL=true
                shift
                ;;
            -n|--no-restart)
                AUTO_RESTART=false
                shift
                ;;
            -b|--no-backup)
                CREATE_BACKUP=false
                shift
                ;;
            -d|--debug)
                VERBOSE=true
                set -x
                shift
                ;;
            -c|--clean)
                detect_system
                full_cleanup
                exit 0
                ;;
            -l|--list)
                detect_system
                list_versions
                exit 0
                ;;
            -r|--remove)
                detect_system
                uninstall_plugin
                exit $?
                ;;
            *)
                echo -e "${RED}Option inconnue: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Initialisation
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     STB_UNION E2 - Script d'installation Premium v3.0                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    # Détection du système
    detect_system
    
    # Vérifications préalables
    check_root || exit 1
    check_internet || exit 1
    check_disk_space || exit 1
    check_dependencies || exit 1
    
    # Vérification de la version existante
    if [ -d "$INSTALL_PATH/$PLUGIN_NAME" ] && [ "$FORCE_INSTALL" = false ]; then
        echo -e "${YELLOW}⚠ Une version existe déjà. Options:${NC}"
        echo -e "  • Forcer l'installation: ${CYAN}$0 -f${NC}"
        echo -e "  • Désinstaller d'abord: ${CYAN}$0 --remove${NC}"
        echo -e "  • Voir les versions: ${CYAN}$0 --list${NC}"
        exit 1
    fi
    
    # Installation
    echo -e "\n${CYAN}▶ Début de l'installation...${NC}\n"
    
    download_plugin || exit 1
    backup_plugin
    install_plugin || exit 1
    set_permissions || exit 1
    
    # Vérification finale
    if verify_installation; then
        INSTALL_SUCCESS=true
        show_report
        
        # Nettoyage
        rm -f "$TEMP_DIR/$PLUGIN_FILE"
        
        # Redémarrage
        if ! restart_enigma2; then
            RESTART_NEEDED=true
        fi
        
        log "SUCCESS" "Installation terminée avec succès"
        exit 0
    else
        log "ERROR" "Échec de l'installation"
        echo -e "\n${RED}✗ L'installation a échoué. Consultez le log: $LOG_FILE${NC}"
        exit 1
    fi
}

# Lancer le script
main "$@"
