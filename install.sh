#!/bin/sh

# Script d'installation du plugin STB_UNION E2
# Version: 2.0
# Auteur: Script automatique

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
PLUGIN_URL="https://github.com/ilyasM6/Plugins/raw/main/STB_UNION%20E2.tar.gz"
TEMP_DIR="/tmp"
PLUGIN_NAME="STB_UNION_E2"
DISPLAY_NAME="STB_UNION E2"
PLUGIN_FILE="STB_UNION_E2.tar.gz"
INSTALL_PATH="/usr/lib/enigma2/python/Plugins/Extensions"
LOG_FILE="/tmp/stb_union_install.log"

# Fonction pour afficher les messages
print_message() {
    echo -e "${BLUE}[$(date +"%H:%M:%S")]${NC} $1"
    log_message "$1"
}

print_success() {
    echo -e "${GREEN}✓ SUCCÈS:${NC} $1"
    log_message "SUCCÈS: $1"
}

print_error() {
    echo -e "${RED}✗ ERREUR:${NC} $1"
    log_message "ERREUR: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ ATTENTION:${NC} $1"
    log_message "ATTENTION: $1"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   Installation du plugin $DISPLAY_NAME${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

# Fonction de journalisation
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$LOG_FILE"
}

# Nettoyage des fichiers temporaires
cleanup() {
    print_message "Nettoyage des fichiers temporaires..."
    
    if [ -f "$TEMP_DIR/$PLUGIN_FILE" ]; then
        rm -f "$TEMP_DIR/$PLUGIN_FILE"
        print_success "Fichier temporaire supprimé: $TEMP_DIR/$PLUGIN_FILE"
    fi
    
    if [ -d "$TEMP_DIR/plugin_extract_$$" ]; then
        rm -rf "$TEMP_DIR/plugin_extract_$$"
        print_success "Répertoire d'extraction temporaire supprimé"
    fi
}

# Vérification des droits root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        print_error "Ce script doit être exécuté avec les droits root (sudo)"
        exit 1
    fi
}

# Vérification des dépendances
check_dependencies() {
    print_message "Vérification des dépendances..."
    
    local missing_deps=""
    
    for cmd in tar gzip wget; do
        if ! command -v $cmd >/dev/null 2>&1; then
            # wget manquant, essayer curl
            if [ "$cmd" = "wget" ] && command -v curl >/dev/null 2>&1; then
                continue
            fi
            missing_deps="$missing_deps $cmd"
        fi
    done
    
    if [ -n "$missing_deps" ]; then
        print_error "Dépendances manquantes:$missing_deps"
        print_message "Installation des dépendances..."
        
        # Tentative d'installation automatique
        if command -v opkg >/dev/null 2>&1; then
            opkg update && opkg install tar gzip wget
        elif command -v apt-get >/dev/null 2>&1; then
            apt-get update && apt-get install -y tar gzip wget
        fi
        
        # Re-vérification
        for cmd in tar gzip; do
            if ! command -v $cmd >/dev/null 2>&1; then
                print_error "Impossible d'installer les dépendances"
                exit 1
            fi
        done
    fi
    
    print_success "Toutes les dépendances sont présentes"
}

# Vérification de l'espace disque
check_disk_space() {
    print_message "Vérification de l'espace disque..."
    
    # Vérifier si le répertoire parent existe
    if [ ! -d "$INSTALL_PATH" ]; then
        mkdir -p "$INSTALL_PATH" 2>/dev/null
    fi
    
    # Utiliser df avec le bon répertoire
    if [ -d "$INSTALL_PATH" ]; then
        available_space=$(df -m "$INSTALL_PATH" 2>/dev/null | awk 'NR==2 {print $4}')
    else
        # Fallback sur /usr
        available_space=$(df -m /usr 2>/dev/null | awk 'NR==2 {print $4}')
    fi
    
    if [ -z "$available_space" ] || [ "$available_space" -lt 50 ]; then
        print_error "Espace disque insuffisant ou impossible à vérifier"
        print_message "Espace disponible: ${available_space:-0}MB"
        exit 1
    fi
    
    print_success "Espace disque suffisant: ${available_space}MB disponible"
}

