#!/bin/bash

# ==================== CONFIGURATION DES COULEURS ====================
declare -A COLORS=(
    [BLUE]='\033[0;34m'
    [BOLD]='\033[1m'
    [RESET]='\033[0m'
    [RED]='\033[0;31m'
    [GREEN]='\033[0;32m'
    [YELLOW]='\033[1;33m'
)

# ==================== FONCTIONS D'AFFICHAGE ====================
print_banner() {
    clear
    echo -e "${COLORS[BLUE]}${COLORS[BOLD]}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                      ║"
    echo "║     ███████╗████████╗██████╗     ██╗   ██╗███╗   ██╗██╗ ██████╗ ███╗   ██╗"
    echo "║     ██╔════╝╚══██╔══╝██╔══██╗    ██║   ██║████╗  ██║██║██╔═══██╗████╗  ██║"
    echo "║     ███████╗   ██║   ██████╔╝    ██║   ██║██╔██╗ ██║██║██║   ██║██╔██╗ ██║"
    echo "║     ╚════██║   ██║   ██╔══██╗    ██║   ██║██║╚██╗██║██║██║   ██║██║╚██╗██║"
    echo "║     ███████║   ██║   ██████╔╝    ╚██████╔╝██║ ╚████║██║╚██████╔╝██║ ╚████║"
    echo "║     ╚══════╝   ╚═╝   ╚═════╝      ╚═════╝ ╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝"
    echo "║                                                                      ║"
    echo "║                    SCRIPT D'INSTALLATION V2.0                        ║"
    echo "║                     INTERFACE ENIGMA2                                ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${COLORS[RESET]}"
}

# Fonction pour afficher les messages
print_message() {
    echo -e "${COLORS[BLUE]}[$(date +"%H:%M:%S")]${COLORS[RESET]} $1"
}

print_success() {
    echo -e "${COLORS[GREEN]}✓ SUCCÈS:${COLORS[RESET]} $1"
}

print_error() {
    echo -e "${COLORS[RED]}✗ ERREUR:${COLORS[RESET]} $1"
}

print_warning() {
    echo -e "${COLORS[YELLOW]}⚠ ATTENTION:${COLORS[RESET]} $1"
}

print_header() {
    echo -e "\n${COLORS[BLUE]}═══════════════════════════════════════════════════════════${COLORS[RESET]}"
    echo -e "${COLORS[GREEN]}   Installation du plugin $PLUGIN_NAME${COLORS[RESET]}"
    echo -e "${COLORS[BLUE]}═══════════════════════════════════════════════════════════${COLORS[RESET]}\n"
}

# ==================== VARIABLES ====================
PLUGIN_URL="https://github.com/ilyasM6/Plugins/raw/main/STB_UNION%20E2.tar.gz"
TEMP_DIR="/tmp"
PLUGIN_NAME="STB_UNION E2"
PLUGIN_FILE="STB_UNION_E2.tar.gz"
INSTALL_PATH="/usr/lib/enigma2/python/Plugins/Extensions"

# ==================== FONCTIONS D'INSTALLATION ====================
# Vérification des droits root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        print_error "Ce script doit être exécuté avec les droits root (sudo)"
        exit 1
    fi
}

# Nettoyage des fichiers temporaires
cleanup() {
    print_message "Nettoyage des fichiers temporaires..."
    if [ -f "$TEMP_DIR/$PLUGIN_FILE" ]; then
        rm -f "$TEMP_DIR/$PLUGIN_FILE"
        print_success "Fichier temporaire supprimé"
    fi
}

# Vérification de l'espace disque
check_disk_space() {
    print_message "Vérification de l'espace disque..."
    if [ -d "$INSTALL_PATH" ]; then
        available_space=$(df -m "$INSTALL_PATH" | awk 'NR==2 {print $4}')
        if [ "$available_space" -lt 50 ]; then
            print_error "Espace disque insuffisant (moins de 50MB disponible)"
            exit 1
        fi
        print_success "Espace disque suffisant: ${available_space}MB disponible"
    else
        print_warning "Le répertoire d'installation n'existe pas encore"
    fi
}

# Téléchargement du plugin
download_plugin() {
    print_message "Téléchargement du plugin depuis GitHub..."
    
    # Essayer différentes méthodes de téléchargement
    if command -v wget >/dev/null 2>&1; then
        print_message "Utilisation de wget..."
        wget -O "$TEMP_DIR/$PLUGIN_FILE" "$PLUGIN_URL" 2>/dev/null
    elif command -v curl >/dev/null 2>&1; then
        print_message "Utilisation de curl..."
        curl -L -o "$TEMP_DIR/$PLUGIN_FILE" "$PLUGIN_URL" 2>/dev/null
    else
        print_error "Ni wget ni curl n'est installé"
        exit 1
    fi
    
    if [ $? -eq 0 ] && [ -f "$TEMP_DIR/$PLUGIN_FILE" ]; then
        file_size=$(du -h "$TEMP_DIR/$PLUGIN_FILE" | cut -f1)
        print_success "Téléchargement réussi (taille: $file_size)"
    else
        print_error "Échec du téléchargement"
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
    
    # Vérifier si c'est un fichier tar.gz valide
    if tar -tzf "$TEMP_DIR/$PLUGIN_FILE" >/dev/null 2>&1; then
        print_success "Fichier archive valide"
    else
        print_error "Fichier archive corrompu ou invalide"
        cleanup
        exit 1
    fi
}

# Sauvegarde de l'ancienne version si elle existe
backup_old_version() {
    local plugin_dir="$INSTALL_PATH/$PLUGIN_NAME"
    if [ -d "$plugin_dir" ]; then
        print_warning "Une version existante du plugin a été trouvée"
        backup_path="$INSTALL_PATH/${PLUGIN_NAME}_backup_$(date +%Y%m%d_%H%M%S)"
        print_message "Création d'une sauvegarde dans: $backup_path"
        
        mv "$plugin_dir" "$backup_path"
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
    chmod 755 "$INSTALL_PATH"
    print_success "Répertoire d'installation prêt"
}

