#!/bin/bash
#
################################################################################
# configurarAtualizador.sh - realizar a configuracao basica do atualizador
#
# DATA: 03/07/2024 09:53 - Versao 2.3
#
# ------------------------------------------------------------------------------
# Autor: Luiz Gustavo <luiz.gustavo@avancoinfo.com.br>
#                     <luizgcesar@gmail.com.br>
# site: https://github.com/ketteiGustavo
# ------------------------------------------------------------------------------
# Versao 1: realizar a configuracao de forma correta
# Versao 2: Mudanças para baixar o configurador pelo help e rodar
# Versão 2.1: Melhoria para servidores que usam slack, opções de download via
#             comando curl -k
# Versão 2.2: Opção de não sair caso não tenha algum dos comandos necessários,
#             e caso o comando não esteja instalado não ativar os recursos do
#             comando.
# Versão 2.3 Melhoras visuais na configuração.
# ------------------------------------------------------------------------------
# Objetivo: facilitar o uso do atualizador.
###############################


MENSAGEM_USO="
Programa: $(basename "$0")

--------------------------------------------------------------------------------
                              [OPCOES DISPONIVEIS]

OPCOES NA LINHA DE COMANDO:
    -h, --help      Mostra esta tela de ajuda e sai
    -V, --version   Mostra a versao do programa e sai
MODO DE USAR:
    (em construção - AGUARDE

--------------------------------------------------------------------------------
"

# Funcao para extrair e exibir a versao do programa
mostrar_versao() {
    local versao=$(grep '^# DATA:' "$0" | head -1 | cut -d '-' -f 2 | sed 's/Versao //')
    echo -n "-Programa: $(basename "$0")"
    echo
    echo "-Versao: $versao"
}

###############################

PASTA_AVANCO="/u/rede/avanco"
BATS="/u/bats"
EXEC="/u/sist/exec"
versaoCobol=""
statusOnline="status-online.gnt"
script_atualizador="atualizador"
script_baixar_atualizacao="baixarAtualizacao"
manual_atualizador="atualizador.1.gz"
url_baixarAtualizacao="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/baixarAtualizacao"
url_atualizador="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/atualizador"
url_manual_atualizador="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Manuais/atualizador.1.gz"
url_base_status_online_gnt="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/gnt/"
buscaStatusOnline=""
url_versao_release="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/versao_release.txt"
pacoteConfiguracao="https://github.com/ketteiGustavo/atualizador/raw/main/Atual/PacoteAtualizador.rar"
distro_nome=$(grep '^NAME=' /etc/os-release | cut -d '=' -f 2 | tr -d '"' | awk '{print $1}')
clear
echo "SERVIDOR UTILIZA: $distro_nome"


# Funcao para verificar qual o cobol usado
verifica_cobol() {
    if command -v cobrun &> /dev/null; then
        resultado=$(cobrun 2>&1)
        versaoCobol=$(echo "$resultado" | sed -n 's/V\([0-9]\+\.[0-9]\+\).*/\1/p')
        inf_versaoCobol="$versaoCobol"
    else
        while true; do
            read -p "Informe a versao do Cobol nesse servidor: " versao_informada
            case "$versao_informada" in
            "40" | "4.0")
                versaoCobol="4.0"
                break
                ;;
            "41" | "4.1")
                versaoCobol="4.1"
                break
                ;;
            *)
                echo "Favor informar o cobol corretamente!"
                echo "EXEMPLO: '4.0'"
                ;;
            esac
            read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
            clear
        done
    fi
}

checar_comandos() {
    for comando in "$@"; do
        if ! command -v "$comando" &> /dev/null; then
            echo "O COMANDO '$comando' ESTA DESABILITADO NESSE SERVIDOR"
        fi
    done
}