# Téléchargement du plugin
download_plugin() {
    print_message "Téléchargement du plugin depuis GitHub..."
    
    # Essayer différentes méthodes de téléchargement
    if command -v wget >/dev/null 2>&1; then
        print_message "Utilisation de wget..."
        wget -O "$TEMP_DIR/$PLUGIN_FILE" "$PLUGIN_URL" 2>/dev/null
        result=$?
    elif command -v curl >/dev/null 2>&1; then
        print_message "Utilisation de curl..."
        curl -L -o "$TEMP_DIR/$PLUGIN_FILE" "$PLUGIN_URL" 2>/dev/null
        result=$?
    else
        print_error "Ni wget ni curl n'est installé"
        exit 1
    fi
    
    if [ $result -eq 0 ] && [ -f "$TEMP_DIR/$PLUGIN_FILE" ]; then
        file_size=$(du -h "$TEMP_DIR/$PLUGIN_FILE" 2>/dev/null | cut -f1)
        print_success "Téléchargement réussi (taille: $file_size)"
    else
        print_error "Échec du téléchargement (code: $result)"
        cleanup
        exit 1
    fi
}

# Vérification de l'intégrité du fichier
check_file_integrity() {
    print_message "Vérification de l'intégrité du fichier..."
    
    if [ ! -f "$TEMP_DIR/$PLUGIN_FILE" ]; then
        print_error "Fichier non trouvé: $TEMP_DIR/$PLUGIN_FILE"
        exit 1
    fi
    
    # Vérifier la taille du fichier (ne doit pas être trop petit)
    file_size_bytes=$(stat -c%s "$TEMP_DIR/$PLUGIN_FILE" 2>/dev/null || stat -f%z "$TEMP_DIR/$PLUGIN_FILE" 2>/dev/null)
    if [ "$file_size_bytes" -lt 10000 ]; then
        print_error "Fichier trop petit (${file_size_bytes} bytes) - Téléchargement corrompu"
        cleanup
        exit 1
    fi
    
    # Vérifier si c'est un fichier tar.gz valide
    if gunzip -t "$TEMP_DIR/$PLUGIN_FILE" 2>/dev/null; then
        print_success "Fichier archive valide"
    else
        print_error "Fichier archive corrompu ou invalide"
        cleanup
        exit 1
    fi
}

# Sauvegarde de l'ancienne version si elle existe
backup_old_version() {
    if [ -d "$INSTALL_PATH/$PLUGIN_NAME" ]; then
        print_warning "Une version existante du plugin a été trouvée"
        backup_path="$INSTALL_PATH/${PLUGIN_NAME}_backup_$(date +%Y%m%d_%H%M%S)"
        print_message "Création d'une sauvegarde dans: $backup_path"
        
        mv "$INSTALL_PATH/$PLUGIN_NAME" "$backup_path"
        if [ $? -eq 0 ]; then
            print_success "Sauvegarde créée avec succès"
        else
            print_error "Échec de la création de la sauvegarde"
            exit 1
        fi
    fi
}

# Création du répertoire d'installation
create_install_dir() {
    print_message "Préparation du répertoire d'installation..."
    
    if [ ! -d "$INSTALL_PATH" ]; then
        mkdir -p "$INSTALL_PATH"
        print_message "Répertoire créé: $INSTALL_PATH"
    fi
    
    # Vérification des permissions
    chmod 755 "$INSTALL_PATH" 2>/dev/null
    print_success "Répertoire d'installation prêt"
}

