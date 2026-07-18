#!/bin/bash

echo "Teste de execução - Script Arch"

# ==========================================
# --- Cores para o Terminal ---
# ==========================================
VERDE='\033[1;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[1;31m'
AZUL='\033[1;34m'
NC='\033[0m' # Sem cor

# ==========================================
# --- Variáveis Globais (Setup) ---
# ==========================================
HOME_DIR="$HOME"
HIDDEN_DIR="$HOME_DIR/.python_master"
VENV_DIR="$HIDDEN_DIR/venv"
RELATORIO="$HOME_DIR/Resumo_Instalacao.md"
INSTALAR_PYTHON="n"
INSTALAR_OBS="n"
INSTALAR_GIT="n"
INSTALAR_KITTY="n"

# A variável de pacotes começa com pacman, mas será atualizada para yay dinamicamente
PKG_MANAGER="sudo pacman"

declare -a RELATORIO_SUCESSOS=()
declare -a RELATORIO_FALHAS=()
declare -a RELATORIO_AVISOS=()

# ==========================================
# --- Verificação de Segurança ---
# ==========================================
verificar_nao_root() {
    if [ "$EUID" -eq 0 ]; then
        echo -e "\n${VERMELHO}[❌] Erro: Não execute este script com 'sudo'!${NC}"
        echo -e "O script usará o sudo automaticamente apenas quando for necessário."
        echo -e "Gerenciadores do AUR (como o yay) não podem ser executados como root.\n"
        exit 1
    fi
}

# ==========================================
# --- MÓDULO: MIRRORS ---
# ==========================================
atualizar_mirrors() {
    echo -e "\n${AMARELO}--- Configurando e Otimizando Mirrors (Reflector) ---${NC}"

    # Instala o reflector se não existir
    if ! command -v reflector >/dev/null 2>&1; then
        echo -e "  ${AZUL}[*] Instalando 'reflector' para gerenciar mirrors...${NC}"
        sudo pacman -S --needed --noconfirm reflector >/dev/null 2>&1
    fi

    echo -e "  ${AZUL}[*] Buscando os mirrors mais rápidos (isso pode levar alguns instantes)...${NC}"

    # Busca os 15 mirrors HTTPS mais rápidos/recentes e salva em um arquivo temporário
    if sudo reflector --latest 15 --protocol https --sort rate --save /tmp/novos_mirrors.txt >/dev/null 2>&1; then
        echo -e "  ${AZUL}[*] Adicionando os novos mirrors no topo da lista atual (preservando os antigos)...${NC}"

        # Faz backup de segurança do mirrorlist atual
        sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bkp

        # Junta os novos mirrors (topo) com os antigos (base)
        cat /tmp/novos_mirrors.txt /etc/pacman.d/mirrorlist > /tmp/mirrorlist_mesclada.txt

        # Remove linhas de servidores duplicados (mantendo apenas a primeira aparição, no topo)
        awk '!seen[$0]++' /tmp/mirrorlist_mesclada.txt > /tmp/mirrorlist_final.txt

        # Substitui a lista pela nova mesclada
        sudo mv /tmp/mirrorlist_final.txt /etc/pacman.d/mirrorlist

        # Limpeza de temporários
        rm -f /tmp/novos_mirrors.txt /tmp/mirrorlist_mesclada.txt

        echo -e "  ${VERDE}[✔] Mirrors atualizados e mesclados com sucesso!${NC}"
        RELATORIO_SUCESSOS+=("- Mirrors otimizados e adicionados ao topo")
    else
        echo -e "  ${VERMELHO}[✖] Falha ao buscar novos mirrors. A lista atual foi mantida.${NC}"
        RELATORIO_FALHAS+=("- Otimização de Mirrors com Reflector")
    fi
}

