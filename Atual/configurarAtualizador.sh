#!/bin/bash
#
################################################################################
# configurarAtualizador.sh - realizar a configuracao basica do atualizador
#
# DATA: 03/07/2024 09:53 - Versao 2.8.1
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
# Versão 2.3: Melhoras visuais na configuração.
# Versão 2.4: Ativa recurso de conceder permissoes pelo root toda madrugada na
#             pasta /u/sist/exec
# Versão 2.5: Configurado opção para baixar o compilado corretamente
# Versão 2.6: Novos ajustes de configuração
#
# v2.7 - 19/11/2024 - Luiz Gustavo;
#      - alteracoes na instalação do 'xmlstarlet'
#
# v2.8 - 03/12/2024 - Luiz Gustavo;
#      - Alteracoes de permissao ao criar diretorio /u/sist/logs e /u/sist/controle
#
# v2.8.1 - 15/01/2025 - Luiz Gustavo;
#        - Corrigido linha no código do comando que é salvo no cron
#
# ------------------------------------------------------------------------------
# Objetivo: facilitar o uso do atualizador.
###############################

versao=2.8.1
MENSAGEM_USO="
Programa: $(basename "$0")

--------------------------------------------------------------------------------
                              [OPCOES DISPONIVEIS]

OPCOES NA LINHA DE COMANDO:
    -h, --help      Mostra esta tela de ajuda e sai
    -V, --version   Mostra a versao do programa e sai
MODO DE USAR:
    (em construção - AGUARDE)

--------------------------------------------------------------------------------
"

# Funcao para extrair e exibir a versao do programa
mostrar_versao() {
    echo -e "- Programa: $(basename "$0")"
    echo -e "- Versao..: $versao"
}

###############################

PASTA_AVANCO="/u/rede/avanco"
BATS="/u/bats"
EXEC="/u/sist/exec"
LOG_DIR="/u/sist/logs"
versaoCobol=""
statusOnline="status-online.gnt"
script_atualizador="atualizador"
manual_atualizador="atualizador.1.gz"
url_atualizador="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/programa/atualizador"
url_manual_atualizador="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Manuais/atualizador.1.gz"
url_base_status_online_gnt="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/gnt/"
buscaStatusOnline=""
url_versao_release="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/versao_release.txt"
distro_nome=$(grep '^NAME=' /etc/os-release | cut -d '=' -f 2 | tr -d '"' | awk '{print $1}')
distro_versao=$(grep '^VERSION_ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"' | tr -d '.')
url_xmlStarlet_Debian="https://github.com/ketteiGustavo/atualizador/blob/main/extras/xmlstarlet.Debian"
url_xmlStarlet_Slackware="https://github.com/ketteiGustavo/atualizador/blob/main/extras/xmlstarlet.Slackware"
ulr_verifica_processo="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/extras/verificar-processo"
url_gera_xml="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/extras/gera-xml-por-tag.sh"
url_conv_xml_cte="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/extras/conv-xml-cte.sh"

clear
echo "SERVIDOR UTILIZA: $distro_nome"
tput cup 0 59; echo "$(date +"%d/%m/%Y - %H:%M")"

# Funcao para log de erros
log_erro() {
    echo "[ERRO] $(date +'%d/%m/%Y %H:%M') - $1" >>"$LOG_DIR/registroConfiguracao.log"
}

# Funcao para verificar comandos necessários
checar_comandos() {
    for comando in "$@"; do
        if ! command -v "$comando" &>/dev/null; then
            echo "O COMANDO '$comando' ESTA DESABILITADO NESSE SERVIDOR"
            log_erro "O COMANDO '$comando' ESTA DESABILITADO NESSE SERVIDOR"
        fi
    done
}

# Funcao para verificar qual o cobol usado
verifica_cobol() {
    if command -v cobrun &>/dev/null; then
        resultado=$(cobrun 2>&1)
        versaoCobol=$(echo "$resultado" | sed -n 's/V\([0-9]\+\.[0-9]\+\).*/\1/p')
        inf_versaoCobol="$versaoCobol"
    else
        while true; do
            read -p "INFORME A VERSAO DO COBOL NESSE SERVIDOR: " versao_informada
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
                echo "FAVOR INFORMAR O COBOL CORRETAMENTE!"
                echo "EXEMPLO: '4.0'"
                ;;
            esac
            read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
            clear
        done
    fi
}