# Testa se o usuario e root.
if [ "$(id -u)" -ne 0 ]; then
    #clear
    tput smso
    echo 'NECESSARIO ESTAR COM O USUARIO ROOT, ACESSO NEGADO !!!'
    echo "AS $(date +'%H:%M:%S') DO DIA $(date +'%d/%m/%Y') HOUVE UMA TENTATIVA DE CONFIGURAR O ATUALIZADOR" >> /u/sist/logs/registroConfiguracao.log
    echo "O USUARIO $USER TENTOU UTILIZAR O CONFIGURADOR" >> /u/sist/logs/registroConfiguracao.log
    tput rmso
    exit 1
else
    tput cup 3 28
    tput smso
    echo "INICIANDO A CONFIGURACAO"
    tput rmso
    echo
    checar_comandos wget curl mandb
fi

# funcao para baixar os arquivos necessarios
baixar_arquivo() {
    local url=$1
    local destino=$2
    if curl -k --output /dev/null --silent --head --fail "$url"; then
        curl -# -O --output-dir "$destino" "$url"
        sleep 2
    else
        echo "NAO FOI POSSIVEL ACESSAR O '$url'"
    fi
}

configurar_online () {

    local novo_URL
    verifica_cobol
    cd "$EXEC" || { echo "Falha ao acessar diretorio $EXEC"; exit 1; }

    if [ "$versaoCobol" == "4.0" ]; then
        buscaStatusOnline=40
        novo_URL=$url_base_status_online_gnt$buscaStatusOnline$statusOnline
    elif [ "$versaoCobol" == "4.1" ]; then
        buscaStatusOnline=41
        novo_URL=$url_base_status_online_gnt$buscaStatusOnline$statusOnline
    else
        echo "Versao do COBOL invalida."
        exit 1
    fi

    if [ "$distro_nome" == "Debian" ]; then
        echo INSTALANDO OS MANUAIS!
        baixar_arquivo "$url_manual_atualizador" "$PASTA_AVANCO"
        chown root:root $PASTA_AVANCO/atualizador.1.gz
        mv $PASTA_AVANCO/atualizador.1.gz /usr/share/man/man1/
        mandb > /dev/null 2>&1
        echo
    fi

    if [ ! -e "$EXEC/status-online.gnt" ]; then
        echo "INSTALANDO O STATUS-ONLINE.gnt"
        baixar_arquivo "$novo_URL" "$EXEC"
        mv /u/sist/exec/$buscaStatusOnline$statusOnline /u/sist/exec/$statusOnline
        echo
    fi

    echo "ATIVANDO ATUALIZADOR! AGUARDE"
    baixar_arquivo "$url_atualizador" "$PASTA_AVANCO"
    baixar_arquivo "$url_baixarAtualizacao" "$PASTA_AVANCO"
    echo
    chown avanco:sist $PASTA_AVANCO/atualizador
    chown avanco:sist $PASTA_AVANCO/baixarAtualizacao

    chmod 777 $PASTA_AVANCO/atualizador
    chmod 777 $PASTA_AVANCO/baixarAtualizacao

    mv $PASTA_AVANCO/atualizador /u/bats/
    mv $PASTA_AVANCO/baixarAtualizacao /u/bats/

    chown avanco:sist /u/sist/exec/*
    chmod 777 /u/sist/exec/*
    echo
    echo
    echo "CONFIGURACAO REALIZADA!!!"
    echo "LOGUE COMO 'avanco' PARA ATUALIZAR!!!"
    sleep 3
    echo
    echo
}


# Tratamento das opcoes que serao responsaveis por controlar na linha de comando
# ------------------------------------------------------------------------------

case "$1" in
-h | --help)
    clear
    echo "$MENSAGEM_USO"
    exit 0
    ;;
-V | --version)
    # Extrai a versao diretamente do cabecalho do programa
    clear
    mostrar_versao
    exit 0
    ;;
*)
    if test -n "$1"; then
        echo Opcao invalida: $1
        exit 1
    fi
    ;;
esac

###############################
configurar_online
exit 0