# ==========================================
# --- MÓDULO: MANUTENÇÃO ---
# ==========================================
executar_manutencao() {
    clear
    echo -e "${AZUL}==================================================${NC}"
    echo -e "${VERDE}     INICIANDO MANUTENÇÃO DO SISTEMA              ${NC}"
    echo -e "${AZUL}==================================================${NC}\n"

    # Atualiza o PKG_MANAGER se o yay já existir no sistema
    if command -v yay >/dev/null 2>&1; then
        PKG_MANAGER="yay"
    fi

    # --- 1. Otimização de Mirrors ---
    atualizar_mirrors

    # --- 2. Atualização do Sistema ---
    echo -e "\n${AMARELO}--- 2. Sincronizando Repositórios e Atualizando Sistema ---${NC}"
    if $PKG_MANAGER -Syu --noconfirm; then
        echo -e "${VERDE}[✔] Sistema atualizado com sucesso!\n${NC}"
    else
        echo -e "${VERMELHO}[✖] Houve um problema ao atualizar os pacotes.\n${NC}"
    fi

    # --- 3. Gerenciamento de Flatpaks ---
    echo -e "${AMARELO}--- 3. Verificando e Atualizando Flatpaks ---${NC}"
    if ! command -v flatpak >/dev/null 2>&1; then
        echo "Flatpak não encontrado. Instalando..."
        sudo pacman -S --noconfirm flatpak
    fi

    if flatpak update -y; then
        echo -e "${VERDE}[✔] Flatpaks atualizados com sucesso!\n${NC}"
    else
        echo -e "${VERMELHO}[✖] Falha ao atualizar os Flatpaks.\n${NC}"
    fi

    # --- 4. Limpeza de Pacotes Órfãos ---
    echo -e "${AMARELO}--- 4. Removendo Pacotes Órfãos (Lixo do Sistema) ---${NC}"
    PACOTES_ORFAOS=$(pacman -Qtdq 2>/dev/null)
    if [[ -n "$PACOTES_ORFAOS" ]]; then
        QTD_ORFAOS=$(echo "$PACOTES_ORFAOS" | wc -l)
        echo -e "Encontrados ${VERMELHO}${QTD_ORFAOS}${NC} pacotes órfãos. Removendo..."
        if sudo pacman -Rns --noconfirm $PACOTES_ORFAOS; then
            echo -e "${VERDE}[✔] Pacotes órfãos removidos com sucesso!\n${NC}"
        else
            echo -e "${VERMELHO}[✖] Erro ao remover pacotes órfãos.\n${NC}"
        fi
    else
        echo -e "${VERDE}[✔] Nenhum pacote órfão encontrado para remover.\n${NC}"
    fi

    # --- 5. Limpeza de Caches e Logs ---
    echo -e "${AMARELO}--- 5. Limpando Caches e Logs Antigos ---${NC}"
    if sudo pacman -Sc --noconfirm >/dev/null 2>&1; then
        echo -e "${VERDE}[✔] Cache do Pacman limpo!${NC}"
    else
        echo -e "${VERMELHO}[✖] Erro ao limpar cache do Pacman.${NC}"
    fi

    if sudo journalctl --vacuum-time=7d >/dev/null 2>&1; then
        echo -e "${VERDE}[✔] Logs antigos limpos com sucesso!\n${NC}"
    fi

    # --- 6. Finalização ---
    clear
    if command -v fastfetch >/dev/null 2>&1; then
        fastfetch
    fi

    echo -e "\n${AZUL}==================================================${NC}"
    echo -e "${VERDE}------ Sistema atualizado, limpo e otimizado! ------${NC}"
    echo -e "${AZUL}==================================================${NC}\n"
}

# ==========================================
# --- MÓDULO: SETUP E INSTALAÇÃO ---
# ==========================================
perguntar_python() {
    read -p "Instalar o ambiente Python Master? (s/n): " resposta
    [[ "$resposta" =~ ^[Ss]$ ]] && INSTALAR_PYTHON="s" || RELATORIO_AVISOS+=("- Python ignorado.")
}

perguntar_obs() {
    echo -e "\n${AZUL}==================================================${NC}"
    read -p "Deseja instalar o OBS Studio? (s/n): " resposta
    [[ "$resposta" =~ ^[Ss]$ ]] && INSTALAR_OBS="s" || RELATORIO_AVISOS+=("- OBS Studio ignorado.")
}