# Décompression du plugin
extract_plugin() {
    print_message "Décompression du plugin..."
    
    temp_extract="$TEMP_DIR/plugin_extract_$$"
    mkdir -p "$temp_extract"
    
    tar -xzf "$TEMP_DIR/$PLUGIN_FILE" -C "$temp_extract" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "Décompression réussie"
        
        # Recherche plus robuste du dossier du plugin
        extracted_dir=""
        
        # Chercher un dossier avec STB_UNION dans le nom
        extracted_dir=$(find "$temp_extract" -type d \( -name "*STB_UNION*" -o -name "*stb_union*" -o -name "*STB*UNION*" \) | head -1)
        
        # Si non trouvé, chercher un dossier contenant plugin.py
        if [ -z "$extracted_dir" ]; then
            plugin_file=$(find "$temp_extract" -type f -name "plugin.py" | head -1)
            if [ -n "$plugin_file" ]; then
                extracted_dir=$(dirname "$plugin_file")
            fi
        fi
        
        # Si non trouvé, chercher un dossier contenant __init__.py
        if [ -z "$extracted_dir" ]; then
            init_file=$(find "$temp_extract" -type f -name "__init__.py" | head -1)
            if [ -n "$init_file" ]; then
                extracted_dir=$(dirname "$init_file")
            fi
        fi
        
        # Dernier recours : prendre le premier dossier
        if [ -z "$extracted_dir" ]; then
            extracted_dir=$(find "$temp_extract" -mindepth 1 -maxdepth 1 -type d | head -1)
        fi
        
        if [ -n "$extracted_dir" ] && [ -d "$extracted_dir" ]; then
            print_message "Déplacement du plugin vers $INSTALL_PATH/$PLUGIN_NAME"
            
            # Supprimer l'ancien dossier s'il existe
            rm -rf "$INSTALL_PATH/$PLUGIN_NAME" 2>/dev/null
            
            # Copier le nouveau plugin
            cp -r "$extracted_dir" "$INSTALL_PATH/$PLUGIN_NAME"
            
            if [ $? -eq 0 ]; then
                print_success "Plugin déplacé avec succès"
            else
                print_error "Échec du déplacement du plugin"
                exit 1
            fi
        else
            print_error "Impossible de trouver le dossier du plugin dans l'archive"
            ls -la "$temp_extract"
            exit 1
        fi
        
        # Nettoyage du répertoire temporaire d'extraction
        rm -rf "$temp_extract"
    else
        print_error "Échec de la décompression"
        exit 1
    fi
}

# Définition des permissions
set_permissions() {
    print_message "Configuration des permissions..."
    
    if [ -d "$INSTALL_PATH/$PLUGIN_NAME" ]; then
        # Permissions pour les dossiers
        find "$INSTALL_PATH/$PLUGIN_NAME" -type d -exec chmod 755 {} \; 2>/dev/null
        # Permissions pour les fichiers
        find "$INSTALL_PATH/$PLUGIN_NAME" -type f -exec chmod 644 {} \; 2>/dev/null
        # Permissions pour les fichiers exécutables
        find "$INSTALL_PATH/$PLUGIN_NAME" -name "*.sh" -exec chmod 755 {} \; 2>/dev/null
        find "$INSTALL_PATH/$PLUGIN_NAME" -name "*.py" -exec chmod 644 {} \; 2>/dev/null
        find "$INSTALL_PATH/$PLUGIN_NAME" -name "*.so" -exec chmod 755 {} \; 2>/dev/null
        find "$INSTALL_PATH/$PLUGIN_NAME" -name "*.ipk" -exec chmod 755 {} \; 2>/dev/null
        find "$INSTALL_PATH/$PLUGIN_NAME" -name "*.sh" -exec chmod 755 {} \; 2>/dev/null
        
        # Permission spéciale pour le dossier principal
        chmod 755 "$INSTALL_PATH/$PLUGIN_NAME" 2>/dev/null
        
        print_success "Permissions configurées avec succès"
    else
        print_error "Dossier du plugin non trouvé"
        exit 1
    fi
}

