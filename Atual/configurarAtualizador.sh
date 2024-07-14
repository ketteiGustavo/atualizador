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
url_baixarAtualizacao="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/baixarAtualizacao"
url_atualizador="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/atualizador"
url_manual_atualizador="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Manuais/atualizador.1.gz"
url_ctrl_ver_rel="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/controle_ver_rel.txt"
url_base_status_online_gnt="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/gnt/"
buscaStatusOnline=""

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


local novo_URL
VERIFICA_COBOL
cd /u/sist/exec
pwd
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

#baixando o programa status-online.gnt
if curl --output /dev/null --silent --head --fail "$novo_URL"; then
    wget -c "$novo_URL" -P "/u/sist/exec"
fi

# baixando o atualizador
if curl --output /dev/null --silent --head --fail "$url_atualizador"; then
    wget -c "$url_atualizador" -P "$PASTA_AVANCO"
fi

# baixando o baixarAtualizacao
if curl --output /dev/null --silent --head --fail "$url_baixarAtualizacao"; then
    wget -c "$url_baixarAtualizacao" -P "$PASTA_AVANCO"
fi

# baixando o manual do Atualizador
if curl --output /dev/null --silent --head --fail "$url_manual_atualizador"; then
    wget -c "$url_manual_atualizador" -P "$PASTA_AVANCO"
fi

# baixando o controle_ver_rel
if curl --output /dev/null --silent --head --fail "$url_ctrl_ver_rel"; then
    wget -c "$url_ctrl_ver_rel" -P "$PASTA_AVANCO"
fi

chown avanco:sist $PASTA_AVANCO/atualizador
chown avanco:sist $PASTA_AVANCO/baixarAtualizacao
chown root:root $PASTA_AVANCO/atualizador.1.gz
chown avanco:sist $PASTA_AVANCO/controle_ver_rel.txt

chmod 755 $PASTA_AVANCO/atualizador
chmod 755 $PASTA_AVANCO/baixarAtualizacao

mv $PASTA_AVANCO/atualizador /u/bats/
mv $PASTA_AVANCO/baixarAtualizacao /u/bats/
mv $PASTA_AVANCO/controle_ver_rel.txt /u/sist/controle/
mv $PASTA_AVANCO/atualizador.1.gz /usr/share/man/man1/
mv /u/sist/exec/$buscaStatusOnline$statusOnline /u/sist/exec/$statusOnline

mandb

chown root:root /u/rede/avanco/configurarAtualizador
chmod 700 /u/rede/avanco/configurarAtualizador

mv /u/rede/avanco/configurarAtualizador /u/bats/


chown avanco:sist /u/sist/exec/*.gnt
chmod 777 /u/sist/exec/*.gnt


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