perguntar_git() {
    echo -e "\n${AZUL}==================================================${NC}"
    read -p "Deseja instalar o Git e utilitários dev (GitHub CLI, Lazygit)? (s/n): " resposta
    [[ "$resposta" =~ ^[Ss]$ ]] && INSTALAR_GIT="s" || RELATORIO_AVISOS+=("- Ferramentas Git ignoradas.")
}

perguntar_kitty() {
    echo -e "\n${AZUL}==================================================${NC}"
    read -p "Deseja instalar o Terminal Kitty? (s/n): " resposta
    [[ "$resposta" =~ ^[Ss]$ ]] && INSTALAR_KITTY="s" || RELATORIO_AVISOS+=("- Terminal Kitty ignorado.")
}

instalar_yay_oculto() {
    echo -e "\n${AMARELO}--- Configurando Gerenciador AUR (yay) ---${NC}"
    if command -v yay >/dev/null 2>&1; then
        echo -e "  ${VERDE}[✔] Yay já está instalado e pronto para uso.${NC}"
        PKG_MANAGER="yay"
        return
    fi

    echo -e "  ${AZUL}[*] Instalando 'yay' em diretório oculto (~/.aur_builds)...${NC}"
    # Garante que as dependências de compilação existam
    sudo pacman -S --needed --noconfirm base-devel git >/dev/null 2>&1

    # Cria a pasta oculta na Home do usuário
    AUR_DIR="$HOME_DIR/.aur_builds"
    mkdir -p "$AUR_DIR"
    cd "$AUR_DIR" || return

    # Clona o repositório yay-bin
    if [ ! -d "yay-bin" ]; then
        git clone https://aur.archlinux.org/yay-bin.git >/dev/null 2>&1
    fi

    cd yay-bin || return

    # Compila e instala o yay
    if makepkg -si --noconfirm >/dev/null 2>&1; then
        echo -e "  ${VERDE}[✔] Yay instalado com sucesso em $AUR_DIR!${NC}"
        PKG_MANAGER="yay" # Define o yay como gerenciador oficial a partir de agora
        RELATORIO_SUCESSOS+=("- Yay (Instalado em diretório oculto)")
    else
        echo -e "  ${VERMELHO}[✖] Erro ao instalar o Yay.${NC}"
        RELATORIO_FALHAS+=("- Instalação do Yay")
    fi

    cd "$HOME_DIR" || return
}

instalar_grupo() {
    local NOME_GRUPO=$1
    shift
    local PACOTES=("$@")
    echo -e "\n${AZUL}[*] Processando grupo: ${AMARELO}$NOME_GRUPO${NC} via $PKG_MANAGER..."

    for pkg in "${PACOTES[@]}"; do
        if pacman -Q "$pkg" > /dev/null 2>&1; then
            echo -e "  ${AMARELO}[⚡] '$pkg' já instalado. Verificando atualizações...${NC}"
            OUTPUT=$($PKG_MANAGER -S --noconfirm "$pkg" 2>&1)
            if [ $? -eq 0 ]; then
                echo -e "  ${VERDE}[✔] '$pkg' pronto e atualizado!${NC}"
                RELATORIO_SUCESSOS+=("- $pkg (Verificado/Atualizado)")
            else
                MSG_ERRO=$(echo "$OUTPUT" | tail -n 1)
                echo -e "  ${VERMELHO}[✖] Erro ao atualizar '$pkg': $MSG_ERRO${NC}"
                RELATORIO_FALHAS+=("- $pkg (Erro: $MSG_ERRO)")
            fi
        else
            echo -e "  ${AZUL}[*] Instalando '$pkg'...${NC}"
            OUTPUT=$($PKG_MANAGER -S --noconfirm "$pkg" 2>&1)
            if [ $? -eq 0 ]; then
                echo -e "  ${VERDE}[✔] '$pkg' instalado com sucesso!${NC}"
                RELATORIO_SUCESSOS+=("- $pkg (Instalado)")
            else
                MSG_ERRO=$(echo "$OUTPUT" | tail -n 1)
                echo -e "  ${VERMELHO}[✖] Erro ao instalar '$pkg': $MSG_ERRO${NC}"
                RELATORIO_FALHAS+=("- $pkg (Erro: $MSG_ERRO)")
            fi
        fi
    done
}

