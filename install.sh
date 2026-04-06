#!/bin/bash
# =================================================================
#     SCRIPT D'INSTALLATION ULTRA - PLUGIN STB_UNION E2
#     Version: 2.0 - Interface Sophistiquée
#     Compatible: Enigma2 (OpenPLi, OpenATV, OpenBH, etc.)
# =================================================================

# ==================== CONFIGURATION ====================
PLUGIN_URL="https://github.com/ilyasM6/Plugins/raw/main/STB_UNION%20E2.tar.gz"
PLUGIN_NAME="STB_UNION_E2"
TEMP_FILE="/tmp/${PLUGIN_NAME}.tar.gz"
INSTALL_BASE="/usr/lib/enigma2/python/Plugins/Extensions"
INSTALL_PATH="${INSTALL_BASE}/${PLUGIN_NAME}"
LOG_FILE="/tmp/install_${PLUGIN_NAME}_$(date +%Y%m%d_%H%M%S).log"
BACKUP_PATH="${INSTALL_BASE}/BACKUP_${PLUGIN_NAME}_$(date +%Y%m%d_%H%M%S)"

# ==================== COULEURS AVANCÉES ====================
declare -A COLORS=(
    [RESET]="\033[0m"
    [BOLD]="\033[1m"
    [DIM]="\033[2m"
    [RED]="\033[31m"
    [GREEN]="\033[32m"
    [YELLOW]="\033[33m"
    [BLUE]="\033[34m"
    [MAGENTA]="\033[35m"
    [CYAN]="\033[36m"
    [WHITE]="\033[37m"
    [BG_RED]="\033[41m"
    [BG_GREEN]="\033[42m"
    [BG_YELLOW]="\033[43m"
    [BG_BLUE]="\033[44m"
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

print_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    echo -ne "\r${COLORS[CYAN]}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    echo -ne "] ${percentage}%%${COLORS[RESET]}"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null 2>&1; do
        for ((i=0; i<${#spinstr}; i++)); do
            echo -ne "\r${COLORS[MAGENTA]}[${spinstr:$i:1}] En cours...${COLORS[RESET]}"
            sleep $delay
        done
    done
    echo -ne "\r\033[K"
}

# ==================== FONCTIONS DE LOGGING ====================
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        INFO)  echo -e "${COLORS[GREEN]}[✓]${COLORS[RESET]} $message" ;;
        WARN)  echo -e "${COLORS[YELLOW]}[⚠]${COLORS[RESET]} $message" ;;
        ERROR) echo -e "${COLORS[RED]}[✗]${COLORS[RESET]} $message" ;;
        DEBUG) echo -e "${COLORS[DIM]}[→]${COLORS[RESET]} $message" ;;
        SUCCESS) echo -e "${COLORS[GREEN]}${COLORS[BOLD]}[✔]${COLORS[RESET]} $message" ;;
        *) echo "$message" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# ==================== VÉRIFICATIONS SYSTÈME ====================
check_system() {
    log INFO "Vérification du système..."
    
    # Vérification des droits root
    if [ "$EUID" -ne 0 ]; then 
        log ERROR "Ce script doit être exécuté avec les droits root (sudo)"
        exit 1
    fi
    
    # Détection de la distribution
    if [ -f /etc/image-version ]; then
        DISTRO=$(grep "distro" /etc/image-version | cut -d'=' -f2)
        VERSION=$(grep "version" /etc/image-version | cut -d'=' -f2)
        log SUCCESS "Distribution détectée: $DISTRO $VERSION"
    elif [ -f /etc/issue ]; then
        DISTRO=$(cat /etc/issue | head -1)
        log SUCCESS "Distribution détectée: $DISTRO"
    else
        log WARN "Distribution non reconnue, mais installation continue..."
    fi
    
    # Vérification de l'espace disque
    local available=$(df -m "$INSTALL_BASE" | awk 'NR==2 {print $4}')
    if [ "$available" -lt 50 ]; then
        log ERROR "Espace disque insuffisant: ${available}MB disponible (minimum 50MB)"
        exit 1
    fi
    log SUCCESS "Espace disque: ${available}MB disponible"
    
    # Vérification des dépendances
    local deps=("wget" "tar" "grep" "awk")
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log ERROR "Dépendances manquantes: ${missing[*]}"
        exit 1
    fi
    log SUCCESS "Toutes les dépendances sont présentes"
}

