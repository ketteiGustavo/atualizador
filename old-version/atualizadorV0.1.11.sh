#!/bin/bash
#
################################################################################
# atualizador - Programa para atualizar o sistema Integral
#
# DATA: 13/04/2024 11:27 - Versao 0.1.11
# -------------------------------------------------------------------------------
# Autor: Luiz Gustavo <luiz.gustavo@avancoinfo.com.br>
# -------------------------------------------------------------------------------
# Versao 0: Programa de atualizacao automatica.
# Versao 0.0.1: Logica do programa ajustada para gravar versao e release apos
#               execucao completa da atualizacao
# Versao 0.0.2: Logica para obter links de releases corrigidos
# Versao 0.0.3: Comandos rar sao exibidos com porcentagem em tela
# Versao 0.0.4: Criado teste para os arquivos baixados
# Versao 0.0.5: Criado teste para validar usuarios logados
# Versao 0.0.6: Validacao do Online, atraves do status-online.gnt
# Versao 0.0.7: Melhora na parte visual com porcentagens nos progressos
# Versao 0.0.8: Confirmacao de iniciar atualizacao, para evitar caso seja acio-
#               nado acidentamente.
# Versao 0.0.9: Desativado validacao de usuarios logados.
# Versao 0.0.10: Novos recursos e opcoes para linha de comando.
# Versao 0.1.0:  Diversas correcoes e melhorias.
#                Dentre elas melhor logica para obter os links atuais.
# Versao 0.1.1: Leitura apenas de versao e release atuais, garantindo velocidade
#               de execucao.
# Versao 0.1.2: Criado opcoes de leitura de logs pela linha de comando
# Versao 0.1.3: Opcao de restauracao implementada
# Versao 0.1.4: Criado log de auditoria
# Versao 0.1.5: Funcao de parametrizacao, para executar o atualizador de acordo
#               com o que for predefinido pelo usuario.
# Versão 0.1.6: Alterações para instalar o 'xmlstarlet' e 'gera-xml-por-tag.sh'
#               de acordo com o que foi pedido pelo Ronaldo
# Versão 0.1.7: Correções para funcionar em slackware, opções de curl
# Versão 0.1.8: Função para conceder permissão de madrugada.
# Versão 0.1.9: Novos menus e submenus
# Versão 0.1.10: Ativando recursos de cores visuais somente em terminais que
#                aceitam cores
# Versão 0.1.11: Opção para conceder permissão somente pelo usuário avanço
#
# -------------------------------------------------------------------------------
# Este programa ira atualizar o Sistema Integral respeitando a versao do cobol e
# instalando versao e a release mais recentes. Apos isso ira executar o atu-help
# manual e dar permissao em /u/sist/exec/*gnt.
# O objetivo desse Programa e facilitar o dia-a-dia do clinte usuario Avanco!
################################################################################
#
versaoPrograma="0.1.11"
distro_nome=$(grep '^NAME=' /etc/os-release | cut -d '=' -f 2 | tr -d '"' | awk '{print $1}')
manual_uso="
Programa: $(basename "$0")

--------------------------------------------------------------------------------
                              [OPCOES DISPONIVEIS]                              

OPCOES NA LINHA DE COMANDO:
    -h,  --help      Mostrar tela de ajuda.
    -V,  --version   Mostrar versao do Atualizador
    -b,  --baixar    Baixar atualizacoes do Integral
    -up, --update    Realizar update do Atualizador
    -m,  --menu      Menu interativo

MODO DE USAR:
Digite o nome do programa e a opcao desejada.
  Exemplo:
  atualizador --help
  'Exibir tela de ajuda.'

--------------------------------------------------------------------------------
"

guia_erros="
    Elaborar ainda.
"

avanco="
                                                          ##                    
                                                        ####                    
                                                      ######                    
                                                    ########                    
                        ------------              ##########                    
                      ------                    ############                    
                    ------                    ##############                    
                      ----                  ################                    
                      ----                ########  ########                    
                        ----            ########    ########                    
                          ----       #########      ########                    
                            --    ########          ########                    
                              --########            ########                    
                              ##----                  ######                    
                            ######----                ######                    
                          ####        ----            ######                    
                        ####              --                                    
                      ####                    --                                
                    ##                            --                            
                  ##                                    --                      
                                                                                
                                                                                
                                                                                
     ##         ##  ##         ##         ##    ##        #####        #####
   ##  ##       ##  ##       ##  ##       ####  ##       ##          ##    ##
   ##  ##       ##  ##       ##  ##       ##  ####       ##          ##    ##
   ##  ##         ##         ##  ##       ##    ##        #####       #####
"

###############################
# Variaveis globais
info_loja_txt="/u/sist/controle/info_loja.txt"
controle_ver_rel="/u/sist/controle/versao_release.txt"

dia_semana_lido=$(date +%u)
hora_lida=$(date +%H)
contauser=$(ps ax | grep rts32 | grep -v 'grep' | wc -l)
programa_validar="rts32"
usuarios_permitidos=("root" "super" "avanco")

# datas
mes_ano=$(date +"%m%y")
mes_atual=$(date +"%m")
ano_atual=$(date +"%y")

date=$(date +"%d%m%y")

mes_anterior=$(date -d "4 weeks ago" +"%m")
ano_anterior=$(date -d "4 weeks ago" +"%y")

# Locais dentro do sevidor
local_gnt="/u/sist/exec"
pasta_avanco="/u/rede/avanco"
removidos="$pasta_avanco/removidos"
pasta_destino="/u/rede/avanco/atualizacoes"

arquivo_versao_atual=""
arquivo_release_atual=""

local_log="/u/sist/logs" # arquivo de log
bkp_destino="/u/sist/exec-a"

# Arquivos de log para consulta.
teste_gnt_log="/u/sist/logs/testeGNT.log"
validados_gnt="/u/sist/logs/statusGNT.log"

infos_extras="/u/sist/logs/infos_extras.log"
auditoria="/u/sist/logs/auditoria.log"

# Arquivo de log
log_file="/u/sist/logs/log_$mes_ano.log"
# Arquivo de log de erro
erro_log_file="/u/sist/logs/erro_$mes_ano.log"

log_cron_erro="/u/sist/logs/.cron-erro.log"

# arquivo de pre leitura
controle_servidor="/u/sist/controle"
arquivo_parametros="$controle_servidor/parametros.txt"
config_cron="$controle_servidor/.config_cron.txt"

script_baixar_atualizacao="/u/bats/baixarAtualizacao"

# Parte web - Links

script_url="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/atualizador"
script_path="$0"
url_controle_versao_release="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/controle_ver_rel.txt"
url_versao_release="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/versao_release.txt"
url_gera_xml="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/extras/gera-xml-por-tag.sh"
url_xmlStarlet_Debian="https://github.com/ketteiGustavo/atualizador/blob/main/extras/xmlstarlet.Debian"
url_xmlStarlet_Slackware="https://github.com/ketteiGustavo/atualizador/blob/main/extras/xmlstarlet.Slackware"


versaoCobol="" # usada para armazenar o cobol, apos rodar cobrun integral

# trabalhando as variaveis que receberao datas que sao baseada em datas
novoPortal="" # responsavel por obter a atual versao no site e ser usada para comparacoes
novoPortalPosRelease=""
releasePortal="" # armazenara a data da release (precisa validar, pois nao havia release disponivel no dia do teste)
letraRelease=""  # cada release e unica, tem uma letra propria, aqui ficara essa informacao
versaoLoja=""    # usada para obter a versao no servidor do cliente
releaseLoja=""   # usada para obter a release no servidor do cliente
inf_versao=""
inf_release="" # usada para obter a release digitada

inf_versaoCobol=""
inf_versaoLoja=""
inf_releaseLoja=""
inf_releaseLojaAntes=""
dia=""
mes=""
ano=""
data_release_servidor=""
data_release_baixar=""
data_release=""
cronometro_start=$(date +'%H:%M:%S')
cronometro_start_volta=""
cronometro_stop=""
cronometro_stop_volta=""
tempo_gasto=""
atualizado_flag=""
controle_flag="/u/sist/controle"
flag_versao=false
flag_release=false
flag_esta_atualizado=false
flag_renomea=false
flag_load_parametros=false
flag_pacote_descompactado=false
olhar_online=false
fim_atualizacao=false
local_abortado=""
abortado_controle=""

resultado="" # armazena a saida do comando cobrun, para separar somente a versao 4.0 ou 4.1

data_atual=$(date +"%d%m%y")   # data obtida ao rodar o script, sera sempre o dia atual
hora_atual=$(date +"%H:%M:%S") # hora para gravacoes necessarias
dia_hoje=$(date +"%Y%m%d")

################################################################################
### Inicio das Funções - serão dividas em blocos
#
### VISUAL - necessários ter a chave $USAR_CORES ativa
# exibi mensagens de erro em vermelho

testar_cores() {
    if [ "$(tput colors)" -ge 8 ]; then
        USAR_CORES=1
    else
        USAR_CORES=0
    fi
}
################################################################################
## Criando opcoes visuais
## Cores
readonly red='\e[1;91m'
readonly green='\e[1;92m'
readonly yellow='\e[1;93m'
readonly blue='\e[1;94m'
readonly magenta='\e[1;95m'
readonly cyan='\e[1;96m'
readonly no_color='\e[0m'

################################################################################
# exibe mensagens de erro em vermelho
erro_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${red}[ERROR] - $1${no_color}"
    else
        echo "[ERROR] - $1"
    fi
}
# exibi mensagens de informacao em verde
info_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${green}[INFO] - $1${no_color}"
    else
        echo "[INFO] - $1"
    fi
}
# exibi mensagens de alerta em amarelo
alerta_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${yellow}[ALERTA] - $1${no_color}"
    else
        echo "[ALERTA] - $1"
    fi
}
# exibe mensagens em vermelho
red_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${red}$1${no_color}"
    else
        echo "$1"
    fi
}
# exibi mensagens em verde
green_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${green}$1${no_color}"
    else
        echo "$1"
    fi
}
# exibi mensagens em amarelo
yellow_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${yellow}$1${no_color}"
    else
        echo "$1"
    fi
}
# exibi mensagens em azul
blue_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${blue}$1${no_color}"
    else
        echo "$1"
    fi
}
# exibi mensagens em magenta
magenta_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${magenta}$1${no_color}"
    else
        echo "$1"
    fi
}
# exibi mensagens em ciano
cyan_mgs() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${cyan}$1${no_color}"
    else
        echo "$1"
    fi
}
#

mensagem_saida() {
    tput smso
    echo ""
    echo "                               AVANCO INFORMATICA                               "
    echo ""
    echo "                           TELESUPORTE (31) 3025-1188                           "
    echo ""
    echo "                                   TELEGRAM                                     "
    echo ""
    echo "                           t.me/avancoinformatica_bot                           "
    tput rmso
    stty sane
}

### SEGURANÇA E VALIDAÇÕES
#
conceder_permissao() {
    local nivel_permissao=$1
    local local_permissao=$2
    case $nivel_permissao in
    "t" | "T")
        chmod 777 "$local_permissao" || {
            erro_msg "ERRO AO CONCEDER PERMISSAO TOTAL."
            echo "Erro ao conceder permissoes! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
        }
        chown avanco:sist "$local_permissao" || {
            erro_msg "ERRO AO DEFINIR COMO: 'avanco:sist'"
            echo "Erro ao definir 'dono' e 'grupo'! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
        }
        ;;
    "rw" | "RW")
        chmod 666 "$local_permissao" || {
            erro_msg "ERRO AO CONCEDER PERMISSAO TOTAL."
            echo "Erro ao conceder permissoes! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
        }
        chown avanco:sist "$local_permissao" || {
            erro_msg "ERRO AO DEFINIR COMO: 'avanco:sist'"
            echo "Erro ao definir 'dono' e 'grupo'! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
        }
        ;;
    *)
        echo "PERMISSAO INVALIDA"
        echo "USE 't' para total(777) ou 'rw' para leitura/escrita(666)"
        ;;
    esac
}
# ------------------------------------------------------------------------------