# Vérification de l'installation
verify_installation() {
    print_message "Vérification de l'installation..."
    
    if [ -d "$INSTALL_PATH/$PLUGIN_NAME" ]; then
        # Compter les fichiers installés
        file_count=$(find "$INSTALL_PATH/$PLUGIN_NAME" -type f | wc -l)
        
        # Vérifier si le plugin contient des fichiers essentiels
        if [ -f "$INSTALL_PATH/$PLUGIN_NAME/plugin.py" ] || [ -f "$INSTALL_PATH/$PLUGIN_NAME/__init__.py" ]; then
            print_success "Plugin installé correctement avec les fichiers essentiels"
        else
            print_warning "Plugin installé mais fichiers essentiels manquants"
            print_message "Fichiers trouvés: $file_count"
        fi
        
        # Afficher le contenu du dossier
        plugin_size=$(du -sh "$INSTALL_PATH/$PLUGIN_NAME" 2>/dev/null | cut -f1)
        print_message "Taille du plugin: $plugin_size"
        print_message "Nombre de fichiers: $file_count"
        
        return 0
    else
        print_error "Le plugin n'a pas été installé correctement"
        return 1
    fi
}

# Restart enigma2 GUI
restart_enigma2() {
    print_message "Redémarrage de l'interface Enigma2..."
    
    # Différentes méthodes de redémarrage
    if [ -f /etc/init.d/enigma2 ]; then
        print_message "Utilisation de /etc/init.d/enigma2 restart..."
        /etc/init.d/enigma2 restart
        result=$?
    elif command -v init >/dev/null 2>&1; then
        print_message "Utilisation de init 4 && init 3..."
        init 4 && sleep 2 && init 3
        result=$?
    elif command -v systemctl >/dev/null 2>&1; then
        print_message "Utilisation de systemctl..."
        systemctl restart enigma2 2>/dev/null || systemctl restart enigma2.service 2>/dev/null
        result=$?
    else
        print_warning "Redémarrage automatique impossible"
        echo -e "${YELLOW}Veuillez redémarrer Enigma2 manuellement depuis le menu${NC}"
        return 1
    fi
    
    if [ $result -eq 0 ]; then
        print_success "Enigma2 redémarré avec succès"
        return 0
    else
        print_warning "Redémarrage manuel nécessaire"
        return 1
    fi
}

# Affichage du résumé final
show_summary() {
    print_header
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         INSTALLATION TERMINÉE AVEC SUCCÈS !            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}Détails de l'installation:${NC}"
    echo -e "  • Plugin: $DISPLAY_NAME"
    echo -e "  • Emplacement: $INSTALL_PATH/$PLUGIN_NAME"
    echo -e "  • Date: $(date +"%d/%m/%Y à %H:%M:%S")"
    echo -e "  • Log: $LOG_FILE"
    
    # Afficher le contenu principal
    if [ -d "$INSTALL_PATH/$PLUGIN_NAME" ]; then
        echo -e "\n${YELLOW}Contenu du plugin:${NC}"
        ls -la "$INSTALL_PATH/$PLUGIN_NAME" | head -10
    fi
}

# Fonction principale
main() {
    print_header
    
    # Initialisation du log
    echo "=== Installation du plugin $DISPLAY_NAME ===" > "$LOG_FILE"
    log_message "Début de l'installation"
    
    # Vérifications préalables
    check_root
    check_dependencies
    check_disk_space
    
    # Installation
    download_plugin
    check_file_integrity
    backup_old_version
    create_install_dir
    extract_plugin
    set_permissions
    
    # Vérification finale
    if verify_installation; then
        show_summary
        
        # Nettoyage
        cleanup
        
        # Redémarrage d'Enigma2
        echo -e "\n${YELLOW}Redémarrage de l'interface Enigma2...${NC}"
        sleep 2
        restart_enigma2
        
        echo -e "\n${GREEN}✓ Installation complète et réussie !${NC}\n"
        log_message "Installation terminée avec succès"
        exit 0
    else
        print_error "L'installation a échoué"
        log_message "Échec de l'installation"
        echo -e "\n${YELLOW}Consultez le log pour plus de détails: $LOG_FILE${NC}"
        cleanup
        exit 1
    fi
}

# Exécution du script avec gestion des erreurs
trap 'print_error "Script interrompu par l'utilisateur"; cleanup; log_message "Script interrompu"; exit 1' INT TERM
trap 'print_error "Erreur à la ligne $LINENO"; cleanup; log_message "Erreur à la ligne $LINENO"; exit 1' ERR

# Lancer l'installation
main "$@"