instalar_flatpaks() {
    echo -e "\n${AMARELO}--- Configurando Aplicativos Flatpak ---${NC}"
    FLATPAKS=("com.github.tchx84.Flatseal" "com.rtosta.zapzap")

    # Garante que o Flathub está ativo
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    for fp in "${FLATPAKS[@]}"; do
        if flatpak list | grep -q "$fp"; then
            echo -e "  ${AMARELO}[⚡] Flatpak '$fp' já instalado. Atualizando...${NC}"
            flatpak update "$fp" -y >/dev/null 2>&1
            RELATORIO_SUCESSOS+=("- Flatpak $fp (Atualizado)")
        else
            echo -e "  ${AZUL}[*] Instalando Flatpak '$fp'...${NC}"
            if flatpak install flathub "$fp" -y >/dev/null 2>&1; then
                echo -e "  ${VERDE}[✔] '$fp' instalado com sucesso!${NC}"
                RELATORIO_SUCESSOS+=("- Flatpak $fp (Instalado)")
            else
                echo -e "  ${VERMELHO}[✖] Erro ao instalar Flatpak '$fp'.${NC}"
                RELATORIO_FALHAS+=("- Flatpak $fp (Falha)")
            fi
        fi
    done
}

configurar_swap() {
    echo -e "\n${AMARELO}--- Configurando Memória Swap (8GiB) ---${NC}"

    if swapon --show | grep -q "/swapfile"; then
        echo -e "${VERDE}[✔] O arquivo /swapfile já está configurado e ativo.${NC}"
        RELATORIO_AVISOS+=("- Swap 8GB (Ignorado, já existente)")
        return
    fi

    echo -e "${AZUL}[*] Criando arquivo de swap de 8GiB (Isso pode demorar alguns segundos)...${NC}"
    sudo touch /swapfile

    # IMPORTANTE: Desativa CoW (Copy-on-Write) no Btrfs (padrão do Big Linux) para não corromper o Swap
    sudo chattr +C /swapfile 2>/dev/null

    if sudo fallocate -l 8G /swapfile; then
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile >/dev/null 2>&1
        sudo swapon /swapfile

        if ! grep -q "/swapfile" /etc/fstab; then
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
        fi

        echo -e "${VERDE}[✔] Swap de 8GiB ativado com sucesso e tornado permanente!${NC}"
        RELATORIO_SUCESSOS+=("- Swap de 8GiB criado e ativado")
    else
        echo -e "${VERMELHO}[✖] Erro ao criar o arquivo de swap.${NC}"
        RELATORIO_FALHAS+=("- Falha na criação do Swap")
    fi
}

configurar_energia_e_arquivos() {
    echo -e "\n${AMARELO}--- Configurando Energia e Sistemas de Arquivos ---${NC}"
    PACOTES_ENERGIA_FS=("power-profiles-daemon" "dosfstools" "exfatprogs")
    instalar_grupo "Energia e File Systems" "${PACOTES_ENERGIA_FS[@]}"

    if sudo systemctl enable --now power-profiles-daemon >/dev/null 2>&1; then
        echo -e "${VERDE}[✔] power-profiles-daemon ativado!${NC}"
    fi
}