if [ ! -d "/u/sist/controle" ]; then
    mkdir -p "/u/sist/controle"
    chmod 777 -R "/u/sist/controle"
    chown avanco.sist "/u/sist/controle"
else
    chmod 777 -R "/u/sist/controle"
    chown avanco.sist "/u/sist/controle"
fi

if [ ! -d "/u/sist/logs" ]; then
    mkdir -p "/u/sist/logs"
    chmod 777 -R "/u/sist/logs"
    chown avanco.sist "/u/sist/logs"
else
    chmod 777 -R "/u/sist/logs"
    chown avanco.sist "/u/sist/logs"
fi

# Testa se o usuario e root.
if [ "$(id -u)" -ne 0 ]; then
    #clear
    tput smso
    echo 'NECESSARIO ESTAR COM O USUARIO ROOT, ACESSO NEGADO !!!'
    echo "AS $(date +'%H:%M:%S') DO DIA $(date +'%d/%m/%Y') HOUVE UMA TENTATIVA DE CONFIGURAR O ATUALIZADOR" >>/u/sist/logs/registroConfiguracao.log
    echo "O USUARIO $USER TENTOU UTILIZAR O CONFIGURADOR" >>/u/sist/logs/registroConfiguracao.log
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

configurar_online() {
    local novo_URL
    local tudo_ok=1
    local verifica_xmlstarlet=$(which xmlstarlet 2>/dev/null)
    verifica_cobol

    cd "$EXEC" || {
        echo "Falha ao acessar diretorio $EXEC"
        log_erro "Falha ao acessar diretorio $EXEC."
        exit 1
    }

    if [ "$versaoCobol" == "4.0" ]; then
        buscaStatusOnline=40
        novo_URL=$url_base_status_online_gnt$buscaStatusOnline$statusOnline
    elif [ "$versaoCobol" == "4.1" ]; then
        buscaStatusOnline=41
        novo_URL=$url_base_status_online_gnt$buscaStatusOnline$statusOnline
    else
        echo "Versao do COBOL invalida."
        log_erro "Versao do COBOL invalida: $versaoCobol."
        exit 1
    fi
    echo "AGUARDE!"
    echo

    if curl -k --output /dev/null --silent --head --fail "$url_atualizador"; then
        echo ""
        echo "INSTALANDO O ATUALIZADOR"
        curl -k -L -# -o "/u/bats/atualizador" "$url_atualizador"
        tudo_ok=0
        echo ""
        chown avanco:sist /u/bats/atualizador
        chmod 777 /u/bats/atualizador
        echo "ATUALIZADOR INSTALADO"
        echo ""
    else
        echo "ERRO: A URL DO ATUALIZADOR NAO ESTA ACESSIVEL."
        log_erro "URL inacessivel: $url_atualizador."
        tudo_ok=1
    fi

    echo
    echo "REALIZANDO ATIVACOES NECESSARIAS DOS DEMAIS SCRIPTS... AGUARDE!"
    echo
    if [ -z "$verifica_xmlstarlet" ] || [ "$verifica_xmlstarlet" == "/u/bats"* ]; then
        if [ "$distro_nome" = "Debian" ]; then
            apt install xmlstarlet -y >/dev/null 2>&1 && echo -e "ATIVADO e CONFIGURADO O XMLSTARLET"
            if [ -f "$BATS/xmlstarlet" ]; then
                rm -rf /u/bats/xmlstarlet >/dev/null
            fi
            tudo_ok=0
        elif [ "$distro_nome" = "Slackware" ]; then
            if [ ! -f "$BATS/xmlstarlet" ]; then
                # Usando o link raw para baixar o binário corretamente
                echo "ATIVANDO O XMLSTARLET"
                echo ""
                curl -L -# -o "/u/bats/xmlstarlet" "https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/extras/xmlstarlet.Slackware"
                chown avanco:sist /u/bats/xmlstarlet
                chmod +x /u/bats/xmlstarlet
                tudo_ok=0
            fi
        else
            echo "VERSAO DE DISTRIBUICAO DESCONHECIDA!!!"
            log_erro "Distribuicao desconhecida: $distro_nome."
        fi
    else
        echo -e "XMLSTARLET ja esta configurado e ativo!"
    fi

    if [ ! -f "$BATS/gera-xml-por-tag.sh" ]; then
        if curl -k --output /dev/null --silent --head --fail "$url_gera_xml"; then
            echo "ATIVANDO O GERA-XML-POR-TAG"
            echo ""
            curl -k -# -o "/u/bats/gera-xml-por-tag.sh" "$url_gera_xml"
            sleep 1
            chown avanco:sist /u/bats/gera-xml-por-tag.sh
            chmod +x /u/bats/gera-xml-por-tag.sh
            tudo_ok=0
        else
            echo "NAO FOI POSSIVEL ACESSAR BAIXAR e INSTALAR O 'gera-xml-por-tag'"
            tudo_ok=1
        fi
    fi

    if [ ! -f "/u/bats/verificar-processo" ]; then
        if curl -k --output /dev/null --silent --head --fail "$ulr_verifica_processo"; then
            echo "ATIVANDO O VERIFICA PROCESSO"
            echo
            curl -# -o "/u/bats/verificar-processo" "$ulr_verifica_processo"
            chmod 777 "/u/bats/verificar-processo"
            sleep 1
            tudo_ok=0
        else
            echo "NAO FOI POSSIVEL ACESSAR BAIXAR e INSTALAR O 'verificar-processo'"
            tudo_ok=1
        fi
    fi

    if [ ! -f "/u/bats/conv-xml-cte.sh" ]; then
        if curl -k --output /dev/null --silent --head --fail "$url_conv_xml_cte"; then
            echo "ATIVANDO O 'conv-xml-cte.sh'"
            echo
            curl -# -o "/u/bats/conv-xml-cte.sh" "$url_conv_xml_cte"
            chmod 777 "/u/bats/conv-xml-cte.sh"
            chown avanco.sist "/u/bats/conv-xml-cte.sh"
            sleep 1
            tudo_ok=0
        else
            echo "NAO FOI POSSIVEL ACESSAR BAIXAR e INSTALAR O 'conv-xml-cte.sh'"
            tudo_ok=1
        fi
    fi


    if [ ! -f "$EXEC/status-online.gnt" ]; then
        if curl -k --output /dev/null --silent --head --fail "$novo_URL"; then
            echo "INSTALANDO O STATUS-ONLINE.gnt"
            curl -k -# -o "/u/sist/exec/status-online.gnt" "$novo_URL"
            tudo_ok=0
            echo ""
            sleep 1
        else
            echo "NAO FOI POSSIVEL BAIXAR e INSTALAR O 'status-online.gnt'"
            tudo_ok=1
        fi
        echo
    fi

    echo
    chown avanco:sist /u/sist/exec/*
    chmod 777 /u/sist/exec/*

    if [ "$tudo_ok" = 0 ]; then
        echo
        echo "FINALIZANDO CONFIGURACAO DO ATUALIZADOR! AGUARDE"
        echo
        echo "CONFIGURACAO REALIZADA!!!"
        echo "LOGUE COMO 'avanco' PARA ATUALIZAR!!!"
        ativar_permissao
        sleep 1
    else
        echo "NAO FOI POSSIVEL FAZER A CONFIGURACAO"
        log_erro "Configuracao falhou."
    fi
    echo
}

ativar_permissao() {
    if [ ! -f /u/sist/controle/bkp_cron.config ]; then
        echo "# BACKUP DO CRONTAB DO ROOT - NAO APAGAR - NAO ALTERAR" >>/u/sist/controle/bkp_cron.config
        crontab -l >>/u/sist/controle/bkp_cron.config
        chmod 666 /u/sist/controle/bkp_cron.config
        cp /u/sist/controle/bkp_cron.config /u/bats
    fi

    if ! crontab -l | grep -q "atualizador --permissoes"; then
        (
            crontab -l
            echo ""
            echo "# ATUALIZADOR AUTOMATICO - CONCEDER PERMISSOES NO SIST/EXEC - NAO REMOVER"
            echo "00 04 * * * /u/bats/atualizador --permissoes 2>> /u/sist/logs/.cron-erro.log"
            echo ""
        ) | crontab -
    fi
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