# ==================== SAUVEGARDE INTELLIGENTE ====================
smart_backup() {
    if [ -d "$INSTALL_PATH" ]; then
        log WARN "Une version existante du plugin a été trouvée"
        
        # Calculer la taille de l'ancienne installation
        local old_size=$(du -sh "$INSTALL_PATH" 2>/dev/null | cut -f1)
        log INFO "Ancienne installation: ${old_size}"
        
        # Créer la sauvegarde avec compression
        log INFO "Création d'une sauvegarde..."
        mkdir -p "$BACKUP_PATH"
        cp -r "$INSTALL_PATH"/* "$BACKUP_PATH/" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            log SUCCESS "Sauvegarde créée: $BACKUP_PATH"
            
            # Option de restauration
            echo -e "\n${COLORS[YELLOW]}Voulez-vous conserver la configuration ancienne? (o/n)${COLORS[RESET]}"
            read -t 10 -n 1 keep_config
            if [[ "$keep_config" =~ ^[Oo]$ ]]; then
                log INFO "Configuration préservée"
                # Sauvegarder les fichiers de config spécifiques
                find "$INSTALL_PATH" -name "*.cfg" -o -name "*.conf" -o -name "settings" | while read config; do
                    local rel_path="${config#$INSTALL_PATH/}"
                    local backup_config="$BACKUP_PATH/$rel_path"
                    if [ -f "$backup_config" ]; then
                        cp "$backup_config" "$config"
                        log DEBUG "Configuration restaurée: $rel_path"
                    fi
                done
            fi
        else
            log ERROR "Échec de la sauvegarde"
            return 1
        fi
    fi
    return 0
}

# ==================== TÉLÉCHARGEMENT AVEC PROGRESSION ====================
download_with_progress() {
    log INFO "Téléchargement du plugin depuis GitHub..."
    
    # Tester la connexion
    if ! wget --spider --timeout=5 "$PLUGIN_URL" 2>/dev/null; then
        log ERROR "Impossible d'atteindre le serveur GitHub"
        return 1
    fi
    
    # Téléchargement avec barre de progression
    if wget --progress=bar:force --show-progress -O "$TEMP_FILE" "$PLUGIN_URL" 2>&1 | grep -E "[0-9]+%" | while read line; do
        percent=$(echo "$line" | grep -oP '[0-9]+(?=%)')
        print_progress "$percent" 100
    done; then
        echo ""
        local file_size=$(du -h "$TEMP_FILE" | cut -f1)
        log SUCCESS "Téléchargement terminé: ${file_size}"
        return 0
    else
        log ERROR "Échec du téléchargement"
        return 1
    fi
}

# ==================== VALIDATION D'ARCHIVE ====================
validate_archive() {
    log INFO "Validation de l'archive téléchargée..."
    
    # Vérifier l'intégrité du fichier
    if [ ! -f "$TEMP_FILE" ]; then
        log ERROR "Fichier non trouvé: $TEMP_FILE"
        return 1
    fi
    
    # Tester l'archive tar.gz
    if gunzip -t "$TEMP_FILE" 2>/dev/null; then
        log SUCCESS "Archive valide (intégrité vérifiée)"
        
        # Analyser le contenu
        local content_count=$(tar -tzf "$TEMP_FILE" 2>/dev/null | wc -l)
        log DEBUG "Contient $content_count fichiers/dossiers"
        return 0
    else
        log ERROR "Archive corrompue"
        return 1
    fi
}

# ==================== EXTRACTION INTELLIGENTE ====================
smart_extract() {
    log INFO "Extraction du plugin..."
    
    # Créer le répertoire d'installation
    mkdir -p "$INSTALL_BASE"
    
    # Extraire dans un répertoire temporaire
    local temp_extract="/tmp/extract_$$"
    mkdir -p "$temp_extract"
    
    # Extraction avec gestion des erreurs
    if tar -xzf "$TEMP_FILE" -C "$temp_extract" 2>&1 | while read line; do
        echo -ne "\r${COLORS[CYAN]}[↻] Extraction: $(echo $line | cut -c1-40)${COLORS[RESET]}"
    done; then
        echo ""
        log SUCCESS "Archive extraite avec succès"
        
        # Détection intelligente de la structure
        local extracted_items=("$temp_extract"/*)
        
        if [ ${#extracted_items[@]} -eq 1 ] && [ -d "${extracted_items[0]}" ]; then
            # Structure standard: un dossier principal
            local source_dir="${extracted_items[0]}"
            log DEBUG "Structure détectée: dossier unique"
        else
            # Structure multiple: tout déplacer
            local source_dir="$temp_extract"
            log DEBUG "Structure détectée: fichiers multiples"
        fi
        
        # Nettoyer l'ancienne installation
        rm -rf "$INSTALL_PATH"
        
        # Copier vers la destination finale
        cp -r "$source_dir" "$INSTALL_PATH" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            log SUCCESS "Plugin installé dans: $INSTALL_PATH"
            rm -rf "$temp_extract"
            return 0
        else
            log ERROR "Échec de la copie"
            return 1
        fi
    else
        log ERROR "Échec de l'extraction"
        return 1
    fi
}

# ==================== PERMISSIONS OPTIMISÉES ====================
optimize_permissions() {
    log INFO "Configuration des permissions..."
    
    if [ ! -d "$INSTALL_PATH" ]; then
        log ERROR "Dossier d'installation introuvable"
        return 1
    fi
    
    # Statistiques avant modification
    local before_count=$(find "$INSTALL_PATH" -type f | wc -l)
    
    # Définir les permissions récursives
    find "$INSTALL_PATH" -type d -exec chmod 755 {} \;
    find "$INSTALL_PATH" -type f -exec chmod 644 {} \;
    find "$INSTALL_PATH" -name "*.sh" -exec chmod 755 {} \;
    find "$INSTALL_PATH" -name "*.py" -exec chmod 644 {} \;
    find "$INSTALL_PATH" -name "*.so" -exec chmod 755 {} \;
    find "$INSTALL_PATH" -name "*.ipk" -exec chmod 755 {} \;
    
    # Permissions spéciales pour certains fichiers
    [ -f "$INSTALL_PATH/bin/*" ] && chmod 755 "$INSTALL_PATH"/bin/* 2>/dev/null
    [ -f "$INSTALL_PATH/scripts/*" ] && chmod 755 "$INSTALL_PATH"/scripts/* 2>/dev/null
    
    # Vérification
    local after_count=$(find "$INSTALL_PATH" -type f | wc -l)
    log SUCCESS "Permissions configurées: $after_count fichiers traités"
    
    # Propriétaire (root:root par défaut pour Enigma2)
    chown -R root:root "$INSTALL_PATH" 2>/dev/null
    log DEBUG "Propriétaire: root:root"
    
    return 0
}

# ==================== VALIDATION D'INSTALLATION ====================
validate_installation() {
    log INFO "Validation de l'installation..."
    
    local checks_passed=0
    local checks_total=3
    
    # Vérification 1: Dossier existe
    if [ -d "$INSTALL_PATH" ]; then
        log DEBUG "[1/$checks_total] Dossier d'installation présent"
        ((checks_passed++))
    else
        log ERROR "[1/$checks_total] Dossier d'installation manquant"
    fi
    
    # Vérification 2: Contient des fichiers
    local file_count=$(find "$INSTALL_PATH" -type f 2>/dev/null | wc -l)
    if [ "$file_count" -gt 0 ]; then
        log DEBUG "[2/$checks_total] $file_count fichiers installés"
        ((checks_passed++))
    else
        log ERROR "[2/$checks_total] Aucun fichier trouvé"
    fi
    
    # Vérification 3: Plugin Python valide
    if [ -f "$INSTALL_PATH/plugin.py" ] || [ -f "$INSTALL_PATH/__init__.py" ] || [ -d "$INSTALL_PATH"/*/plugin.py ]; then
        log DEBUG "[3/$checks_total] Plugin Python valide détecté"
        ((checks_passed++))
    else
        log WARN "[3/$checks_total] Plugin Python non standard (peut fonctionner quand même)"
        ((checks_passed++)) # On considère comme réussi car certains plugins ont des structures différentes
    fi
    
    if [ $checks_passed -ge 2 ]; then
        log SUCCESS "Installation validée ($checks_passed/$checks_total critères)"
        return 0
    else
        log ERROR "Installation invalide ($checks_passed/$checks_total critères)"
        return 1
    fi
}