configurar_firewall_kdeconnect() {
    echo -e "\n${AMARELO}--- Configurando Firewall para KDE Connect ---${NC}"
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw allow 1714:1764/udp >/dev/null 2>&1
        sudo ufw allow 1714:1764/tcp >/dev/null 2>&1
        sudo ufw reload >/dev/null 2>&1
        echo -e "${VERDE}[✔] Regras do UFW aplicadas para o KDE Connect!${NC}"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        sudo firewall-cmd --zone=public --permanent --add-service=kdeconnect >/dev/null 2>&1
        sudo firewall-cmd --reload >/dev/null 2>&1
        echo -e "${VERDE}[✔] Regras do Firewalld aplicadas para o KDE Connect!${NC}"
    else
        echo -e "${AMARELO}[!] Nenhum firewall detectado. O KDE Connect deve funcionar livremente.${NC}"
    fi
}

configurar_sddm() {
    echo -e "\n${AMARELO}--- Configurando Gerenciador de Login (SDDM) ---${NC}"
    echo -e "${AZUL}[*] Forçando o SDDM como gerenciador oficial do sistema...${NC}"

    if sudo systemctl enable -f sddm >/dev/null 2>&1; then
        echo -e "${VERDE}[✔] SDDM ativado com sucesso! As configurações do Plasma irão reconhecê-lo.${NC}"
        RELATORIO_SUCESSOS+=("- SDDM configurado e ativado")
    else
        echo -e "${VERMELHO}[✖] Falha ao ativar o SDDM.${NC}"
        RELATORIO_FALHAS+=("- Ativação do SDDM falhou")
    fi
}

configurar_ambiente_python() {
    echo -e "\n${AMARELO}--- Configurando Ambiente Virtual Python ---${NC}"
    mkdir -p "$HIDDEN_DIR"
    if python -m venv "$VENV_DIR"; then
        echo -e "${VERDE}[✔] Ambiente Virtual Python criado em $VENV_DIR${NC}"
        RELATORIO_SUCESSOS+=("- Ambiente Virtual Python criado")
    else
        echo -e "${VERMELHO}[✖] Falha ao criar Ambiente Virtual Python${NC}"
        RELATORIO_FALHAS+=("- Criação do Ambiente Virtual Python")
    fi
}

