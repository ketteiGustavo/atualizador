#!/bin/bash
#
################################################################################
# parser.sh - Lê arquivos de configuração e converte os dados para variaveis
#
# DATA: 12/08/2024 12:22 - Versao 1
#
# ------------------------------------------------------------------------------
# Autor: Luiz Gustavo <luiz.gustavo@avancoinfo.com.br>
#                     <luizgcesar@gmail.com.br>
# site: https://github.com/ketteiGustavo
# ------------------------------------------------------------------------------
# Versao 1: Faz a leitura de arquivos .config
# ------------------------------------------------------------------------------
# Objetivo: facilitar a leitura para scripts e programas.
###############################
CONFIG=$1

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
#

if [ -z "$CONFIG" ]; then
    echo USO: parser arquivo.config
    exit 1
elif [ ! -r "$CONFIG" ]; then
    echo ERROR: Nao foi possivel ler o arquivo $CONFIG
    exit 1
fi

# Loop para ler linha a linha a configuração, guardando em $LINHA
while read LINHA; do

    # ignorando as linhas de comentários
    [ "$(echo $LINHA | cut -c1)" = '#' ] && continue

    # ignorando as linhas em branco
    [ "$LINHA" ] || continue

    # guardando cada palavra da linha em $1, $2, $3...
    set - $LINHA

    # extraindo os dados (chaves sempre maiúsculas)
    chave=$(echo $1 | tr a-z A-Z)
    shift
    valor=$*

    # mostrando chave="valor" na saída padrão
    echo "CONF_$chave=\"$valor\""

done < "$CONFIG"



# Funcao para extrair e exibir a versao do programa
mostrar_versao() {
    local versao=$(grep '^# DATA:' "$0" | head -1 | cut -d '-' -f 2 | sed 's/Versao //')
    echo -n "-Programa: $(basename "$0")"
    echo
    echo "-Versao: $versao"
}

###############################


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
