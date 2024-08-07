#!/bin/bash
#
################################################################################
# configurarAtualizador.sh - realizar a configuracao basica do atualizador
#
# DATA: 03/07/2024 09:53 - Versao 2
#
# ------------------------------------------------------------------------------
# Autor: Luiz Gustavo <luiz.gustavo@avancoinfo.com.br>
#                     <luizgcesar@gmail.com.br>
# site: https://github.com/ketteiGustavo
# ------------------------------------------------------------------------------
# Versao 1: realizar a configuracao de forma correta
# Versao 2: Mudanças para baixar o configurador pelo help e rodar
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
            echo "Necessario configurar '$comando'."
            exit 1
        fi
    done
}

checar_comandos wget curl mandb

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
    echo "INICIANDO A CONFIGURACAO"
fi

# funcao para baixar os arquivos necessarios
baixar_arquivo() {
    local url=$1
    local destino=$2
    if curl -k --output /dev/null --silent --head --fail "$url"; then
        wget -c "$url" -P "$destino"
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

    baixar_arquivo "$novo_URL" "$EXEC"
    baixar_arquivo "$url_atualizador" "$PASTA_AVANCO"
    baixar_arquivo "$url_baixarAtualizacao" "$PASTA_AVANCO"
    baixar_arquivo "$url_manual_atualizador" "$PASTA_AVANCO"
    baixar_arquivo "$url_versao_release" "$PASTA_AVANCO"


    chown avanco:sist $PASTA_AVANCO/atualizador
    chown avanco:sist $PASTA_AVANCO/baixarAtualizacao
    chown root:root $PASTA_AVANCO/atualizador.1.gz
    chown avanco:sist $PASTA_AVANCO/versao_release.txt
    chmod 666 $PASTA_AVANCO/versao_release.txt

    chmod 777 $PASTA_AVANCO/atualizador
    chmod 777 $PASTA_AVANCO/baixarAtualizacao

    mv $PASTA_AVANCO/atualizador /u/bats/
    mv $PASTA_AVANCO/baixarAtualizacao /u/bats/
    mv $PASTA_AVANCO/atualizador.1.gz /usr/share/man/man1/
    mv /u/sist/exec/$buscaStatusOnline$statusOnline /u/sist/exec/$statusOnline
    mv $PASTA_AVANCO/versao_release.txt /u/sist/controle

    mandb

    #chown root:root /u/rede/arqp/configurarAtualizador
    #chmod 700 /u/rede/arqp/configurarAtualizador

    #mv /u/rede/arqp/configurarAtualizador /u/bats/


    chown avanco:sist /u/sist/exec/*
    chmod 777 /u/sist/exec/*

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
su - avanco