interromper() {
    echo -e "\nPROCESSO INTERROMPIDO!"
    echo -e "\nDESEJA REALMENTE ABORTAR? [S/n]"
    read -n 1 answer
    answer=$(echo "$answer" | tr '[:lower:]' '[:upper:]')
    if [[ $answer == "S" ]]; then
        echo -e "\nSAINDO!!!"
        echo "" >>$auditoria
        echo "################################################################################" >>$auditoria
        echo "" >>$auditoria
        echo "ROTINA ABORTADA" >>$auditoria
        echo "DIA: $(date +'%d/%m/%Y')" >>$auditoria
        echo "HORA: $(date +'%H:%M:%S')" >>$auditoria
        echo "USUARIO: $USER" >>$auditoria
        echo "ABORTADO EM: $local_abortado" >>$auditoria
        echo "" >>$auditoria
        if [ "$flag_renomea" = true ]; then
            mv /u/sist/exec/cogumeloAzul.gnt /u/sist/exec/integral.gnt
        fi
        echo
        if [[ "$abortado_controle" == "seguranca" ]]; then
            rm -f "$teste_gnt_log"
            rm -f "$validados_gnt"
        fi

        if [[ "$abortado_controle" == "descompactar" ]]; then
            echo "restaurando"
        fi

        if [[ "$abortado_controle" == "download" ]]; then
            rm -rf /u/rede/avanco/atualizacoes/versao*
            rm -rf /u/rede/avanco/atualizacoes/release*
        fi

        exit 0
    else
        echo -e "\nCONTINUANDO..."
    fi

}

trap 'interromper' SIGINT SIGTERM SIGHUP

validar_linux() {
    local_abortado="Validacao LINUX"
    if [ ! -e /etc/debian_version ]; then
        clear
        echo -e "FAVOR ACIONAR O SETOR DE TECNOLOGIA E O ADMINISTRATIVO PARA AGENDAR \nA ATUALIZACAO DO SISTEMA OPERACIONAL DO SEU SERVIDOR."
        #echo "ATUALIZADOR CONFIGURADO PARA SERVIDORES DEBIAN"
        sleep 2
        #exit
    fi
}

ativar_desativar_online() {
    if [[ "$olhar_online" = "true" ]]; then
        status_ON=$(cobrun status-online.gnt "L") >/dev/null 2>&1

        if [ "$status_ON" = "ATIVADO" ]; then
            cobrun status-online.gnt "D" >/dev/null
        fi
    fi

    if [[ "$fim_atualizacao" = "true" ]] && [[ "$olhar_online" = "true" ]]; then
        cobrun status-online.gnt "A" >/dev/null
    fi
}

iniciar() {
    local_abortado="Inicio da atualizacao"
    while true; do
        read -p "DESEJA INICIAR A ATUALIZACAO? [S/n] " confirma_inicio

        case $confirma_inicio in
        "S" | "s")
            echo "Atualizador Integral"
            if [ "$flag_load_parametros" = true ] && [[ "$logar_atualizando" == "N" ]]; then
                mv /u/sist/exec/integral.gnt /u/sist/exec/cogumeloAzul.gnt
                flag_renomea=true
                olhar_online=true
                ativar_desativar_online
            fi
            clear
            sleep 1
            ler_arquivo_texto
            break
            ;;
        "N" | "n")
            clear
            mensagem_saida
            exit 0
            ;;
        *)
            clear
            echo "Entrada invalida, confirme com (S) para sim ou (N) para nao"
            validar_ver_rel
            ;;
        esac
    done
}

usuario_permitido() {
    local usuario_atual="$USER"
    local permitido_att=false
    if [[ "$todos_autorizados" == "S" ]]; then
        echo "TODOS USUARIOS PODEM ATUALIZAR" >/dev/null
        return 0
    elif [[ "$todos_autorizados" == "N" ]]; then
        for user in "${usuarios_permitidos[@]}"; do
            if [[ "$user" == "$usuario_atual" ]]; then
                permitido_att=true
                break
            fi
        done

        IFS=' '
        read -r -a lista_autorizados <<<"$autorizados"

        for user in "${lista_autorizados[@]}"; do
            if [[ "$user" == "$usuario_atual" ]]; then
                permitido_att=true
                break
            fi
        done

        if [[ "$permitido_att" = false ]]; then
            echo "ESTE USUARIO NAO TEM PERMISSAO DE EXECUTAR ESSA ROTINA"
            echo "" >>$auditoria
            echo "AS $(date +'%H:%M:%S') DO DIA $(date +'%d/%m/%Y')" >>$auditoria
            echo "O USUARIO $USER TENTOU EXECUTAR UMA ACAO NAO LIBERADA" >>$auditoria
            exit 1
        fi
    fi
}

# funcao para verificar se o sistema foi atualizado no dia
verifica_atualizacao() {
    local_abortado="Verificando atualizacao"
    ler_arquivo_texto
    if [ -f "$info_loja_txt" ]; then
        ultima_atu=$(grep "DATA RELEASE: " "$info_loja_txt" | cut -d ' ' -f 2)
        if [ "$ultima_atu" == "$(date +'%d%m%y')" ] || [ "$flag_esta_atualizado" = true ]; then

            clear
            tput smso
            echo "                           O INTEGRAL ESTA ATUALIZADO                           "
            tput rmso
            stty sane
            mensagem_saida

            echo "" >>$auditoria
            echo "AS $(date +'%H:%M:%S') DO DIA $(date +'%d/%m/%Y')" >>$auditoria
            echo "INTEGRAL ESTAVA ATUALIZADO NA TENTATIVA DE ATUALIZACAO" >>$auditoria
            echo "USUARIO: $USER" >>$auditoria
            sleep 2
            exit 0
        else
            echo "Atualizando..." >/dev/null
            cronometro_start_volta=$SECONDS
        fi
    fi
}

notificar_usuarios() {
    while true; do
        for usuario in $(who | awk '{print $1}' | sort | uniq); do
            if [[ ! " ${usuarios_permitidos[@]} " =~ " ${usuario} " ]]; then
                if ps -u $usuario -o cmd --no-headers | grep -q "$programa_validar"; then
                    echo -e "Favor encerrar sua sessao. O Integral sera atualizado em breve. \nAperte 'ESC' ate sair do INTEGRAL! \nDIGITE 10 para voltar a linha de comando! \nDEPOIS DIGITE 'exit'" | wall
                fi
            fi
        done
        sleep 5
    done
}

usuarios_usando_programa() {
    ps ax -o user=,cmd= | grep "$programa_validar" | grep -v 'grep' | awk '{print $1}' | sort | uniq
}

contar_usuarios_usando_programa() {
    ps ax | grep "$programa_validar" | grep -v 'grep' | wc -l
}

verifica_logados() {
    local_abortado="Verificando usuarios logados"
    if [[ "$flag_load_parametros" == "true" ]] && [[ "$deslogar_usuarios" == "S" ]]; then
        notificar_usuarios &
        NOTIFICAR_PID=$!

        # Esperar até que todos os usuários saiam
        while true; do
            if [ $(contar_usuarios_usando_programa) -eq 0 ]; then
                clear
                kill $NOTIFICAR_PID
                wait $NOTIFICAR_PID 2>/dev/null
                echo "NENHUM USUARIO LOGADO. INICIANDO A ATUALIZACAO DO SERVIDOR..."
                break
            fi
            clear
            echo "USUARIOS COM O INTEGRAL ABERTO: "
            usuarios_usando_programa
            echo "AGUARDANDO OS USUARIOS ENCERRAREM SUAS SESSOES..."
            sleep 5
        done
    elif [[ "$flag_load_parametros" == "true" ]] && [[ "$deslogar_usuarios" == "N" ]]; then
        #echo "flag: $flag_load_parametros e usuario: $deslogar_usuarios"
        echo "" >/dev/null
    elif [[ "$flag_load_parametros" == "false" ]]; then
        #echo "flag: $flag_load_parametros e usuario: $deslogar_usuarios"
        echo "" >/dev/null
    else
        echo "" >/dev/null
    fi
}

# Funcao para verificar o dia da semana e hora
verificar_dia() {
    local_abortado="Validando dia"
    if [ $dia_semana_lido -eq 5 ] || [ $dia_semana_lido -eq 6 ] || [ $dia_semana_lido -eq 7 ]; then
        clear
        tput smso
        echo "                     O SISTEMA NAO PODE SER ATUALIZADO HOJE!                     "
        echo ""
        echo "                        TENTE NOVAMENTE NA SEGUNDA-FEIRA!                        "
        tput rmso
        stty sane
        mensagem_saida
        echo "" >>$auditoria
        echo "AS $(date +'%H:%M:%S') DO DIA $(date +'%d/%m/%Y')" >>$auditoria
        echo "HOUVE TENTATIVA DE ATUALIZAR INTEGRAL NO FIM DE SEMANA" >>$auditoria
        echo "REALIZADA PELO USUARIO: $USER" >>$auditoria
        exit 0
    fi

    if [ $hora_lida -gt 18 ]; then
        clear
        tput smso
        echo "               FAVOR EXECUTAR A ATUALIZACAO EM HORARIO COMERCIAL!               "
        echo ""
        tput rmso
        stty sane
        mensagem_saida
        echo "" >>$auditoria
        echo "AS $(date +'%H:%M:%S') DO DIA $(date +'%d/%m/%Y')" >>$auditoria
        echo "HOUVE TENTATIVA DE ATUALIZAR INTEGRAL EM HORARIO NAO PERMITIDO" >>$auditoria
        echo "REALIZADA PELO USUARIO: $USER" >>$auditoria
        exit 0
    fi

    if [ $dia_semana_lido -eq 4 ] && [ $hora_lida -ge 18 ]; then
        clear
        tput smso
        echo "         RECOMENDAMOS ATUALIZAR NA 'SEGUNDA-FEIRA',  DEVIDO AO HORARIO!         "
        echo ""
        echo "                         BOM TARDE E BOM FIM DE SEMANA                          "
        tput rmso
        stty sane
        mensagem_saida
        echo "" >>$auditoria
        echo "AS $(date +'%H:%M:%S') DO DIA $(date +'%d/%m/%Y')" >>$auditoria
        echo "HOUVE TENTATIVA DE ATUALIZAR INTEGRAL EM HORARIO NAO PERMITIDO" >>$auditoria
        echo "REALIZADA PELO USUARIO: $USER" >>$auditoria
        exit 0
    fi
    sleep 3
}

# Criando diretorio de logs e atualizacoes
if [ ! -d "/u/rede/avanco/atualizacoes" ]; then
    mkdir -p "/u/rede/avanco/atualizacoes"
    chmod 777 -R "/u/rede/avanco/atualizacoes"
fi

# Criando diretorio de logs e atualizacoes
if [ ! -d "$removidos" ]; then
    mkdir -p "$removidos"
    chmod 777 -R "$removidos"
fi

if [ ! -d "/u/sist/controle" ]; then
    mkdir -p "/u/sist/controle"
    chmod 766 -R "/u/sist/controle"
fi

if [ ! -d "/u/sist/logs" ]; then
    mkdir -p "/u/sist/logs"
    chmod 766 -R "/u/sist/logs"
fi

if [ ! -f "/u/sist/logs/log-de-remocao.log" ]; then
    echo "                          Controle de Backups Removidos                         " >/u/sist/logs/log-de-remocao.log
    echo "      DATA        -    HORA   -             DIRETORIO                           " >>/u/sist/logs/log-de-remocao.log
fi

if [ ! -f "$log_file" ]; then
    echo "--------------------------------------------------------------------------------" >"$log_file"
    echo "                      CONTROLE DE LOGS DE ACOES EXECUTADAS                      " >>"$log_file"
    echo "--------------------------------------------------------------------------------" >>"$log_file"
fi

if [ ! -f "$auditoria" ]; then
    echo "--------------------------------------------------------------------------------" >"$auditoria"
    echo "               CONTROLE DE LOGS DE ACOES EXECUTADAS INDEVIDAMENTE               " >>"$auditoria"
    echo "--------------------------------------------------------------------------------" >>"$auditoria"
fi

if [ ! -f "/u/sist/logs/infos_extras.log" ]; then
    echo "               CONTROLE DE DESEMPENHO DO ATUALIZADOR NO SERVIDOR                " >"/u/sist/logs/infos_extras.log"
    echo " DIA DA ATUALIZACAO -    HORA INICIAL    -    HORA FINAL    -    TEMPO GASTO    " >>"/u/sist/logs/infos_extras.log"
fi

rm -rf /u/rede/avanco/atualizacoes/versao*
rm -rf /u/rede/avanco/atualizacoes/release*