gerar_relatorio() {
    echo -e "\n${AMARELO}--- Gerando Relatório de Instalação ---${NC}"
    echo "# Relatório de Instalação - Setup Big Linux / Arch" > "$RELATORIO"

    echo -e "\n## Sucessos" >> "$RELATORIO"
    printf -- "- %s\n" "${RELATORIO_SUCESSOS[@]/#-/}" >> "$RELATORIO"

    echo -e "\n## Falhas" >> "$RELATORIO"
    if [ ${#RELATORIO_FALHAS[@]} -eq 0 ]; then
        echo "- Nenhuma falha detectada." >> "$RELATORIO"
    else
        printf -- "- %s\n" "${RELATORIO_FALHAS[@]/#-/}" >> "$RELATORIO"
    fi

    echo -e "\n## Avisos / Ignorados" >> "$RELATORIO"
    printf -- "- %s\n" "${RELATORIO_AVISOS[@]/#-/}" >> "$RELATORIO"

    echo -e "${VERDE}[✔] Relatório salvo em: $RELATORIO${NC}"
}

configurar_nanorc() {
    if [ -d "/usr/share/nano-syntax-highlighting" ] && ! grep -q "nano-syntax-highlighting" "$HOME/.nanorc" 2>/dev/null; then
        echo "include /usr/share/nano-syntax-highlighting/*.nanorc" >> "$HOME/.nanorc"
    fi
}

executar_setup() {
    clear
    echo -e "${AZUL}==================================================${NC}"
    echo -e "${VERDE}             INICIANDO SETUP DO SISTEMA           ${NC}"
    echo -e "${AZUL}==================================================${NC}\n"

    # Atualiza e mescla os mirrors mais rápidos ANTES de instalar pacotes
    atualizar_mirrors

    echo -e "${AMARELO}[*] Atualizando a base do sistema antes de instalar pacotes...${NC}"
    sudo pacman -Syu --noconfirm >/dev/null 2>&1

    # O yay é crucial aqui, ele vai permitir a instalação do Google Chrome e outros AURs
    instalar_yay_oculto

    perguntar_python
    perguntar_obs
    perguntar_git
    perguntar_kitty

    configurar_swap

    FONTES=(
        "noto-fonts" "noto-fonts-emoji" "noto-fonts-cjk" "ttf-liberation" "ttf-dejavu"
        "ttf-jetbrains-mono-nerd" "ttf-fira-mono" "ttf-fira-code"
    )
    instalar_grupo "Fontes do Sistema" "${FONTES[@]}"

    # Google Chrome foi adicionado nesta lista, o yay lidará perfeitamente com ele
    APPS_GERAIS=(
        "7zip" "ark" "btop" "dolphin" "dolphin-plugins" "elisa" "fastfetch" "firefox"
        "flatpak" "google-chrome" "gwenview" "kamoso" "kate" "kcalc" "kcolorchooser" "kdeconnect" "konsole"
        "libreoffice-fresh-pt-br" "nano" "nano-syntax-highlighting" "okular" "partitionmanager"
        "qbittorrent" "qbittorrent-nox" "spectacle" "intel-ucode" "base-devel" "unrar" "foot"
        "starship" "fzf" "sddm" "sddm-kcm" "kvantum" "papirus-icon-theme" "plasma-workspace-wallpapers"
    )
    instalar_grupo "Aplicativos Gerais (Lista Completa)" "${APPS_GERAIS[@]}"
    configurar_nanorc

    VLC_COMPLETO=("vlc" "libvlc" "phonon-qt6-vlc")
    instalar_grupo "VLC" "${VLC_COMPLETO[@]}"

    if [ "$INSTALAR_KITTY" == "s" ]; then
        instalar_grupo "Terminal Kitty" "kitty" "kitty-shell-integration" "kitty-terminfo"
    fi

    if [ "$INSTALAR_GIT" == "s" ]; then
        instalar_grupo "Ferramentas Git" "git" "lazygit" "github-cli"
    fi

    if [ "$INSTALAR_OBS" == "s" ]; then
        instalar_grupo "OBS Studio" "obs-studio" "obs-studio-plugin-browser"
    fi

    if [ "$INSTALAR_PYTHON" == "s" ]; then
        PYTHON_DEPENDENCIAS=("python-pip" "python-virtualenv" "python-setuptools" "python-wheel" "sdl2" "sdl2_image" "sdl2_mixer" "sdl2_ttf" "freetype2" "libjpeg-turbo" "libpng" "zlib")
        instalar_grupo "Dependências Python" "${PYTHON_DEPENDENCIAS[@]}"
    fi

    instalar_flatpaks
    configurar_energia_e_arquivos
    configurar_firewall_kdeconnect

    # === AQUI ESTÁ A ADIÇÃO DO SDDM ===
    configurar_sddm

    if [ "$INSTALAR_PYTHON" == "s" ]; then
        configurar_ambiente_python
    fi

    gerar_relatorio
}

# ==========================================
# --- MENU PRINCIPAL ---
# ==========================================
verificar_nao_root

while true; do
    clear
    echo -e "${AZUL}==================================================${NC}"
    echo -e "${VERDE}     MENU PRINCIPAL - SETUP BIG LINUX / ARCH      ${NC}"
    echo -e "${AZUL}==================================================${NC}"
    echo -e "  1) Executar Manutenção do Sistema (Limpeza, Update e Mirrors)"
    echo -e "  2) Executar Setup Inicial (Instalação e Configurações)"
    echo -e "  3) Sair"
    echo -e "${AZUL}==================================================${NC}"
    read -p "Escolha uma opção [1-3]: " OPCAO

    case $OPCAO in
        1)
            executar_manutencao
            read -n 1 -s -r -p "Pressione qualquer tecla para voltar ao menu..."
            ;;
        2)
            executar_setup
            read -n 1 -s -r -p "Pressione qualquer tecla para voltar ao menu..."
            ;;
        3)
            echo -e "\n${VERDE}Saindo do gerenciador. Até logo!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${VERMELHO}[✖] Opção inválida! Tente novamente.${NC}"
            sleep 2
            ;;
    esac
done