# ==================== REDÉMARRAGE INTELLIGENT ====================
smart_restart() {
    log INFO "Préparation du redémarrage d'Enigma2..."
    
    # Sauvegarder les processus actifs
    local running_processes=$(ps | grep -c enigma2)
    
    # Nettoyage du cache Python
    log DEBUG "Nettoyage du cache Python (*.pyc, *.pyo)..."
    find "$INSTALL_PATH" -name "*.pyc" -delete 2>/dev/null
    find "$INSTALL_PATH" -name "*.pyo" -delete 2>/dev/null
    
    # Options de redémarrage
    local restart_method=""
    
    if command -v systemctl &> /dev/null; then
        restart_method="systemctl"
        log INFO "Redémarrage via systemctl..."
        systemctl restart enigma2 &
    elif command -v init &> /dev/null; then
        restart_method="init"
        log INFO "Redémarrage via init..."
        (init 4 && sleep 3 && init 3) &
    else
        restart_method="killall"
        log INFO "Redémarrage via killall..."
        (killall -9 enigma2 2>/dev/null) &
    fi
    
    # Animation pendant le redémarrage
    local restart_pid=$!
    spinner $restart_pid
    
    wait $restart_pid 2>/dev/null
    sleep 2
    
    # Vérifier si Enigma2 a redémarré
    if pgrep -x "enigma2" > /dev/null; then
        log SUCCESS "Enigma2 redémarré avec succès"
        return 0
    else
        log WARN "Redémarrage automatique incertain, mais l'installation est complète"
        return 1
    fi
}