# Funcao para verificar permissao e grupo dos programas .gnt
seguranca() {
    local_abortado="Processo de validacao de permissoes"
    abortado_controle="seguranca"

    sleep 1
    gnt_files=($(find "$local_gnt" -name "*.gnt"))

    #if [ ! -s "$teste_gnt_log" ]; then
    #    rm "$teste_gnt_log"
    #fi

    #if [ -f "$teste_gnt_log" ] && [ "$(date -r "$teste_gnt_log" +%Y%m%d)" = "$dia_hoje" ]; then
    #    mapfile -t gnt_files <"$teste_gnt_log"
    #else
    #    gnt_files=($(find "$local_gnt" -name "*.gnt"))
    #fi

    if [ ${#gnt_files[@]} -eq 0 ]; then
        echo "Nenhum arquivo '.gnt' encontrado no diretorio '$local_gnt'." >/dev/null
        if [ "$flag_renomea" = true ]; then
            mv /u/sist/exec/cogumeloAzul.gnt /u/sist/exec/integral.gnt
        fi
        exit 1
    fi

    all_valide=true
    total_files_teste=${#gnt_files[@]}
    contagem_gnt=0

    >"$teste_gnt_log"

    for file in "${gnt_files[@]}"; do
        clear
        contagem_gnt=$((contagem_gnt + 1))
        porc_gnt=$((contagem_gnt * 100 / total_files_teste))
        echo "validando os programas... ($porc_gnt%)"
        permissions=$(stat -c "%a" "$file")
        if [ "$permissions" -ne 777 ]; then
            alerta_msg "O programa $file nao tem permissao total!"
            echo "O programa $file nao tem permissao total!" >>$validados_gnt
            alerta_msg "SERA NECESSARIO CONCEDER PERMISSAO TOTAL!!!"
            #all_valide=false
            echo "$file" >>"$teste_gnt_log"
        fi

        dono=$(stat -c "%U %G" "$file")

        if [ "$dono" != "avanco sist" ]; then
            alerta_msg "O programa $file nao esta com o usuario: avanco e o grupo: sist."
            echo "O programa $file nao esta com o usuario: avanco e o grupo: sist." >>$validados_gnt
            alerta_msg "Favor acionar o suporte Avanco!"
            #all_valide=false
            echo "$file" >>"$teste_gnt_log"
        fi
    done

    if [ "$all_valide" = true ]; then
        info_msg "INICIANDO A ATUALIZACAO!"
        rm -f "$teste_gnt_log"
        rm -f "$validados_gnt"
    else
        alerta_msg "E necessario acionar o suporte Avanco para executar as permissoes"
        if [ "$flag_renomea" = true ]; then
            mv /u/sist/exec/cogumeloAzul.gnt /u/sist/exec/integral.gnt
        fi
        sleep 1
        exit 1
    fi
}

# Funcao para testar e verificar sinal e qualidade da internet
checar_internet() {
    local_abortado="Checando a Internet"
    # Endereço para pingar (Google DNS)
    local host="8.8.8.8"

    # Pingar o endereço 4 vezes e capturar a saída
    ping_output=$(ping -c 4 $host)
    ping_exit_status=$?

    # Verificar se o comando ping teve sucesso
    if [ $ping_exit_status -eq 0 ]; then
        # Extrair os tempos de resposta
        rtt_min=$(echo "$ping_output" | grep "rtt" | awk -F'/' '{print $4}')
        rtt_avg=$(echo "$ping_output" | grep "rtt" | awk -F'/' '{print $5}')
        rtt_max=$(echo "$ping_output" | grep "rtt" | awk -F'/' '{print $6}')

        echo "CONEXAO COM A INTERNET OK"
        #echo "TEMPO DE RESPOSTA (ms):"
        #echo "MINIMO: $rtt_min"
        #echo "MEDIO: $rtt_avg"
        #echo "MAXIMO: $rtt_max"

        # Verificar se a conexão está lenta ou instável
        if (($(echo "$rtt_avg > 100" | bc -l))); then
            echo "AVISO: A CONEXAO ESTA LENTA"
        fi
        if (($(echo "$rtt_max - $rtt_min > 100" | bc -l))); then
            echo "AVISO: A CONEXAO ESTA INSTAVEL"
        fi
    else
        # Mensagem de erro centralizada
        clear
        tput cup $(($(tput lines) / 2)) $(($(tput cols) / 2 - 20))
        echo "NAO HA CONEXAO COM A INTERNET"
        exit 1
    fi
}

# funcao para validar data
validar_data() {
    data_verificada=$(date -d "$1" +"%d%m%y" 2>/dev/null)
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Funcao para criar o arquivo 'info_loja.txt'
criar_info_loja() {
    local_abortado="Criando arquivo de versao e release"
    data_configuracao=$(date +'%d/%m/%Y')

    while true; do
        verifica_cobol

        # loop para validar versao
        while true; do
            read -p "Informe a VERSAO ATUAL do Integral: (DDMMAA) " inf_versaoLoja
            if validar_data "$inf_versaoLoja"; then
                if [[ ! "$inf_versaoLoja" =~ ^[0-9]{6}$ ]]; then
                    clear
                    erro_msg "VERSAO INFORMADA INVALIDA! POR FAVOR, DIGITE NOVAMENTE (DDMMAA)"
                else
                    break
                fi
            else
                clear
                erro_msg "VERSAO INFORMADA INVALIDA! POR FAVOR, DIGITE NOVAMENTE (DDMMAA)"
            fi
        done

        # loop para validar release
        while true; do
            read -p "Informe a RELEASE ATUAL do Integral (se nao existir deixe em branco): " inf_releaseLoja
            inf_releaseLoja=$(echo "$inf_releaseLoja" | tr '[:lower:]' '[:upper:]')
            if [[ ! "$inf_releaseLoja" =~ ^[A-Z]$ ]] && [ ! -z "$inf_releaseLoja" ]; then
                clear
                erro_msg "RELEASE INVALIDA. A RELEASE DEVE CONTER E SER APENAS UMA LETRA OU VAZIA SE NAO EXISTIR!"
            else
                break
            fi
        done

        while true; do
            clear
            echo
            echo "VERSAO COBOL: $inf_versaoCobol"
            echo "VERSAO INTEGRAL: $inf_versaoLoja"
            echo "RELEASE INTEGRAL: $inf_releaseLoja"
            echo
            read -p "CONFIRMA AS INFORMACOES FORNECIDAS? [S/n] " confirmar_infos

            case $confirmar_infos in
            "S" | "s")
                echo "GRAVANDO INFORMACOES. AGUARDE..."
                sleep 2
                clear
                break 2
                ;;
            "N" | "n")
                clear
                echo "INFORME NOVAMENTE A VERSAO E RELEASE."
                break
                ;;
            *)
                echo "Entrada invalida, confirme com (S) para sim ou (N) para nao"
                ;;
            esac
        done
    done

    echo
    echo "DATA: $data_configuracao" >"$info_loja_txt"
    echo "VERSAO COBOL: $inf_versaoCobol" >>"$info_loja_txt"
    echo "VERSAO INTEGRAL: $inf_versaoLoja" >>"$info_loja_txt"
    echo "RELEASE: $inf_releaseLoja" >>"$info_loja_txt"
    inf_releaseLojaAntes="$inf_releaseLoja"
    echo "DATA RELEASE: " >>"$info_loja_txt"
}

# Funcao para ler o arquivo 'info_loja_txt'
ler_arquivo_texto() {
    local_abortado="Lendo arquivo de versao e release"
    # verifica se o arquivo existe
    if [ ! -f "$info_loja_txt" ]; then
        echo "FAVOR INFORMAR A VERSAO E RELEASE QUE ESTAO NESSE SERVIDOR!" 2> >(tee -a "$erro_log_file")
        criar_info_loja
        return 1
    else
        inf_data=$(grep -oP '(?<=DATA: )\d+/\d+/\d+' "$info_loja_txt")
        inf_versaoCobol=$(grep -oP '(?<=VERSAO COBOL: )\d+.\d+' "$info_loja_txt")
        versaoCobol="$inf_versaoCobol"
        inf_versaoLoja=$(grep -oP '(?<=VERSAO INTEGRAL: )\d+' "$info_loja_txt")
        inf_releaseLoja=$(grep -oP '(?<=RELEASE: )[[:alpha:]]' "$info_loja_txt")
        inf_releaseLojaAntes="$inf_releaseLoja"
        data_release_servidor=$(grep -oP '(?<=DATA RELEASE: )\d+' "$info_loja_txt")
    fi
    validar_ver_rel
}

# Funcao para verificar qual o cobol usado
verifica_cobol() {
    resultado=$(cobrun 2>&1)
    versaoCobol=$(echo "$resultado" | sed -n 's/V\([0-9]\+\.[0-9]\+\).*/\1/p')
    inf_versaoCobol="$versaoCobol"
}

# Funcao para limpar qualquer arquivo ou pasta que esteja errado no sist/exec
limpa_exec() {
    local_abortado="Limpando sist/exec"
    local data_clear=$(date +'%d/%m/%Y')
    local rar_file="$removidos/removidos_$data_atual.rar"
    echo "Arquivos e Pastas que estavam no 'u/sist/exec' no dia $data_clear" >"/u/sist/logs/removidos_$data_atual.log"
    for item in "$local_gnt"/*; do
        # valida se e um programa gnt
        if [[ ! "$item" =~ \.gnt$ ]]; then
            echo "Arquivo/Pasta encontrado -> $item" >>"/u/sist/logs/removidos_$data_atual.log"

            # compactando arquivo encontrado
            rar a "$rar_file" "$item"

            rm -rf "$item"
        fi
    done
    sleep 1
    arquivo_testado="/u/sist/logs/removidos_$data_atual.log"
    frase_validar="Arquivos e Pastas que estavam no 'u/sist/exec' no dia $data_clear"
    conteudo=$(cat "$arquivo_testado")
    if [ "$conteudo" == "$frase_validar" ]; then
        rm "$arquivo_testado"
        echo "Arquivo vazio removido" >/dev/null
    else
        echo "Arquivo Removido" >/dev/null
    fi

}

# -----------------------------------------------------------------------------
# Funcoes de log

# Funcao para controlar registro de logs
manter_log_atual() {

    log_atual=$ano_atual$mes_atual
    log_anterior=$ano_anterior$mes_anterior
    log_remover=$mes_anterior$ano_anterior

    if [ ! -e "$local_log/log_$mes_ano.log" ]; then
        touch "$local_log/log_$mes_ano.log"
    fi

    if [ "$log_atual" != "$log_anterior" ]; then
        if [ -e "$local_log/log_$log_remover.log" ]; then
            rm "$local_log/log_$log_remover.log"
        fi
    fi

    for arquivo in "$local_log"/log_*.log; do
        if [ "$arquivo" != "$local_log/log_$mes_ano.log" ] && [ "$arquivo" != "$local_log/log_erro_$mes_ano.log" ]; then
            rm "$arquivo"
        fi
    done

    #echo "$(date +'%d/%m/%Y - %H:%M:%S')" >> "$LOCAL_LOG/log_$MES_ANO.log"
    echo "" >>"$local_log/log_$mes_ano.log"
}

manter_log_erro_atual() {
    log_erro_atual=$ano_atual$mes_atual
    log_erro_anterior=$ano_anterior$mes_anterior
    log_erro_remover=$mes_anterior$ano_anterior

    if [ ! -e "$local_log/erro_$mes_ano.log" ]; then
        touch "$local_log/erro_$mes_ano.log"
    fi

    if [ "$log_erro_atual" != "$log_erro_anterior" ]; then
        if [ -e "$local_log/erro_$log_erro_remover.log" ]; then
            rm "$local_log/erro_$log_erro_remover.log"
        fi
    fi

    #echo "$(date +'%d/%m/%Y - %H:%M:%S')" >> "$LOCAL_LOG/erro_$MES_ANO.log"
    echo "" >>"$local_log/erro_$mes_ano.log"
}

# Funcao para criar e ou atualizar o arquivo de log com as informacoes padroes
log_info() {
    manter_log_atual
    local info="$1"
    local log_msg="\n################################################################################\n[$(date '+%d/%m/%Y - %H:%M:%S')] \n- $info \n- VERSAO COBOL: $versaoCobol \n- VERSAO INTEGRAL ANTES: $inf_versaoLoja \n- RELEASE INTEGRAL ANTES: $inf_releaseLojaAntes \n- VERSAO INSTALADA: $novoPortal \n- RELEASE INSTALADA: $data_release - $letraRelease \n- BACKUP realizado no dia $(date +"%d/%m/%Y") as $(date +"%H:%M:%S") \n- LOCAL DO BACKUP: $bkp_destino/BKPTOTAL_$date.rar \n- USUARIO UTILIZADO: $USER\n################################################################################"

    # Escreve no arquivo de log
    echo -e "$log_msg\n" >>"$log_file"

    # Verifica se o arquivo foi criado com sucesso
    if [ $? -ne 0 ]; then
        echo "Erro ao escrever no arquivo de log." >&2
        exit 1
    fi
}

# Funcao para criar e ou atualizar o arquivo de logERRO com as informacoes padroes
log_error() {
    manter_log_erro_atual
    local error="$1"
    echo "$(date '+%d/%m/%Y %H:%M:%S') - $error" >>"$erro_log_file"
}

# ------------------------------------------------------------------------------

# Funcao para converter datas no formato YYYYMMDD, para ser usado em equacoes de comparacao, maior, menor e igual
converter_datas() {
    local dia="${1:0:2}"
    local mes="${1:2:2}"
    local ano="${1:4:2}"
    # Convertendo para o formato 'YYYYMMDD' para facilitar a adição de dias
    local data_formatada="20${ano}${mes}${dia}"
    echo "$data_formatada"

}

# Funcao para tratar datas e inserir barras entre os digitos deixando DD/MM/AA
tratar_datas() {
    local dia_td=${1:0:2}
    local mes_td=${1:2:2}
    local ano_td=${1:4:2}
    local data_tratada="${dia_td}/${mes_td}/${ano_td}"
    echo "$data_tratada"
}

# Funcao para validar a versao no portal e no cliente
validar_ver_rel() {
    local_abortado="Verificando se esta na versao atual"
    baixar_controle
    novoPortal=$(grep -oP '(?<=Versao atual: )\d+' "$controle_ver_rel")
    letraRelease=$(grep -oP '(?<=Release atual: )[A-Z]' "$controle_ver_rel")
    data_release=$(grep -oP '(?<=Release atual: [A-Z] )\d{6}' "$controle_ver_rel")

    data_tratada_infVersaoLoja=$(tratar_datas "$inf_versaoLoja")
    data_tratada_dt_relaseLoja=$(tratar_datas "$data_release_servidor")
    echo "VERSAO DO INTEGRAL NESSE SERVIDOR"
    echo "VERSAO INSTALADA: $data_tratada_infVersaoLoja"
    echo "RELEASE INSTALADA: $data_tratada_dt_relaseLoja - $inf_releaseLoja"
    echo ""
    sleep 2
    local data_informada_comparar=$(converter_datas "$inf_versaoLoja")
    local data_versao_comparar=$(converter_datas "$novoPortal")

    if [ "$data_informada_comparar" -lt "$data_versao_comparar" ]; then
        echo "INTEGRAL DESATUALIZADO..."
        atualizado_flag=false
        flag_esta_atualizado=false
        flag_versao=false
        echo "$atualizado_flag" >$controle_flag/controle_flag.txt
    elif [ "$data_informada_comparar" -eq "$data_versao_comparar" ]; then
        echo "INTEGRAL ESTA COM A VERSAO ATUAL!"
        atualizado_flag=true
        flag_versao=true
        echo "$atualizado_flag" >$controle_flag/controle_flag.txt
        if [[ "$inf_releaseLoja" < "$letraRelease" ]]; then
            echo "NECESSARIO ATUALIZAR APENAS RELEASE!!!"
            atualizado_flag=false
            flag_release=false
            echo "$atualizado_flag" >$controle_flag/controle_flag.txt
        elif [[ "$inf_releaseLoja" == "$letraRelease" ]]; then
            echo "INTEGRAL ESTA COM A RELEASE ATUAL!"
            atualizado_flag=true
            flag_release=true
            echo "$atualizado_flag" >$controle_flag/controle_flag.txt
            flag_esta_atualizado=true
        else
            echo "RELEASE INVALIDA!"
        fi
    else
        echo "ERRO AO VALIDAR VERSAO E RELEASE!"
    fi
    echo ""
}

# Funcao para chamar o script que realiza o download
baixar_atualizacoes() {
    local_abortado="Processo de Download das atualizacoes"
    abortado_controle="download"
    if [ "$flag_versao" = false ]; then
        echo "$atualizado_flag" >$controle_flag/controle_flag.txt
        bash "$script_baixar_atualizacao" "--baixarVersao"
        sleep 1
        bash "$script_baixar_atualizacao" "--baixarRelease"
        sleep 1
    fi

    if [ "$flag_release" = false ]; then
        echo "$atualizado_flag" >$controle_flag/controle_flag.txt
        bash "$script_baixar_atualizacao" "--baixarRelease"
        sleep 1
    fi
}

# Funcao para realizar backup
fazer_bkp() {
    local_abortado="Realizando Backup"
    if [ -e "$bkp_destino/BKPTOTAL_$date.rar" ]; then
        # se o backup existir com a data atual permite atualizar
        sleep 1
        return 0
    else
        alerta_msg "Realizando backup dos programas..."
        total_bkp_files=$(find $local_gnt -type f -name "*.gnt" | wc -l)
        contagem_arquivo=0
        # Verifica se o comando anterior foi executado com sucesso
        if rar a "$bkp_destino/BKPTOTAL_$date" $local_gnt/*gnt | while read -r line; do
            ((contagem_arquivo++))
            porcentagem_bkp=$((contagem_arquivo * 100 / total_bkp_files))
            echo -ne "Criando Backup: [$porcentagem_bkp%]\r"
        done; then
            info_msg "Backup concluido!"
        else
            erro_msg "Erro ao realizar Backup em $date!"
            log_error "Erro ao relizar Backup em $date"
        fi
    fi

    find /u/sist/exec-a/ -name "BKPTOTAL_*" -type f -printf '%T@ %p\n' | sort -n | head -n -5 | cut -d' ' -f2- | while read file; do
        echo "No dia $(date +'%d/%m/%Y as %H:%M:%S') - o backup foi removido de: $file" >>/u/sist/logs/log-de-remocao.log
        rm -f "$file"
    done

}

# Funcao para verificar se o backup foi feito no dia atual
verifica_backup() {
    local_abortado="Validando existencia de backup"
    if [ -e "$bkp_destino/BKPTOTAL_$date.rar" ]; then
        # se o backup existir com a data atual permite atualizar
        info_msg "Backup verificado!"
        return 0
    else
        # se o backup nao existir, alertar ao usuario e voltar ao menu principal
        alerta_msg "POR FAVOR FACA O BACKUP ANTES DE ATUALIZAR"
        echo "Arquio de BACKUP nao foi localizado! $(date +"%d/%m/%Y") - $(date +"%H:%M:%S")" >>$erro_log_file
        sleep 1
        return 1
    fi
}

definirPacote_por_cobol() {
    local_abortado="Definindo pacotes para serem instalados"
    local ver="${novoPortal:0:4}"
    local rel="${data_release:0:4}"
    # Define o diretorio com base na versao do Cobol
    if [ "$versaoCobol" == "4.0" ]; then
        arquivo_versao_atual=$(find "$pasta_destino" -type f -name "versao40-$novoPortal.rar")
        arquivo_release_atual=$(find "$pasta_destino" -type f -name "release40-$ver-a-$rel.rar")
        sleep 1
    elif [ "$versaoCobol" == "4.1" ]; then
        arquivo_versao_atual=$(find "$pasta_destino" -type f -name "versao41-$novoPortal.rar")
        arquivo_release_atual=$(find "$pasta_destino" -type f -name "release-$ver-a-$rel.rar")
        sleep 1
    else
        erro_msg "Versao do Cobol desconhecida: $versaoCobol"
        echo "Versao do Cobol desconhecida: $versaoCobol" >>$erro_log_file
        exit 1
    fi
}

# Funcao para atualizar o sistema
atualizar() {
    local_abortado="Inicio Atualizacao"
    baixar_atualizacoes
    definirPacote_por_cobol
    local DIRCERTO="/u/sist/exec"
    local_abortado="func. Atualizar: pos definir"
    if [ ! -d "$DIRCERTO" ]; then
        erro_msg "O diretorio nao existe."
        echo "O diretorio nao existe." >>$erro_log_file
        exit 1
    fi

    cd "$DIRCERTO"
    atualizado_flag=$(cat "$controle_flag/controle_flag.txt")
    if [ -z "$atualizado_flag" ]; then
        echo "STATUS NAO ENCONTRADO"
        exit 1
    fi

    if [ "$atualizado_flag" != "true" ]; then
        fazer_bkp
        verifica_backup
    fi
    local_abortado="Func. Atualizar: Pre descompactacao"

    if [ "$inf_versaoLoja" != "$novoPortal" ]; then
        if [ -z "$arquivo_versao_atual" ]; then
            erro_msg "PACOTE DE ATUALIZACAO DA VERSAO NAO ENCONTRADO"
            flag_pacote_descompactado=false
            echo "PACOTE DE ATUALIZACAO DA VERSAO NAO ENCONTRADO! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
            return
        else
            local_abortado="Func. Atualizar: Descompactando Versao"
            alerta_msg "DESCOMPACTANDO A 'VERSAO'... AGUARDE!!!"
            total_files=$(rar lb "$arquivo_versao_atual" | wc -l)
            current_file=0

            if rar e -o+ "$arquivo_versao_atual" "$DIRCERTO" | while read -r line; do
                ((current_file++))
                abortado_controle="descompactar"
                percent=$((current_file * 100 / total_files))
                echo -ne "ATUALIZANDO: [$percent%]\r"
            done; then
                info_msg "ATUALIZACAO DE VERSAO CONCLUIDA!"
                flag_pacote_descompactado=true
                versaoLoja="$novoPortal"

                rm -rf "$arquivo_versao_atual"
                info_msg "VERSAO ATUALIZADA PARA: '$novoPortal'"
                sleep 1

                if [ -z "$arquivo_release_atual" ]; then
                    erro_msg "PACOTE DE ATUALIZACAO DA RELEASE NAO ENCONTRADO"
                    flag_pacote_descompactado=false
                    echo "PACOTE DE ATUALIZACAO DA RELEASE NAO ENCONTRADO! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
                    return
                else
                    local_abortado="Func. Atualizar: Descompactando Release"
                    total_files_release=$(rar lb "$arquivo_release_atual" | wc -l)
                    current_file_release=0
                    alerta_msg "DESCOMPACTANDO A 'RELEASE'... AGUARDE!!!"
                    if rar e -o+ "$arquivo_release_atual" "$DIRCERTO" | while read -r line; do
                        ((current_file_release++))
                        abortado_controle="descompactar"
                        porcento=$((current_file_release * 100 / total_files_release))
                        echo -ne "ATUALIZANDO: [$porcento%]\r"
                    done; then
                        info_msg "ATUALIZACAO DE RELEASE CONCLUIDA!"
                        flag_pacote_descompactado=true
                        rm -rf "$arquivo_release_atual"
                    else
                        erro_msg "ERRO AO ATUALIZAR!"
                        flag_pacote_descompactado=false
                        echo "ERRO AO ATUALIZAR INTEGRAL! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
                        exit 1
                    fi
                    echo ""
                    info_msg "RELEASE ATUALIZADA PARA: $letraRelease"
                    flag_pacote_descompactado=true
                    inf_releaseLoja="$letraRelease"
                fi
            else
                local_abortado="Func. Atualizar: Tentativa de descompactar"
                alerta_msg "NOVA VERSAO DISPONIVEL, MAS NAO FOI POSSIVEL ATUALIZAR. ENTRE EM CONTATO COM O SUPORTE AVANCO!"
                echo "Nova Versao Disponivel, mas nao foi possível atualizar. Entre em contato com o suporte Avanco! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
                exit 1
            fi
        fi
    elif [ "$inf_versaoLoja" == "$novoPortal" ]; then
        if [ "$inf_releaseLoja" != "$letraRelease" ]; then
            if [ -z "$arquivo_release_atual" ]; then
                erro_msg "PACOTE DE ATUALIZACAO DA RELEASE NAO ENCONTRADO"
                flag_pacote_descompactado=false
                echo "Pacote de atualizacao da release nao encontrado! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
                return
            else
                local_abortado="Func. Atualizar: Descompactando Release"
                alerta_msg "DESCOMPACTANDO A 'RELEASE'... AGUARDE!!!"
                total_files_release=$(rar lb "$arquivo_release_atual" | wc -l)
                current_file_release=0
                if rar e -o+ "$arquivo_release_atual" "$DIRCERTO" | while read -r line; do
                    ((current_file_release++))
                    abortado_controle="descompactar"
                    porcento=$((current_file_release * 100 / total_files_release))
                    echo -ne "ATUALIZANDO: [$porcento%]\r"
                done; then
                    info_msg "ATUALIZACAO DE RELEASE CONCLUIDA!"
                    flag_pacote_descompactado=true
                    rm -rf "$arquivo_release_atual"
                    inf_releaseLoja="$letraRelease"
                else
                    local_abortado="Func. Atualizar: Tentativa descompactar Release"
                    alerta_msg "NOVA RELEASE DISPONIVEL, MAS NAO FOI POSSIVEL ATUALIZAR. ENTRE EM CONTATO COM O SUPORTE AVANCO!"
                    echo "Nova Release Disponivel, mas nao foi possivel atualizar. Entre em contato com o suporte Avanco! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
                    exit 1
                fi
                echo
                info_msg "ATUALIZACAO CONCLUIDA COM SUCESSO."
            fi
        else
            local_abortado="Func. Atualizar: Validado que esta atualziado"
            echo "INTEGRAL JA ESTA COM A RELEASE MAIS RECENTE!"
            echo "INTEGRAL JA ESTA COM A RELEASE MAIS RECENTE! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$log_file
        fi
    else
        local_abortado="Func. Atualizar: Validado que esta atualizado"
        echo "INTEGRAL JA ESTA COM VERSAO E RELEASE MAIS RECENTES!"
        echo "INTEGRAL JA ESTA COM VERSAO E RELEASE MAIS RECENTES! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$log_file
    fi

    sleep 1
    local_abortado="Func. Atualizar: Atu-help iniciando"
    sleep 1
    echo "Aguarde..."
    atu-help manual
    if [ $? -ne 0 ]; then
        erro_msg "ERRO AO EXECUTAR 'ATU-HELP MANUAL'."
        echo "Erro ao executar 'atu-help manual'! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
    fi
    baixar_extras

    local_abortado="Func. Atualizar: Concedendo permissoes"
    chmod 777 /u/sist/exec/*.gnt 2>>"$validados_gnt" || {
        erro_msg "ERRO AO CONCEDER PERMISSAO TOTAL."
        echo "Erro ao conceder permissoes! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
    }

    info_msg "ATUALIZACAO REALIZADA COM SUCESSO!"
    log_info "ATUALIZACAO REALIZADA PELO ATUALIZADOR"

    rm -rf "$controle_flag/controle_flag.txt"
    local_abortado="Func. Atualizar: Fim"
    fim_atualizacao=true
}

# Funcao para atualizar o script sempre para a versao mais recente
update() {
    script_path="$0"
    clear
    echo "BAIXANDO VERSAO MAIS RECENTE DO ATUALIZADOR"
    if curl -k --output /dev/null --silent --head --fail "$script_url"; then
        mv "$script_path" "/u/bats/atualizadorOLD"
        curl -k -# -o "/u/bats/atualizador" "$script_url"
        if [ $? -eq 0 ]; then
            chmod +x "$script_path"
            echo "ATUALIZACAO CONCLUIDA."
        else
            echo "ERRO AO BAIXAR A ATUALIZACAO."
            rm -f "/u/bats/atualizador"
            mv "/u/bats/atualizadorOLD" "/u/bats/atualizador"
        fi
    else
        echo "ERRO: A URL DO ATUALIZADOR NAO ESTA ACESSIVEL."
        rm -f "/u/bats/atualizador"
        mv "/u/bats/atualizadorOLD" "/u/bats/atualizador"
    fi

    exit
}

# Funcao que gravara a versao e release apos a atualizacao
gravando_atualizacoes() {
    local_abortado="Gravando informacoes pos atualizado"
    if [[ "$flag_pacote_descompactado" = true ]]; then

        inf_versaoLoja="$novoPortal"
        data_configuracao=$(date +'%d/%m/%Y')
        data_exibir=$(tratar_datas "$inf_versaoLoja")
        data_rel_exibir=$(tratar_datas "$data_release")
        #clear
        echo
        echo "GRAVANDO INFORMACOES..."
        echo
        echo "VERSAO COBOL: $inf_versaoCobol"
        echo "VERSAO INTEGRAL INSTALADA: $data_exibir"
        echo "RELEASE INTEGRAL INSTALADA: $inf_releaseLoja"
        echo "DATA DA RELEASE INSTALADA: $data_rel_exibir"

        echo "DATA: $data_configuracao" >"$info_loja_txt"
        echo "VERSAO COBOL: $inf_versaoCobol" >>"$info_loja_txt"
        echo "VERSAO INTEGRAL: $inf_versaoLoja" >>"$info_loja_txt"
        echo "RELEASE: $inf_releaseLoja" >>"$info_loja_txt"
        echo "DATA RELEASE: $data_release" >>"$info_loja_txt"
        fim_atualizacao=true
        ativar_desativar_online

        if [ "$flag_load_parametros" = true ] && [[ "$logar_atualizando" == "N" ]]; then
            mv /u/sist/exec/cogumeloAzul.gnt /u/sist/exec/integral.gnt
        fi

        echo
        echo "INFORMACOES GRAVADAS COM SUCESSO!"
        echo
        echo "SISTEMA ATUALIZADO EM $data_configuracao"
        cobrun status-online.gnt "A" >/dev/null
    else
        echo "NAO FOI POSSIVEL GRAVAR AS INFORMACOES. $(date +"%d/%m/%Y") - $(date +"%H:%M")" >>$erro_log_file
    fi

    cronometro_start=$cronometro_start
    cronometro_stop="$(date +'%H:%M:%S')"
    cronometro_stop_volta=$SECONDS
    tempo_gasto=$((cronometro_stop_volta - cronometro_start_volta))
    tempo_gasto_formatado=$(date -u -d @${tempo_gasto} +"%M min e %S seg")
    echo "      $(date +"%d/%m/%y")      -      $cronometro_start      -    $cronometro_stop      -  $tempo_gasto_formatado  " >>"/u/sist/logs/infos_extras.log"
    echo "--------------------------------------------------------------------------------" >>"/u/sist/logs/infos_extras.log"
    echo "$avanco"
    sleep 2
}

# Funcao para somente conceder permissão e mudar dono e grupo
somente_permissao() {
    chmod 777 /u/sist/exec/*.gnt
    chown avanco:sist /u/sist/exec/*
}

# Funcao para baixar arquivo atualizado
baixar_controle() {
    local_abortado="Baixando controle de versao/release"
    echo "OBTENDO DETALHES DA VERSAO E RELEASE"
    if curl -k --output /dev/null --silent --head --fail "$url_versao_release"; then
        curl -k -# -o /u/sist/controle/versao_release.txt "$url_versao_release"

        if [ $? -eq 0 ]; then
            chmod 666 /u/sist/controle/versao_release.txt
            clear
            echo "DETALHES DA VERSAO E RELEASE OBTIDOS!"
            novoPortal=$(grep -oP '(?<=Versao atual: )\d+' "$controle_ver_rel")
            letraRelease=$(grep -oP '(?<=Release atual: )[A-Z]' "$controle_ver_rel")
            data_release=$(grep -oP '(?<=Release atual: [A-Z] )\d{6}' "$controle_ver_rel")
            data_tratada_novoPortal=$(tratar_datas "$novoPortal")
            data_tratada_dt_release=$(tratar_datas "$data_release")
            echo ""
            echo "ATUALIZACAO DISPONIVEL NO PORTAL AVANCO"
            echo "VERSAO ATUAL: $data_tratada_novoPortal"
            echo "RELEASE ATUAL: $data_tratada_dt_release - $letraRelease"
            echo ""
        else
            echo "ERRO AO OBTER VERSAO E RELEASE RECENTES!"
            rm -f /u/sist/controle/versao_release.txt
        fi
    else
        echo "ERROR: NAO FOI POSSIVEL OBTER AS INFORMACOES DE VERSAO E RELEASE."
        rm -f /u/sist/controle/versao_release.txt
    fi
}

#Nº | VERSAO | RELEASE | BACKUP

parametros() {
    if [[ -z "$1" ]]; then
        tput cup 8 30
        echo "SELECIONE UMA OPCAO: "
        tput cup 10 30
        echo "1  -  LISTAR PARAMETROS"
        tput cup 11 30
        echo "2  -  ALTERAR PARAMETROS"
        tput cup 12 30
        echo "3  -  EXCLUIR PARAMETROS"
        tput cup 13 30
        echo "4  -  RESTAURAR PARA PADRAO"
        tput cup 14 30
        echo "9  -  VOLTAR AO MENU"
        tput cup 15 30
        echo "99 -  SAIR"
        tput cup 17 30
        echo -n "OPCAO: "
        read opt
        case $opt in
        1)
            clear
            listar_parametros
            ;;
        2)
            clear
            alterar_parametros
            ;;
        3)
            clear
            excluir_parametros
            ;;
        4)
            clear
            default_parametros
            ;;
        9)
            clear
            menu_principal
            ;;
        99)
            clear
            mensagem_saida
            sleep 1
            exit 0
            ;;
        *)
            clear
            echo "OPCAO INVALIDA."
            echo "USE '1' PARA LISTAR OS PARAMETROS."
            echo "USE '2' PARA ALTERAR OS PARAMETROS."
            echo "USE '3' PARA EXCLUIR OS PARAMETROS."
            echo "OU USE '4' PARA RESTAURAR OS PARAMETROS."
            ;;
        esac
    else
        while getopts ":Lade" opt; do
            case ${opt} in
            L)
                clear
                listar_parametros
                ;;
            a)
                clear
                echo "PARAMETROS ATUAIS: "
                echo
                alterar_parametros
                ;;
            e)
                clear
                excluir_parametros
                ;;
            d)
                clear
                default_parametros
                ;;
            *)
                clear
                echo "OPCAOO INVALIDA."
                echo "USE '-L' PARA LISTAR OS PARAMETROS."
                echo "USE '-a' PARA ALTERAR OS PARAMETROS."
                echo "USE '-e' PARA EXCLUIR OS PARAMETROS."
                echo "OU USE '-d' PARA RESTAURAR OS PARAMETROS."
                ;;
            esac
        done
    fi
}

listar_parametros() {
    if [[ -f $arquivo_parametros ]]; then
        more $arquivo_parametros
        sleep 3
        clear
    else
        echo "OS PARAMETROS NAO FORAM ENCONTRADOS"
        echo "DESEJA DEFINIR PARA OS VALORES PADROES? [S/n]"
        read definir_novos
        while true; do
            case $definir_novos in
            "s" | "S")
                default_parametros
                echo
                more $arquivo_parametros
                break
                ;;
            "n" | "N")
                echo "Nenhum parametro armazenado"
                exit 1
                ;;
            *)
                echo "OPCAO INVALIDA!"
                parametros
                ;;
            esac
            read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
            clear
        done
    fi
}

carregar_parametros() {
    if [[ ! -f $arquivo_parametros ]]; then
        default_parametros

        flag_load_parametros=true
        deslogar_usuarios=$(grep -oP '^DESLOGAR USUARIOS - \K\S+' "$arquivo_parametros")
        logar_atualizando=$(grep -oP '^LOGAR ATUALIZANDO - \K\S+' "$arquivo_parametros")
        avisar_atualizacao=$(grep -oP '^AVISAR ATUALIZACAO - \K\S+' "$arquivo_parametros")
        avisar_extras=$(grep -oP '^AVISAR EXTRAS - \K\S+' "$arquivo_parametros")
        baixar_automaticamente=$(grep -oP '^BAIXAR AUTOMATICAMENTE - \K\S+' "$arquivo_parametros")
        instalar_automaticamente=$(grep -oP '^INSTALAR AUTOMATICAMENTE - \K\S+' "$arquivo_parametros")
        todos_autorizados=$(grep -oP '^TODOS AUTORIZADOS - \K\S+' "$arquivo_parametros")
        autorizados=$(grep -oP '^AUTORIZADOS - \K.*' "$arquivo_parametros")
    elif [[ -f $arquivo_parametros ]]; then
        flag_load_parametros=true
        deslogar_usuarios=$(grep -oP '^DESLOGAR USUARIOS - \K\S+' "$arquivo_parametros")
        logar_atualizando=$(grep -oP '^LOGAR ATUALIZANDO - \K\S+' "$arquivo_parametros")
        avisar_atualizacao=$(grep -oP '^AVISAR ATUALIZACAO - \K\S+' "$arquivo_parametros")
        avisar_extras=$(grep -oP '^AVISAR EXTRAS - \K\S+' "$arquivo_parametros")
        baixar_automaticamente=$(grep -oP '^BAIXAR AUTOMATICAMENTE - \K\S+' "$arquivo_parametros")
        instalar_automaticamente=$(grep -oP '^INSTALAR AUTOMATICAMENTE - \K\S+' "$arquivo_parametros")
        todos_autorizados=$(grep -oP '^TODOS AUTORIZADOS - \K\S+' "$arquivo_parametros")
        autorizados=$(grep -oP '^AUTORIZADOS - \K.*' "$arquivo_parametros")
    else
        flag_load_parametros=false
    fi
}

validar_entrada() {
    local valor
    while true; do
        read -p "INFORMAR S, N, ou deixar em branco: " valor
        valor=$(echo "$valor" | tr '[:lower:]' '[:upper:]')
        if [[ "$valor" =~ ^[SN]$ ]] || [[ -z "$valor" ]]; then
            break
        fi
    done
    echo "$valor"
}

alterar_parametros() {
    more $arquivo_parametros
    echo
    echo "DESEJA ALTERAR OS PARAMETROS? [S/n]"
    read resposta
    resposta=$(echo "$resposta" | tr '[:lower:]' '[:upper:]')
    if [[ "$resposta" == "S" ]]; then
        clear
        echo "DESLOGAR USUARIOS"
        deslogar_usuarios=$(validar_entrada)

        echo "LOGAR ATUALIZANDO"
        logar_atualizando=$(validar_entrada)

        echo "AVISAR ATUALIZACAO"
        avisar_atualizacao=$(validar_entrada)

        echo "AVISAR EXTRAS"
        avisar_extras=$(validar_entrada)

        echo "BAIXAR AUTOMATICAMENTE"
        baixar_automaticamente=$(validar_entrada)

        echo "INSTALAR AUTOMATICAMENTE"
        instalar_automaticamente=$(validar_entrada)

        echo "TODOS AUTORIZADOS"
        todos_autorizados=$(validar_entrada)
        if [ "$todos_autorizados" == "N" ]; then
            echo "INFORME OS USUARIOS AUTORIZADOS(usar nome separados por espaco)"
            read autorizados
            autorizados=$(echo "$autorizados" | tr '[:upper:]' '[:lower:]')
        elif [ "$todos_autorizados" == "S" ]; then
            autorizados="TODOS"
        elif [[ -z $todos_autorizados ]]; then
            autorizados="vazio"
        fi

        echo "DESLOGAR USUARIOS - $deslogar_usuarios" >$arquivo_parametros
        echo "LOGAR ATUALIZANDO - $logar_atualizando" >>$arquivo_parametros
        echo "AVISAR ATUALIZACAO - $avisar_atualizacao" >>$arquivo_parametros
        echo "AVISAR EXTRAS - $avisar_extras" >>$arquivo_parametros
        echo "BAIXAR AUTOMATICAMENTE - $baixar_automaticamente" >>$arquivo_parametros
        echo "INSTALAR AUTOMATICAMENTE - $instalar_automaticamente" >>$arquivo_parametros
        echo "TODOS AUTORIZADOS - $todos_autorizados" >>$arquivo_parametros
        echo "AUTORIZADOS - $autorizados" >>$arquivo_parametros

        clear
        echo "Parametros atualizados!"
        listar_parametros
    elif [[ "$resposta" == "N" ]]; then
        echo "Alteracao de parametros cancelada."
    else
        echo "Opcao invalida. Use S ou N"
    fi
}

excluir_parametros() {
    rm -rf $arquivo_parametros
    echo "Parametros excluidos."
}

default_parametros() {
    echo "DESLOGAR USUARIOS - N" >$arquivo_parametros
    echo "LOGAR ATUALIZANDO - N" >>$arquivo_parametros
    echo "AVISAR ATUALIZACAO - N" >>$arquivo_parametros
    echo "AVISAR EXTRAS - N" >>$arquivo_parametros
    echo "BAIXAR AUTOMATICAMENTE - N" >>$arquivo_parametros
    echo "INSTALAR AUTOMATICAMENTE - N" >>$arquivo_parametros
    echo "TODOS AUTORIZADOS - S" >>$arquivo_parametros
    echo "AUTORIZADOS - TODOS" >>$arquivo_parametros
    echo "Parametros definidos para os valores padrao."
}

menu_principal() {
    clear
    while true; do
        tput cup 2 27
        echo "MENU ATUALIZADOR INTEGRAL"
        tput cup 5 31
        echo -ne "\e[1;36mOPCOES DISPONIVEIS:\e[0m"
        tput cup 8 22
        echo " 1  -  OBTER INFORMACOES DO INTEGRAL"
        tput cup 9 22
        echo " 2  -  ATUALIZAR"
        tput cup 10 22
        echo " 3  -  OPCOES DE BACKUP"
        tput cup 11 22
        echo " 4  -  LOGS"
        tput cup 12 22
        echo " 5  -  CONFIGURACOES"
        tput cup 13 22
        echo " 6  -  EXTRAS"
        tput cup 14 22
        echo " 7  -  MANUAL"
        tput cup 15 22
        echo "99  -  SAIR"
        tput cup 19 31
        echo -ne "\e[1;32mOPCAO: \e[0m"
        read opcao
        case $opcao in
        1)
            menu_1
            ;;
        2)
            clear
            menu_2
            ;;

        3)
            clear
            menu_3
            ;;
        4)
            clear
            menu_4
            ;;
        5)
            clear
            menu_5
            ;;
        6)
            clear
            echo "EXTRAS"
            menu_6
            ;;
        7)
            clear
            menu_7
            ;;
        88888) ;;
        99999) ;;
        1188)
            clear
            if [ $USER = avanco ] || [ $USER = root ]; then
                echo "LIBERADO PARA CONFIGURAR"
            else
                echo "Favor acionar o Suporte Avanco para realizar a configuracao"
                exit
            fi
            echo "MANUAL AVANCO"
            echo ""
            ;;
        "avanco" | "AVANCO")
            clear
            if [ $USER = avanco ] || [ $USER = root ]; then
                echo "LIBERADO PARA CONFIGURAR"
            else
                echo "Favor acionar o Suporte Avanco para realizar a configuracao"
                exit
            fi
            ;;
        "r" | "R")
            clear
            echo "REVERTER ATUALIZACAO"
            menu_restaura
            ;;
        99)
            clear
            mensagem_saida
            echo
            sleep 1
            exit 0
            ;;
        *)
            clear
            tput cup 8 32
            echo -ne "\e[1;31mOPCAO INVALIDA!\e[0m"
            ;;
        esac
        sleep 3
        tput cup 20 18
        read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
        clear
    done
}
#
## Funções para sub-menus
# sub-menu opção 1
menu_1() {
    local opcao_menu
    local conteudo_exibir
    clear
    while true; do
        tput cup 5 28
        echo -ne "\e[1;36mINFORMACOES DO INTEGRAL\e[0m"
        tput cup 8 22
        echo " 1  -  VERSAO E RELEASE NESSE SERVIDOR"
        tput cup 9 22
        echo " 2  -  VERSAO E RELEASE NO PORTAL AVANCO"
        tput cup 10 22
        echo " 9  -  MENU PRINCIPAL"
        tput cup 11 22
        echo "99  -  SAIR"
        tput cup 14 31
        echo -ne "\e[1;32mOPCAO: \e[0m"
        read opcao_menu
        case "$opcao_menu" in
        1)
            clear
            echo
            more "/u/sist/controle/info_loja.txt"
            ;;
        2)
            clear
            baixar_controle >/dev/null 2>&1
            tput cup 7 21
            echo "DETALHES DA VERSAO E RELEASE OBTIDOS!"
            tput cup 9 21
            echo "ATUALIZACAO DISPONIVEL NO PORTAL AVANCO"
            tput cup 10 21
            echo "VERSAO ATUAL:   $data_tratada_novoPortal"
            tput cup 11 21
            echo "RELEASE ATUAL:  $data_tratada_dt_release - $letraRelease"
            ;;
        9)
            menu_principal
            return 1
            ;;

        99)
            clear
            mensagem_saida
            echo
            sleep 1
            exit 0
            ;;
        *)
            clear
            tput cup 8 32
            echo -ne "\e[1;31mOPCAO INVALIDA!\e[0m"
            ;;
        esac
        sleep 3
        tput cup 14 18
        read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
        clear
    done
}
# sub-menu opção 2
menu_2() {
    local opcao_menu
    clear
    while true; do
        tput cup 5 28
        echo -ne "\e[1;36mCENTRAL DE ATUALIZACOES DO INTEGRAL\e[0m"
        tput cup 8 22
        echo " 1  -  ATUALIZAR INTEGRAL"
        tput cup 9 22
        echo " 2  -  ATUALIZAR PACOTE POR ID"
        tput cup 10 22
        echo " 3  -  ESCOLHER PACOTE NA PASTA ATUALIZACOES"
        tput cup 11 22
        echo " 4  -  BAIXAR PACOTE VIA LINK"
        tput cup 12 22
        echo " 9  -  MENU PRINCIPAL"
        tput cup 13 22
        echo "99  -  SAIR"
        tput cup 15 31
        echo -ne "\e[1;32mOPCAO: \e[0m"
        read opcao_menu
        case "$opcao_menu" in
        1)
            clear
            echo "Atualizando..."
            #chamar_atualizacao
            ;;
        2)
            clear
            tput cup 6 29
            echo "INFORME O ID DO PACOTE"
            ;;
        3)
            clear
            tput cup 6 27
            echo "LISTAR PACOTE DISPONIVEIS"
            ;;
        4)
            clear
            tput cup 6 29
            echo "INSIRA O LINK ABAIXO: "
            ;;
        9)
            menu_principal
            return 1
            ;;

        99)
            clear
            mensagem_saida
            echo
            sleep 1
            exit 0
            ;;
        *)
            clear
            tput cup 8 32
            echo -ne "\e[1;31mOPCAO INVALIDA!\e[0m"
            ;;
        esac
        sleep 3
        tput cup 14 18
        read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
        clear
    done
}
# sub-menu opção 3
menu_3() {
    local opcao_menu
    clear
    while true; do
        tput cup 5 28
        echo -ne "\e[1;36mCENTRAL DE BACKUP DO INTEGRAL\e[0m"
        tput cup 8 22
        echo " 1  -  FAZER BACKUP DO 'sist/exec'"
        tput cup 9 22
        echo " 2  -  LISTAR BACKUP's DISPONIVEIS"
        tput cup 10 22
        echo " 9  -  MENU PRINCIPAL"
        tput cup 11 22
        echo "99  -  SAIR"
        tput cup 14 31
        echo -ne "\e[1;32mOPCAO: \e[0m"
        read opcao_menu
        case "$opcao_menu" in
        1)
            clear
            echo "BACKUP EM ANDAMENTO"
            #fazer_bkp
            ;;
        2)
            clear
            ls -tr /u/sist/exec-a/BKPTOTAL_* | awk -F'/' '{print $NF}'
            ;;
        9)
            menu_principal
            return 1
            ;;

        99)
            clear
            mensagem_saida
            echo
            sleep 1
            exit 0
            ;;
        *)
            clear
            tput cup 8 32
            echo -ne "\e[1;31mOPCAO INVALIDA!\e[0m"
            ;;
        esac
        sleep 3
        tput cup 14 18
        read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
        clear
    done
}
# sub-menu opção 4
menu_4() {
    ler_logs
}
# sub-menu opção
menu_5() {
    local opcao_menu
    clear
    while true; do
        tput cup 5 20
        echo -ne "\e[1;36mCENTRAL DE CONFIGURACOES DO ATUALIZADOR\e[0m"
        tput cup 8 22
        echo " 1  -  CONFIGURAR ATUALIZADOR NO CRON"
        tput cup 9 22
        echo " 2  -  PARAMETROS DO ATUALIZADOR"
        tput cup 10 22
        echo " 3  -  PARAMETROS USUARIO"
        tput cup 11 22
        echo " 9  -  MENU PRINCIPAL"
        tput cup 12 22
        echo "99  -  SAIR"
        tput cup 14 20
        echo -ne "\e[1;32mOPCAO: \e[0m"
        read opcao_menu
        case "$opcao_menu" in
        1)
            echo
            clear
            if [ $USER = root ]; then
                echo "CONFIGURACOES NO CRON"
                sleep 1
                clear
                configurar_cron
            else
                echo "Favor acionar o Suporte Avanco para realizar a configuracao"
                exit
            fi
            ;;
        2)
            clear
            echo "PARAMETROS ATUALIZADOR"
            if [ $USER = avanco ] || [ $USER = root ]; then
                parametros
            else
                echo "Favor acionar o Suporte Avanco para realizar a configuracao"
                exit
            fi
            ;;
        3)
            clear
            echo "OPCOES DE PARAMETROS INDIVIDUAIS"
            ;;
        9)
            clear
            menu_principal
            return 1
            ;;

        99)
            clear
            mensagem_saida
            echo
            sleep 1
            exit 0
            ;;
        *)
            clear
            tput cup 8 32
            echo -ne "\e[1;31mOPCAO INVALIDA!\e[0m"
            ;;
        esac
        sleep 3
        tput cup 14 18
        read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
        clear
    done
}
# sub-menu opção 6
menu_6() {
    local opcao_menu
    clear
    while true; do
        tput cup 5 26
        echo -ne "\e[1;36mOPCOES EXTRAS DO ATUALIZADOR\e[0m"
        tput cup 8 22
        echo " 1  -  AJUSTES E CORRECOES"
        tput cup 9 22
        echo " 2  -  CONCEDER PERMISSAO"
        tput cup 10 22
        echo " 3  -  UPDATE ATUALIZADOR"
        tput cup 11 22
        echo " 4  -  AVISAR ATUALIZACAO"
        tput cup 12 22
        echo " 9  -  MENU PRINCIPAL"
        tput cup 13 22
        echo "99  -  SAIR"
        tput cup 15 26
        echo -ne "\e[1;32mOPCAO: \e[0m"
        read opcao_menu
        case "$opcao_menu" in
        1)
            clear
            echo "MENU DE CORRECOES"
            menu_correcoes
            ;;
        2)
            clear
            echo "CONDECENDO PERMISSAO TOTAL AO INTEGRAL"
            if [ $USER = avanco ] || [ $USER = root ]; then
                conceder_permissao "t" /u/sist/exec/*.gnt 2>>"$validados_gnt"
            else
                yellow_msg "FAVOR ACIONAR O SUPORTE AVANCO PARA CONCEDER AS PERMISSOES"
                exit 1
            fi

            ;;
        3)
            clear
            echo "BUSCANDO NOVA VERSAO DO ATUALIZADOR! AGUARDE..."
            nova_versao
            ;;

        4)
            clear
            yellow_msg "!!!ATENCAO!!!"
            yellow_msg "SERA ENVIADO UMA MENSAGEM PARA OS USUARIOS LOGADOS"
            yellow_msg "QUE O INTEGRAL SERA ATUALIZADO EM INSTANTES!!!"
            verifica_logados
            ;;
        9)
            menu_principal
            return 1
            ;;

        99)
            clear
            mensagem_saida
            echo
            sleep 1
            exit 0
            ;;
        *)
            clear
            tput cup 8 32
            echo -ne "\e[1;31mOPCAO INVALIDA!\e[0m"
            ;;
        esac
        sleep 3
        tput cup 14 18
        read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
        clear
    done
}
# sub-menu opção 6
menu_7() {
    local opcao_menu
    clear
    while true; do
        tput cup 5 29
        echo -ne "\e[1;36mMANUAIS DO ATUALIZADOR\e[0m"
        tput cup 8 22
        echo " 1  -  LER AJUDA RAPIDA"
        tput cup 9 22
        echo " 2  -  MANUAL COMPLETO"
        tput cup 10 22
        echo " 9  -  MENU PRINCIPAL"
        tput cup 11 22
        echo "99  -  SAIR"
        tput cup 14 31
        echo -ne "\e[1;32mOPCAO: \e[0m"
        read opcao_menu
        case "$opcao_menu" in
        1)
            clear
            mostrar_ajuda 1
            ;;
        2)
            clear
            mostrar_ajuda 2
            ;;
        9)
            menu_principal
            return 1
            ;;

        99)
            clear
            mensagem_saida
            echo
            sleep 1
            exit 0
            rm -rf "$TMP_manual"
            rm -rf "$TMP_ajuda"
            ;;
        *)
            clear
            tput cup 8 32
            echo -ne "\e[1;31mOPCAO INVALIDA!\e[0m"
            ;;
        esac
        sleep 3
        #tput clear
        tput cup 24 18
        read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
        clear
    done
}


# Funcao para corrigir erros ao tentar atualizar
menu_correcoes() {
    echo "CENTRAL DE CORRECOES DO ATUALIZADOR"
    echo
    echo "1. Corrigir Detalhes da Versao e Release Nesse Servidor"
    echo "2. Dar permissao total no 'sist/exec'"
    echo "3. Limpar Exec"
    echo "4. Liberar acesso ao Integral"
}

# Função para ativar, editar, mostrar, desativar ou remover configuração do crontab
configurar_cron() {
    local cron_command="/u/bats/atualizador --atu-cron"

    while true; do
        echo "MENU DE CONFIGURACAO DO CRON"
        echo
        echo "1.  Ativar Atualizador no cron"
        echo "2.  Editar Atualizador cron"
        echo "3.  Mostrar Atualizador cron"
        echo "4.  Desativar Atualizador cron"
        echo "9.  Voltar ao menu"
        echo "99. Sair"
        echo
        read -p "Escolha uma opcao: " opcao
        echo

        case $opcao in
        1)
            # Ativar atualizador no cron
            if crontab -l | grep -q "$cron_command"; then
                if crontab -l | grep -q "#.*$cron_command"; then
                    echo "ATIVANDO ATUALIZADOR...AGUARDE"
                    crontab -l | sed "s|# \(.*$cron_command.*\)|\1|" | crontab -
                    echo "ATUALIZADOR ATIVO NO CRON!"
                else
                    echo "ATUALIZADOR JA ESTA ATIVO NO CRON!"
                fi
            else
                echo "ATUALIZADOR NAO ESTA ATIVO NO CRON..."
                configuracoes_cron
            fi
            ;;
        2)
            # Editar atualizador no cron
            alterar_cron
            sleep 1
            ;;
        3)
            # Mostrar atualizador no cron
            if crontab -l | grep -q "$cron_command"; then
                echo "# ATUALIZADOR AUTOMATICO"
                crontab -l | grep "$cron_command"
                if [ -f "$config_cron" ]; then
                    more "$config_cron"
                    echo
                else
                    echo "NAO FOI ENCONTRADO O ARQUIVO DA CONFIGURACAO QUE ESTA NO CRON!"
                fi
            else
                echo "NAO FOI ENCONTRADO NO CRON A CONFIGURACAO!"
                rm -rf "$config_cron" 2>>/dev/nul
            fi
            ;;
        4)
            # Desativar atualizador no cron
            if crontab -l | grep -q "$cron_command"; then
                if ! crontab -l | grep -q "^#.*$cron_command"; then
                    echo "DESATIVANDO ATUALIZADOR...AGUARDE"
                    crontab -l | sed "s|\(.*$cron_command\)|# \1|" | crontab -
                    echo "ATUALIZADOR DESATIVADO NO CRON!"
                else
                    echo "ATUALIZADOR JA ESTA DESATIVADO NO CRON"
                fi
            else
                echo "NAO EXISTE CONFIGURACAO DO ATUALIZADOR NO CRON"
            fi
            ;;
        9)
            menu_principal
            ;;
        99)
            # Sair
            clear
            exit
            ;;
        *)
            echo "OPCAO INVALIDA! TENTE NOVAMENTE!!!"
            ;;
        esac
        echo
        read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
        clear
    done
}

# Funcao para configurar no cron
configuracoes_cron() {
    local_abortado="configuracao do cron"
    local cron_command="/u/bats/atualizador --atu-cron"
    carregar_parametros
    if ! crontab -l | grep -q "$cron_command"; then
        if [[ "$flag_load_parametros" == "false" ]]; then
            echo "NECESSARIO ATIVAR OS PARAMETROS"
        elif [[ "$flag_load_parametros" == "true" ]] && [[ "$instalar_automaticamente" == "S" ]]; then
            while true; do
                read -p "DESEJA ALTERAR A CONFIGURACAO NO CRON? [S/n] " alterar_no_cron
                alterar_no_cron=$(echo "$alterar_no_cron" | tr '[:lower:]' '[:upper:]')
                case "$alterar_no_cron" in
                "S")
                    alterar_cron
                    break
                    ;;
                "N")
                    clear
                    echo "O INTEGRAL SERA ATUALIZADO ATRAVES DO CRON TODA SEMANA NA '$dia_informado' AS '0$hora_informada HORAS'"
                    break
                    ;;
                *)
                    clear
                    echo "Entrada invalida, confirme com (S) para sim ou (N) para nao"
                    ;;
                esac
                read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
                clear
            done
        elif [[ "$flag_load_parametros" == "true" ]] && [[ "$instalar_automaticamente" == "N" ]]; then
            echo "NECESSARIO ATIVAR PARAMETRO: 'INSTALAR AUTOMATICAMENTE'"
            exit
        fi
    fi
}

alterar_cron() {
    while true; do
        while true; do
            echo "INFORME ABAIXO O DIA QUE DESEJA QUE O INTEGRAL SEJA ATUALIZADO"
            read -p "DIAS PERMITIDOS: (segunda a quinta) " dia_informado
            dia_informado=$(echo "$dia_informado" | tr '[:upper:]' '[:lower:]')
            case "$dia_informado" in
            "segunda" | "seg")
                dia_definido=1
                ;;
            "terca" | "ter" | "terça")
                dia_definido=2
                ;;
            "quarta" | "qua")
                dia_definido=3
                ;;
            "quinta" | "qui")
                dia_definido=4
                ;;
            *)
                echo "DIA INVALIDO"
                continue
                ;;
            esac
            echo
            read -p "CONFIRMA O DIA INFORMADO $dia_informado ? [S/n] " confirmar_dia_informado
            confirmar_dia_informado=$(echo "$confirmar_dia_informado" | tr '[:lower:]' '[:upper:]')
            case "$confirmar_dia_informado" in
            "S")
                echo "DIA INFORMADO: $dia_informado"
                break
                ;;
            "N")
                clear
                echo "INFORME NOVAMENTE O DIA"
                #break
                ;;
            *)
                clear
                echo "Entrada invalida, confirme com (S) para sim ou (N) para nao"
                ;;
            esac
        done

        while true; do
            read -p "EM QUAL HORA (0-5) DESEJA QUE SEJA ATUALIZADO? " hora_informada
            if ! [[ $hora_informada =~ ^[0-5]+$ ]]; then
                echo "Favor insirir uma hora entre 00 a 05h, para atualizar."
            else
                read -p "CONFIRMA A HORA? [S/N] " confirmar_hora
                case "$(echo "$confirmar_hora" | tr '[:lower:]' '[:upper:]')" in
                "S")
                    echo "HORA SELECIONADA $hora_informada"
                    break
                    ;;
                "N")
                    clear
                    echo "INFORME NOVAMENTE A HORA"
                    ;;
                *)
                    clear
                    echo "Entrada invalida, confirme com (S) para sim ou (N) para nao"
                    ;;
                esac
            fi
        done
        echo
        clear
        echo "DIA INFORMADO: $dia_informado-feira"
        echo "HORA INFORMADA: 0$hora_informada horas"
        echo
        while true; do
            read -p "DESEJA REALMENTE ATUALIZAR NESSE DIA E HORA? [S/n] " confirmar_cron
            case "$(echo "$confirmar_cron" | tr '[:lower:]' '[:upper:]')" in
            "S" | "")
                echo "O INTEGRAL SERA ATUALIZADO ATRAVES DO CRON TODA SEMANA NA '$dia_informado' AS '0$hora_informada HORAS'"
                echo "PARAMETROS ATUALIZADOR NO CRON" >$config_cron
                echo >>$config_cron
                echo "DIA SEMANA: '$dia_definido' - '$dia_informado'" >>$config_cron
                echo "HORA: 0$hora_informada" >>$config_cron
                (
                    crontab -l
                    echo ""
                    echo "# ATUALIZADOR AUTOMATICO"
                    echo "0 $hora_informada * * $dia_definido /u/bats/atualizador --atu-cronb 2>> /u/sist/logs/.cron-erro.log"
                    echo ""
                ) | crontab -
                break 2
                ;;
            "N")
                clear
                echo "FAVOR INFORMAR NOVAMENTE!!!"
                break
                ;;
            *)
                echo "Entrada invalida, confirme com (S) para sim ou (N) para nao"
                ;;
            esac
        done
    done
}

# Funcao exclusiva para o cron
atualizar_pelo_cron() {
    if [ "$(id -u)" -ne 0 ]; then
        clear
        tput smso
        echo "ACESSO NEGADO!!!"
        sleep 2
        tput rmso
        echo "" >>$auditoria
        echo "TENTATIVA DE ACESSAR CONFIGURACAO DO CRON" >>$auditoria
        echo "NO DIA $(date +'%d/%m/%Y') AS $(date +'%H:%M:%S') HORAS" >>$auditoria
        echo "$(whoami)" >>"$auditoria"
        echo "USUARIO: $USER" >>$auditoria
        exit
    else
        inf_versaoCobol=$(grep -oP '(?<=VERSAO COBOL: )\d+.\d+' "$info_loja_txt")
        versaoCobol="$inf_versaoCobol"
        carregar_parametros
        checar_internet
        verifica_atualizacao
        chmod 777 /u/sist/exec/*.gnt 2>>"$log_cron_erro"
        chown avanco:sist /u/sist/exec/*.gnt 2>>"$log_cron_erro"
        limpa_exec
        ler_arquivo_texto >/dev/null 2>&1
        atualizar
        chmod 777 /u/sist/exec/*.gnt 2>>"$log_cron_erro"
        gravando_atualizacoes
        chmod 644 /u/sist/logs/.cron-erro.log
        chmod 644 /u/sist/logs/.cron-log.log
        chown avanco:sist /u/sist/exec/*.gnt 2>>"$log_cron_erro"
        chown avanco:sist /u/sist/controle/*
        exit 0
    fi
}

# Função para verificar a senha do usuário atual
verificar_senha() {
    tentativas=3
    while [ $tentativas -gt 0 ]; do
        echo -n "Digite sua senha: "
        read -s senha
        echo

        # Verifica a senha usando 'sudo' com o comando ':'
        echo "$senha" | su -c true $USER >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            clear
            return 0
        else
            clear
            echo "Senha incorreta."
            ((tentativas--))
            echo "Tentativas restantes: $tentativas"
        fi
    done
    return 1
}

# funcao para controlar a restauracao.
menu_restaura() {
    local_abortado="Restaurando backup"
    usuario_permitido

    if ! verificar_senha; then
        echo "Falha na autenticacao. Encerrando o script."
        exit 1
    fi

    echo "BACKUPS DISPONIVEIS:                             (9) para menu ou (99) para sair"
    echo ""
    backups=$(ls ${bkp_destino}/BKPTOTAL_* | sort)
    select backup in ${backups}; do
        if [ "$REPLY" = "99" ]; then
            exit 1
        elif [ "$REPLY" = "9" ]; then
            menu_principal
        fi
        if [[ -n $backup ]]; then
            echo "SERA RESTAURADO O BACKUP: $backup"
            rar e -o+ "$backup" "$local_gnt"
            clear
            break
        else
            echo "OPCAO ESCOLHIDA INVALIDA. TENTE NOVAMENTE."
        fi
    done

    data_bkp=$(basename $backup | sed 's/^BKPTOTAL_//')
    arquivo_log="${local_log}/log_$(date +'%m%y').log"

    if [[ ! -f $arquivo_log ]]; then
        echo "ARQUIVO DE LOG NAO ENCONTRADO: $arquivo_log"
        exit 1
    fi

    entrada_log=$(awk -v RS="################################################################################" -v date="$data_bkp" '$0 ~ date {print}' $arquivo_log)

    if [[ -z $entrada_log ]]; then
        erro_msg "NAO FOI POSSiVEL ENCONTRAR AS INFORMACOES DO BACKUP NO ARQUIVO DE LOG."
        echo "NAO FOI POSSiVEL ENCONTRAR AS INFORMACOES DO BACKUP NO ARQUIVO DE LOG." >>$erro_log_file
        exit 1
    fi

    versao_cobol_antes=$(echo "$entrada_log" | grep -oP '(?<=- VERSAO COBOL: )\S+')
    versao_integral_antes=$(echo "$entrada_log" | grep -oP '(?<=- VERSAO INTEGRAL ANTES: )\S+')
    release_integral_antes=$(echo "$entrada_log" | grep -oP '(?<=- RELEASE INTEGRAL ANTES: )\S+')

    echo "DATA: $(date +'%d/%m/%Y')" >$info_loja_txt
    echo "VERSAO COBOL: $versao_cobol_antes" >>$info_loja_txt
    echo "VERSAO INTEGRAL: $versao_integral_antes" >>$info_loja_txt
    echo "RELEASE: $release_integral_antes" >>$info_loja_txt
    echo "DATA RELEASE: " >>$info_loja_txt

    echo "BACKUP FOI RESTAURADO PARA A VERSAO ABAIXO"
    echo
    echo "DATA: $(date +'%d/%m/%Y')"
    echo "VERSAO COBOL: $versao_cobol_antes"
    echo "VERSAO INTEGRAL: $versao_integral_antes"
    echo "RELEASE: $release_integral_antes"
    echo "DATA RELEASE: "
    echo
    echo "BACKUP RESTAURADO COM SUCESSO."
    echo "" >>$log_file
    echo "BACKUP RESTAURADO COM SUCESSO NO DIA $(date +'%d/%m/%Y') as $(date +'%H:%M:%S')" >>$log_file

}

# Funcao para extrair e exibir a versao do programa
mostrar_versao() {
    local versao=$(grep '^# DATA:' "$0" | head -1 | cut -d '-' -f 2 | sed 's/Versao //')
    echo -n "-Programa: $(basename "$0")"
    echo
    echo "-Versao:  $versao"
}

# Funcao para visualizar logs
ler_logs() {
    clear
    while true; do
        echo "LOGS DISPONIVEIS PARA CONSULTA"
        echo
        echo "1  -  LOG DE ATUALIZACAO"
        echo "2  -  LOG DE ERRO"
        echo "3  -  LOG DE DESEMPENHO"
        echo "4  -  LOG DE ARQUIVOS REMOVIDOS"
        echo "9  -  VOLTAR AO MENU"
        echo "99 -  SAIR"
        echo
        read -p "ESCOLHA UMA OPCAO: " opcao_log
        case $opcao_log in
        1)
            clear
            (head -n 3 "$log_file" && tail -n 50 "$log_file")
            ;;
        2)
            clear
            (echo "ULTIMOS ERROS GRAVADOS" && echo "" && tail -n 25 "$erro_log_file")
            ;;
        3)
            clear
            (head -n 2 "$infos_extras" && tail -n 9 "$infos_extras")
            ;;
        4)
            clear
            visualizar_logs
            ;;
        9)
            clear
            menu_principal
            ;;
        99)
            clear
            mensagem_saida
            sleep 2
            exit 0
            ;;
        1188)
            clear
            if [ $USER = avanco ]; then
                (head -n 3 "$auditoria" && tail -n 25 "$auditoria")
            fi
            ;;
        *)
            echo "OPCAO INVALIDA!"
            ;;
        esac
        echo
        read -p "PRESSIONE QUALQUER TECLA PARA CONTINUAR... " -n 1
        clear
    done
}

visualizar_logs() {
    log_dir="/u/sist/logs"
    echo "LOGS DISPONIVEIS: "
    logs_removidos=($(ls -1 $log_dir | grep 'removidos'))

    if [ ${#logs_removidos[@]} -eq 0 ]; then
        echo "Nenhum Log disponivel."
        return
    fi

    for i in "${!logs_removidos[@]}"; do
        echo "$((i + 1)). ${logs_removidos[$i]}"
    done

    echo
    echo "DIGITE O Num LOG QUE DESEJA VISUALIZAR:      (9) menu anterior ou (99) para sair"
    read numero_log

    if [ "$numero_log" = "99" ]; then
        clear
        mensagem_saida
        exit 0
    elif [ "$numero_log" = "9" ]; then
        ler_logs
    fi
    if [[ $numero_log -gt 0 && $numero_log -le ${#logs_removidos[@]} ]]; then
        log_selecionado="${logs_removidos[$((numero_log - 1))]}"
        echo "EXIBINDO O LOG $log_selecionado: "
        cat "$log_dir/$log_selecionado"
    else
        echo "NUMERO INVALIDO. TENTE NOVAMENTE."
    fi
}

# Função para ser baixado e configurado scripts e programas extras
baixar_extras() {

    if [ "$distro_nome" = "Debian" ]; then
        if [ ! -f "/u/bats/xmlstarlet" ]; then
            # Usando o link raw para baixar o binário corretamente
            echo "CONFIGURANDO XMLSTARTLET"
            curl -L -# -o "/u/bats/xmlstarlet" "https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/extras/xmlstarlet.Debian"
            #chown avanco:sist /u/bats/xmlstarlet
            chmod +x /u/bats/xmlstarlet
        fi
    elif [ "$distro_nome" = "Slackware" ]; then
        if [ ! -f "/u/bats/xmlstarlet" ]; then
            echo "CONFIGURANDO XMLSTARTLET"
            # Usando o link raw para baixar o binário corretamente
            curl -L -# -o "/u/bats/xmlstarlet" "https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/extras/xmlstarlet.Slackware"
            #chown avanco:sist /u/bats/xmlstarlet
            chmod +x /u/bats/xmlstarlet
        fi
    else
        echo "NECESSARIO CONFIGURAR EXTRAS MANUALMENTE!!!"
    fi
    echo
    if [ ! -f "/u/bats/gera-xml-por-tag.sh" ]; then
        echo "CONFIGURANDO GERA-XML"
        curl -# -o "/u/bats/gera-xml-por-tag.sh" "https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/extras/gera-xml-por-tag.sh"
        #chown avanco:sist /u/bats/gera-xml-por-tag.sh
        chmod +x /u/bats/gera-xml-por-tag.sh
    fi
    echo
}

###############################
# Tratamento das opcoes que serao responsaveis por controlar na linha de comando
# ------------------------------------------------------------------------------

case "$1" in
-h | --help)
    clear
    echo "$manual_uso"
    exit 0
    ;;
-V | -v | --version)
    # Extrai a versao diretamente do cabecalho do programa
    mostrar_versao
    exit 0
    ;;
-i | --info)
    clear
    echo "OBTER INFORMACOES DO ATUAIS DO INTEGRAL"
    more "/u/sist/controle/info_loja.txt"
    exit 0
    ;;
-d | --download)
    ler_arquivo_texto
    baixar_atualizacoes
    exit 0
    ;;
-b | --backup)
    fazer_bkp
    verifica_backup
    exit 0
    ;;
-m | --menu)
    menu_principal
    exit 0
    ;;
-up | --update)
    # criar rotina pra baixar nova versao do atualizador.
    echo "Buscando update para o Atualizador..."
    update
    exit 0
    ;;
--man)
    man atualizador
    exit 0
    ;;
-o | --obter)
    # Busca no servidor a versao e release atualizada e exibi no terminal
    baixar_controle
    exit 0
    ;;
-r | --restore)
    echo "OPCAO DE RESTAURACAO"
    menu_restaura
    exit 0
    ;;
-l | --log)
    ler_logs
    exit 0
    ;;
-P)
    if [ $USER != avanco ] || [ $USER != root ]; then
        echo "Favor acionar o Suporte Avanco para realizar a configuracao"
        echo "" >>$auditoria
        echo "TENTATIVA DE ACESSAR CONFIGURACAO DO PARAMETROS" >>$auditoria
        echo "NO DIA $(date +'%d/%m/%Y') AS $(date +'%H:%M:%S') HORAS" >>$auditoria
        echo "USUARIO: $USER" >>$auditoria
        exit 0
    fi
    shift
    clear
    echo "PARAMETRIZACAO"
    parametros "$@"
    exit 0
    ;;
--cron)
    if [ $USER != root ]; then
        echo "Favor acionar o Suporte Avanco para realizar a configuracao"
        echo "" >>$auditoria
        echo "TENTATIVA DE ACESSAR CONFIGURACAO DO CRON" >>$auditoria
        echo "NO DIA $(date +'%d/%m/%Y') AS $(date +'%H:%M:%S') HORAS" >>$auditoria
        echo "USUARIO: $USER" >>$auditoria
        exit 0
    fi
    echo "CONFIGURACAO DO CRON"
    configurar_cron
    exit 0
    ;;
--atu-cron)
    atualizar_pelo_cron
    exit 0
    ;;
--permissoes)
    somente_permissao
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

# Chamandos as funcoes na ordem
#chmod 777 /u/sist/exec/*.gnt 2>>"$validados_gnt"
#validar_linux
verificar_dia
carregar_parametros
usuario_permitido
checar_internet
verifica_atualizacao
iniciar
verifica_logados
#chmod 777 /u/sist/exec/*.gnt 2>>"$validados_gnt"
limpa_exec
seguranca
ler_arquivo_texto >/dev/null 2>&1
atualizar
#chmod 777 /u/sist/exec/*.gnt 2>>"$validados_gnt"
gravando_atualizacoes
cobrun status-online.gnt "A" >/dev/null
#update > /dev/null
exit 0