# Décompression du plugin
extract_plugin() {
    print_message "Décompression du plugin..."
    
    # Extraire dans le répertoire temporaire d'abord
    temp_extract="$TEMP_DIR/plugin_extract"
    mkdir -p "$temp_extract"
    
    tar -xzf "$TEMP_DIR/$PLUGIN_FILE" -C "$temp_extract"
    
    if [ $? -eq 0 ]; then
        print_success "Décompression réussie"
        
        # Chercher le dossier du plugin
        extracted_dir=$(find "$temp_extract" -type d -name "*STB_UNION*" -o -type d -name "*stb_union*" | head -1)
        
        if [ -z "$extracted_dir" ]; then
            extracted_dir=$(find "$temp_extract" -mindepth 1 -maxdepth 1 -type d | head -1)
        fi
        
        if [ -n "$extracted_dir" ] && [ -d "$extracted_dir" ]; then
            print_message "Déplacement du plugin vers $INSTALL_PATH/"
            cp -r "$extracted_dir" "$INSTALL_PATH/$PLUGIN_NAME"
            
            if [ $? -eq 0 ]; then
                print_success "Plugin déplacé avec succès"
            else
                print_error "Échec du déplacement du plugin"
                exit 1
            fi
        else
            print_message "Structure particulière détectée, copie du contenu..."
            cp -r "$temp_extract"/* "$INSTALL_PATH/$PLUGIN_NAME"
        fi
        
        # Nettoyage
        rm -rf "$temp_extract"
    else
        print_error "Échec de la décompression"
        exit 1
    fi
}

# Définition des permissions
set_permissions() {
    print_message "Configuration des permissions..."
    local plugin_dir="$INSTALL_PATH/$PLUGIN_NAME"
    
    if [ -d "$plugin_dir" ]; then
        find "$plugin_dir" -type d -exec chmod 755 {} \;
        find "$plugin_dir" -type f -exec chmod 644 {} \;
        find "$plugin_dir" -name "*.sh" -exec chmod 755 {} \;
        find "$plugin_dir" -name "*.py" -exec chmod 644 {} \;
        find "$plugin_dir" -name "*.so" -exec chmod 755 {} \;
        find "$plugin_dir" -name "*.ipk" -exec chmod 755 {} \;
        
        print_success "Permissions configurées avec succès"
    else
        print_error "Dossier du plugin non trouvé"
        exit 1
    fi
}

# Vérification de l'installation
verify_installation() {
    print_message "Vérification de l'installation..."
    local plugin_dir="$INSTALL_PATH/$PLUGIN_NAME"
    
    if [ -d "$plugin_dir" ]; then
        if [ -f "$plugin_dir/plugin.py" ] || [ -f "$plugin_dir/__init__.py" ]; then
            print_success "Plugin installé correctement avec les fichiers essentiels"
        else
            print_warning "Plugin installé mais fichiers essentiels manquants"
        fi
        
        plugin_size=$(du -sh "$plugin_dir" | cut -f1)
        print_message "Taille du plugin: $plugin_size"
        
        return 0
    else
        print_error "Le plugin n'a pas été installé correctement"
        return 1
    fi
}

# Restart enigma2 GUI
restart_enigma2() {
    print_message "Redémarrage de l'interface Enigma2..."
    
    if command -v init >/dev/null 2>&1; then
        print_message "Utilisation de init 4 && init 3..."
        init 4 && sleep 2 && init 3
    elif command -v systemctl >/dev/null 2>&1; then
        print_message "Utilisation de systemctl..."
        systemctl restart enigma2
    else
        print_message "Utilisation de killall enigma2..."
        killall -9 enigma2 2>/dev/null
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Enigma2 redémarré avec succès"
    else
        print_warning "Redémarrage manuel nécessaire"
    fi
}

# ==================== FONCTION PRINCIPALE ====================
main() {
    # Afficher la bannière
    print_banner
    
    # Attendre 2 secondes pour que l'utilisateur voie la bannière
    sleep 2
    
    print_header
    
    # Vérifications préalables
    check_root
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
        echo -e "\n${COLORS[GREEN]}╔══════════════════════════════════════════════════════════╗${COLORS[RESET]}"
        echo -e "${COLORS[GREEN]}║         INSTALLATION TERMINÉE AVEC SUCCÈS !            ║${COLORS[RESET]}"
        echo -e "${COLORS[GREEN]}╚══════════════════════════════════════════════════════════╝${COLORS[RESET]}"
        echo -e "\n${COLORS[YELLOW]}Détails de l'installation:${COLORS[RESET]}"
        echo -e "  • Plugin: $PLUGIN_NAME"
        echo -e "  • Emplacement: $INSTALL_PATH/$PLUGIN_NAME"
        echo -e "  • Date: $(date +"%d/%m/%Y à %H:%M:%S")"
        
        # Nettoyage
        cleanup
        
        # Redémarrage d'Enigma2
        echo -e "\n${COLORS[YELLOW]}Redémarrage de l'interface Enigma2...${COLORS[RESET]}"
        sleep 2
        restart_enigma2
        
        echo -e "\n${COLORS[GREEN]}✓ Installation complète et réussie !${COLORS[RESET]}\n"
        exit 0
    else
        print_error "L'installation a échoué"
        cleanup
        exit 1
    fi
}

# ==================== EXÉCUTION ====================
# Gestion des interruptions
trap 'print_error "Script interrompu"; cleanup; exit 1' INT TERM

# Lancer le script
main "$@"