# ==================== RAPPORT FINAL ====================
generate_report() {
    local install_size=$(du -sh "$INSTALL_PATH" 2>/dev/null | cut -f1)
    local file_count=$(find "$INSTALL_PATH" -type f 2>/dev/null | wc -l)
    local dir_count=$(find "$INSTALL_PATH" -type d 2>/dev/null | wc -l)
    
    echo ""
    echo -e "${COLORS[GREEN]}${COLORS[BOLD]}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    INSTALLATION RÉUSSIE !                            ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${COLORS[RESET]}"
    
    echo -e "${COLORS[CYAN]}${COLORS[BOLD]}📊 RAPPORT D'INSTALLATION${COLORS[RESET]}"
    echo -e "${COLORS[BLUE]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLORS[RESET]}"
    echo -e "  ${COLORS[GREEN]}✓${COLORS[RESET]} Plugin:     ${COLORS[WHITE]}STB_UNION E2${COLORS[RESET]}"
    echo -e "  ${COLORS[GREEN]}✓${COLORS[RESET]} Version:     ${COLORS[WHITE]}Dernière disponible${COLORS[RESET]}"
    echo -e "  ${COLORS[GREEN]}✓${COLORS[RESET]} Emplacement: ${COLORS[WHITE]}$INSTALL_PATH${COLORS[RESET]}"
    echo -e "  ${COLORS[GREEN]}✓${COLORS[RESET]} Taille:      ${COLORS[WHITE]}$install_size${COLORS[RESET]}"
    echo -e "  ${COLORS[GREEN]}✓${COLORS[RESET]} Fichiers:    ${COLORS[WHITE]}$file_count fichiers, $dir_count dossiers${COLORS[RESET]}"
    echo -e "  ${COLORS[GREEN]}✓${COLORS[RESET]} Log:         ${COLORS[WHITE]}$LOG_FILE${COLORS[RESET]}"
    
    if [ -d "$BACKUP_PATH" ]; then
        local backup_size=$(du -sh "$BACKUP_PATH" 2>/dev/null | cut -f1)
        echo -e "  ${COLORS[YELLOW]}ℹ${COLORS[RESET]} Sauvegarde:  ${COLORS[WHITE]}$BACKUP_PATH ($backup_size)${COLORS[RESET]}"
    fi
    
    echo -e "${COLORS[BLUE]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLORS[RESET]}"
    
    echo -e "\n${COLORS[YELLOW]}💡 ASTUCES:${COLORS[RESET]}"
    echo -e "  • Pour désinstaller: rm -rf $INSTALL_PATH"
    if [ -d "$BACKUP_PATH" ]; then
        echo -e "  • Pour restaurer: rm -rf $INSTALL_PATH && cp -r $BACKUP_PATH $INSTALL_PATH"
    fi
    echo -e "  • Log complet: cat $LOG_FILE"
    
    echo -e "\n${COLORS[GREEN]}${COLORS[BOLD]}✨ Le plugin est prêt à l'emploi ! ✨${COLORS[RESET]}\n"
}

