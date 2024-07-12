#!/bin/bash
#
################################################################################
# configurarAtualizador.sh - realizar a configuracao basica do atualizador
#
# DATA: 03/07/2024 09:53 - Versao 1
#
# ------------------------------------------------------------------------------
# Autor: Luiz Gustavo <luiz.gustavo@avancoinfo.com.br>
#                     <luizgcesar@gmail.com.br>
# site: https://github.com/ketteiGustavo
# ------------------------------------------------------------------------------
# Versao 1: realizar a configuracao de forma correta
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
arquivos=""
BATS="/u/bats"
EXEC="/u/sist/exec"
versaoCobol=""
statusOnline="status-online.gnt"
script="atualizador"
script_baixar_atualizacao="baixarAtualizacao"

# Funcao para verificar qual o cobol usado
VERIFICA_COBOL() {
    # Rebece as informacoes a funcao LER_ARQUIVO_TEXTO
    RESULTADO=$(cobrun 2>&1)
    if [[ $RESULTADO =~ V([0-9]+\.[0-9]+) ]]; then
        versaoCobol="${BASH_REMATCH[1]}"
        echo "Versao do Cobol: $versaoCobol"
    fi
}

# Testa se o usuario e root.
if [ "$USER" != "root" ]; then
    #clear
    tput smso
    echo 'NECESSARIO ESTAR COM O USUARIO ROOT, ACESSO NEGADO !!!'
    tput rmso
    exit
else
    echo "INICIANDO A CONFIGURACAO"
fi



arquivos=$(find "$PASTA_AVANCO" -type f -name "atualizador.rar")
if [[ -f $arquivos ]]; then
    VERIFICA_COBOL
    cd /u/sist/exec
    pwd
    echo "Pacote de configuracao encontrado"
    echo ""
    # Verificando a versao do COBOL
    if [ "$versaoCobol" == "4.0" ]; then
        rar e "$arquivos" "40$statusOnline" -o+ -y
        mv 40$statusOnline $statusOnline
    elif [ "$versaoCobol" == "4.1" ]; then
        rar e "$arquivos" "41$statusOnline" -o+ -y
        mv 41$statusOnline $statusOnline
    else
        echo "Versao do COBOL invalida."
        exit 1
    fi

    chown avanco:sist /u/sist/exec/*.gnt
    chmod 777 /u/sist/exec/*.gnt

    if [ $? -eq 0 ]; then
        echo "Programa '$statusOnline extraido com sucesso"
    else
        echo "Falha ao extrair"
    fi
    echo ""
    cd /u/bats
    pwd
    rar e "$arquivos" "$script" -o+ -y
    if [ $? -eq 0 ]; then
        echo "'$script extraido com sucesso"
        chown avanco:sist /u/bats/$script
        chmod 700 /u/bats/$script
    else
        echo "Falha ao extrair"
    fi

    rar e "$arquivos" "$script_baixar_atualizacao" -o+ -y
    if [ $? -eq 0 ]; then
        echo "'$script_baixar_atualizacao extraido com sucesso"
        chown avanco:sist /u/bats/$script_baixar_atualizacao
        chmod 766 /u/bats/$script_baixar_atualizacao
    else
        echo "Falha ao extrair"
    fi
    
    chmod 700 /u/rede/avanco/configurarAtualizador.sh
    chown root:root /u/rede/avanco/configurarAtualizador.sh
    mv /u/rede/avanco/configurarAtualizador.sh /u/bats/


else
    echo "Favor colar na pasta '/u/rede/avanco' o pacote 'atualizador.rar'"
    exit
fi

# executar mandb

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
su - avanco