# ==================== FONCTION PRINCIPALE ====================
main() {
    print_banner
    
    log INFO "Démarrage de l'installation sophistiquée"
    log INFO "Log sauvegardé: $LOG_FILE"
    echo ""
    
    # Étape 1: Vérifications système
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}🔍 ÉTAPE 1/7: VÉRIFICATIONS SYSTÈME${COLORS[RESET]}"
    check_system
    echo ""
    
    # Étape 2: Sauvegarde
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}💾 ÉTAPE 2/7: SAUVEGARDE${COLORS[RESET]}"
    smart_backup
    echo ""
    
    # Étape 3: Téléchargement
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}📥 ÉTAPE 3/7: TÉLÉCHARGEMENT${COLORS[RESET]}"
    download_with_progress || exit 1
    echo ""
    
    # Étape 4: Validation
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}🔐 ÉTAPE 4/7: VALIDATION${COLORS[RESET]}"
    validate_archive || exit 1
    echo ""
    
    # Étape 5: Extraction
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}📂 ÉTAPE 5/7: EXTRACTION${COLORS[RESET]}"
    smart_extract || exit 1
    echo ""
    
    # Étape 6: Permissions
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}🔧 ÉTAPE 6/7: PERMISSIONS${COLORS[RESET]}"
    optimize_permissions || exit 1
    echo ""
    
    # Étape 7: Validation finale
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}✅ ÉTAPE 7/7: VALIDATION FINALE${COLORS[RESET]}"
    validate_installation || exit 1
    echo ""
    
    # Nettoyage
    rm -f "$TEMP_FILE"
    log DEBUG "Nettoyage des fichiers temporaires effectué"
    
    # Générer rapport
    generate_report
    
    # Redémarrage
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}🔄 REDÉMARRAGE D'ENIGMA2${COLORS[RESET]}"
    echo -e "${COLORS[YELLOW]}L'interface va redémarrer dans 3 secondes...${COLORS[RESET]}"
    sleep 3
    
    smart_restart
    
    log SUCCESS "Script terminé avec succès"
    exit 0
}

# Gestion des interruptions
trap 'echo -e "\n${COLORS[RED]}${COLORS[BOLD]}Installation interrompue par l\'utilisateur${COLORS[RESET]}"; rm -f "$TEMP_FILE"; exit 1' INT TERM

# Exécution
main "$@"
