#!/bin/bash
#
################################################################################
# atualizador - Programa para atualizar o sistema Integral
#
# DATA: 13/04/2024 11:27 - Versao 0.4.0.3
# -------------------------------------------------------------------------------
# Autor: Luiz Gustavo <luiz.gustavo@avancoinfo.com.br>
# -------------------------------------------------------------------------------
# Controle de Versão:
#
# Versão 0.3.5: Ajustes de novas cores e condições de cores
# Versão 0.3.5a: Apontando o Help para dev/null
# Versão 0.3.6: Remoção de função de verificar programas no sist/exec, já esta
#               rodando no cron toda madrugada com a função permissoes
# Versão 0.4: Inicio de Refatoração de código
# Versão 0.4.0.1 : Colocado opção rar a -ep para não incluir todos os subdire-
#                  torios dentro do backup em sist/exec-a, gravando apenas os
#                  programas .gnt
# v0.4.0.2 - 06/11/2024 - Luiz Gustavo;
#          - Alteracoes em voltar o integral.gnt após atualizar
# v0.4.0.2a - 06/11/2024 - Luiz Gustavo;
#          - colocando -f em teste de se o programa integral.gnt foi renomeado
# v0.4.0.2b - 14/11/2024 - Luiz Gustavo;
#           - Funcão para criar diretorios somente se for avanco
#           - Alteracoes para executar chmod somente como avanco ou root
#           - Pequenas correções em mensagens de erros e avisos.
#           - Correções no ativar/desativar online, deixando o online conforme
#             foi iniciado, se ativo, liga o após terminar atualizacao, se desa-
#             tivado, nao faz alteracao no online
# v0.4.0.2c - 14/11/2024 - Luiz Gustavo;
#           - Opção no menu extras para baixar recursos extras
#           - Correção ortografica em nomes exibidos no log
#           - Mensagem para exibir onde foi gravado o log do atu-help
#           - Exibir mensagem de chamar ajuda ao errar argumento.
#
# v0.4.0.2d - 14/11/2024 - Luiz Gustavo;
#           - removido condição de permissão ao atualizar o atualizador
#
# v0.4.0.2e - 14/11/2024 - Luiz Gustavo;
#           - alterado para pacote.rar o atualizador
#
# v0.4.0.2f - 14/11/2024 - Luiz Gustavo;
#           - Melhoria na funcao nova_versao do atualizador
#
# v0.4.0.3  - 03/12/2024 - Luiz Gustavo;
#           - Correção em exit 1, ao não gravar log
#           - validação de usuário root para conceder permissão
#           - Correção para baixar xmlstarlet apenas para slackware
#
# -------------------------------------------------------------------------------
# Testado em:
#   bash 4.3.25 - slackware
#   bash 5.1.4(1) - Debian
# ---------------------------------------------------------------------------- #
# Este programa ira atualizar o Sistema Integral respeitando a versao do cobol e
# instalando versao e a release mais recentes. Apos isso ira executar o atu-help
# manual e dar permissao em /u/sist/exec/*gnt.
# O objetivo desse Programa e facilitar o dia-a-dia do clinte usuario Avanco!
################################################################################

versaoPrograma="0.4.0.3"
distro_nome=$(grep '^NAME=' /etc/os-release | cut -d '=' -f 2 | tr -d '"' | awk '{print $1}')
manual_uso="
Programa: $(basename "$0")

--------------------------------------------------------------------------------
                              [OPCOES DISPONIVEIS]

OPCOES NA LINHA DE COMANDO:
    -h,  --help         Mostrar esta tela de ajuda
    -a,  --ajuda        Mostrar esta tela de ajuda
    -V,  --version      Mostrar a versao do Atualizador
    --versao            Mostrar a versao do Atualizador
    -i,  --info         Mostrar a versao e release no servidor
    -d,  --download     Baixar Versao e Release
    --baixar-versao     Baixar somente o pacote da Versao atual
    --baixar-release    Baixar somente o pacote da Release atual
    -b,  --backup       Realizar o backup do 'sist/exec'
    -m,  --menu         Menu de opcoes do Atualizador
    -up, --update       Realizar update do Atualizador
    --man               Manual tecnico do Atualizador (em construcao)
    -o,  --obter        Obter detalhes de Versao e Release disponiveis no portal
                        Avanco
    -l,  --log          Visualizar principais logs do Atualizador
    -P                  Parametrizacao (somente para usuario 'avanco')
    --cron              Ativar no cron (somente para usuario 'avanco')
    --permissoes        Conceder permissao total no 'sist/exec' (somente para
                        usuario 'avanco')
    --testar-internet   Verifica se o servidor tem conexao com a Internet
    --online            Exibe e/ou altera o Online do vendas. Necessario infor-
                        mar o argumento:
                         '-L' - Para mostrar o status
                         '-A' - Para ativar o Online
                         '-D' - Para Desativar
    
    

MODO DE USAR:
Digite o nome do programa e a opcao desejada.
  Exemplo:
  $ atualizador --help
    'Exibir tela de ajuda.'

--------------------------------------------------------------------------------
"

### Configuração do Programa atualizador
CONFIG_ATUALIZADOR="/u/sist/controle/atualizador.config" # Parametrização do atualizador usando 0 e 1
### Use 0 (zero) para desligar as opções e 1 (um) para ligar
### Use 0 (zero) para não e 1 (um) para sim
### O padrão é o como mostrado abaixo
#
USAR_CORES=1      # mostrar cores nas mensagens?
NIVEL_MENSAGENS=2 # 0(zero) Nenhuma informação é exibida.
#                         1(um) Exibe o mínino necessário, apenas mensagens essencias
#                         2(dois) Exibe todas as informações.
ALERTA_SONORO=0 # habilita alerta sonoro em ações executadas?
#
### Chaves de teste
### As chaves abaixo são usadas para os testes do atualizador, definindo o que
### deverá ser feito
### Elas iniciarão quase todas por padrão 0, para ser testado as condições
### O padrão usado é com ch (chave) e o nome da chave
ch_versao_atualizada=0         # verifica se a versão está atualizada
ch_release_atualizada=0        # verifica se a release está atualizada
ch_esta_atualizado=0           # utilizado para validar o "info_loja"
ch_renomear_integralGNT=0      # renomeara o prog 'integral.gnt'
ch_carregar_parametros=1       # carrega os parametros e configuracoes
ch_pacote_descompactado=0      # verifica se o pacote foi descompactado
ch_chavear_online=1            # altera o online de clientes
ch_atualizacao_finalizada=0    # verifica se o programa foi bem executado
ch_deslogar_usuariaos=0        # envia uma mensagem para os usuários deslogarem
ch_impedir_logar_atualizando=0 # impede usuários logar durante a atualziacao
ch_avisar_atualizacoes=0       # avisa que existe nova atualização disponível
ch_notificar_extras=0          # utilizada para enviar atualizações extras
ch_baixar_automaticamente=0    # baixar os pacotes das atualizacoes
ch_instalar_automaticamente=0  # instala as atualizacoes pelo cron
ch_todos_podem_atualizar=0     # todos os usuários podem atualizar
ch_normal_atu_help=1           # para atualizar o help
ch_release_existe=""           # para validar se existe apenas versao total
#
### Fim da configuração - NÃO EDITE DAQUI PARA BAIXO
#
################################################################################

###############################
### VARIAVEIS GLOBAIS
#
### Sessão de datas
dia_semana_lido=$(date +%u) # dia que será testado para liberar atualizar ou não
hora_lida=$(date +%H)       # hora que será testada para liberar atualizar ou não
mes_ano=$(date +"%m%y")
mes_atual=$(date +"%m")
ano_atual=$(date +"%y")
mes_anterior=$(date -d "4 weeks ago" +"%m") # utilizado para limpar logs antigos
ano_anterior=$(date -d "4 weeks ago" +"%y") # utilizado para limpar logs antigos
date=$(date +"%d%m%y")
data_atual=$(date +"%d%m%y")   # data obtida ao rodar o script, sera sempre o dia atual
hora_atual=$(date +"%H:%M:%S") # hora para gravacoes necessarias
dia_hoje=$(date +"%Y%m%d")
#
### variáveis que armazenam os locais utilizados no sistema
#
info_loja_txt="/u/sist/controle/info_loja.txt"         # arquivo que grava informações da de verão e release da servidor
controle_ver_rel="/u/sist/controle/versao_release.txt" # arquivo que grava informações de versão e release do Portal Avanço
local_gnt="/u/sist/exec"                               # local dos programas gnt
removidos="/u/rede/avanco/removidos"                   # pasta que ficam os arquivos não permitidos no exec e que foram removidos do exec
pasta_destino="/u/rede/avanco/atualizacoes"            # local onde são realizados os downloads das atualizações
pasta_pacotes="/u/rede/avanco/atualizacoes/pacotes"
arquivo_versao_atual=""      # grava o nome do pacote.rar da versão
arquivo_release_atual=""     # grava o nome do pacote.rar da release
local_log="/u/sist/logs"     # arquivo de log
bkp_destino="/u/sist/exec-a" # local onde ficam os backups
#
### Sessão dos logs
### Arquivos de logs para leitura e gravação
teste_gnt_log="/u/sist/logs/testeGNT.log"             # grava o teste dos programas de permissão e dono e no fim da atualização limpa o arquivo
validados_gnt="/u/sist/logs/statusGNT.log"            # grava o nome dos programas que tiveram o teste falho
infos_extras="/u/sist/logs/infos_extras.log"          # grava informações de desempenho do servidor
auditoria="/u/sist/logs/auditoria.log"                # registro de auditoria, de tentativas forçadas de alteração ou ações não permitidas
log_file="/u/sist/logs/log_$(date +"%m%y").log"       # log de ações bem executadas
erro_log_file="/u/sist/logs/erro_$(date +"%m%y").log" # log de erro
log_cron_erro="/u/sist/logs/.cron-erro.log"           # log erro gravado pelo cron
#
### Arquivos de Parametrização
arquivo_parametros="/u/sist/controle/parametros.config" # Parametrização que pode ser alterada pelo programa, fora do script.
config_cron="/u/sist/controle/.config_cron.txt"         # Detalhes da configuração ativa no cron
#

### Validações de servidor
conta_usarios=$(ps ax | grep rts32 | grep -v 'grep' | wc -l) # verifica usuarios usando o integral
usuarios_permitidos=("root" "super" "avanco")                # usuários permitidos, independente dos parâmetros
#
#
### Parte web - Links
#
script_url="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/atualizador"
script_path="$0"
url_controle_versao_release="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/controle_ver_rel.txt"
url_versao_release="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/Atual/versao_release.txt"
url_gera_xml="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/extras/gera-xml-por-tag.sh"
url_xmlStarlet_Debian="https://github.com/ketteiGustavo/atualizador/blob/main/extras/xmlstarlet.Debian"
url_xmlStarlet_Slackware="https://github.com/ketteiGustavo/atualizador/blob/main/extras/xmlstarlet.Slackware"
URL_BASE_VERSAO40="https://s3.amazonaws.com/avancoprogramas/integral/versao40-"
URL_BASE_VERSAO41="https://s3.amazonaws.com/avancoprogramas/integral/versao41-"

URL_BASE_RELEASE40="https://s3.amazonaws.com/avancoprogramas/integral/release40-"
URL_BASE_RELEASE41="https://s3.amazonaws.com/avancoprogramas/integral/release-"

URL_ATUALIZADOV40=""
URL_ATUALIZADOV41=""

URL_ATUALIZADO_RELEASE=""

URL_BUSCAR_RELEASE=""
url_ajuda="https://raw.githubusercontent.com/ketteiGustavo/atualizador/testesHomologacao/manuais/manual-ajuda-rapida"
url_manual="https://raw.githubusercontent.com/ketteiGustavo/atualizador/testesHomologacao/manuais/atualizador.1"
#
### Variáveis de leitura
versaoCobol=""   # usada para armazenar o cobol, apos rodar cobrun integral
novoPortal=""    # armazena a versão atual disponível no site
releasePortal="" # armazena a data da release disponível no site
letraRelease=""  # armazena a letra da release disponível no site
versaoLoja=""    # armazena a versao no servidor do cliente
releaseLoja=""   # armazena a release no servidor do cliente
inf_versao=""    #
inf_release=""   # usada para obter a release digitada
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
#
### Variáveis extras
#
cronometro_start=$(date +'%H:%M:%S') # usada para validar o desempenho do atualizador no servidor
cronometro_start_volta=""            # usada para validar o desempenho do atualizador no servidor
cronometro_stop=""                   # usada para validar o desempenho do atualizador no servidor
cronometro_stop_volta=""             # usada para validar o desempenho do atualizador no servidor
tempo_gasto=""                       # grava o tempo gasto na execução
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

################################################################################
### Inicio das Funções - serão dividas em blocos
#
### VISUAL - necessários ter a chave $USAR_CORES ativa
# exibi mensagens de erro em vermelho

testar_cores() {
    if [ "$(tput colors)" -ge 8 ]; then
        USAR_CORES=1
        VERMELHO="\e[31m"
        VERDE="\e[32m"
        AMARELO="\e[33m"
        AZUL="\e[34m"
        MAGENTA="\e[35m"
        CIANO="\e[36m"
        CINZA="\e[37m"
        NEGRITO="\e[1m"
        PADRAO="\e[0m"
    else
        USAR_CORES=0
        USAR_CORES=0
        VERMELHO=""
        VERDE=""
        AMARELO=""
        AZUL=""
        MAGENTA=""
        CIANO=""
        CINZA=""
        NEGRITO=""
        PADRAO=""
    fi
}
testar_cores

avanco="
                                                          ${NEGRITO}${AZUL}##${PADRAO}
                                                        ${NEGRITO}${AZUL}####${PADRAO}
                                                      ${NEGRITO}${AZUL}######${PADRAO}
                                                    ${NEGRITO}${AZUL}########${PADRAO}
                        ${NEGRITO}${VERDE}------------${PADRAO}              ${NEGRITO}${AZUL}##########${PADRAO}
                      ${NEGRITO}${VERDE}------${PADRAO}                    ${NEGRITO}${AZUL}############${PADRAO}
                    ${NEGRITO}${VERDE}------${PADRAO}                    ${NEGRITO}${AZUL}##############${PADRAO}
                     ${NEGRITO}${VERDE}-----${PADRAO}                  ${NEGRITO}${AZUL}################${PADRAO}
                      ${NEGRITO}${VERDE}----${PADRAO}                ${NEGRITO}${AZUL}########  ########${PADRAO}
                        ${NEGRITO}${VERDE}----${PADRAO}            ${NEGRITO}${AZUL}########    ########${PADRAO}
                          ${NEGRITO}${VERDE}----${PADRAO}       ${NEGRITO}${AZUL}#########      ########${PADRAO}
                            ${NEGRITO}${VERDE}--${PADRAO}    ${NEGRITO}${AZUL}########          ########${PADRAO}
                              ${NEGRITO}${VERDE}--${PADRAO}${NEGRITO}${AZUL}########            ########${PADRAO}
                              ${NEGRITO}${AZUL}##${PADRAO}${VERDE}----${PADRAO}                  ${NEGRITO}${AZUL}######${PADRAO}
                            ${NEGRITO}${AZUL}######${PADRAO}${VERDE}----${PADRAO}                ${NEGRITO}${AZUL}######${PADRAO}
                          ${NEGRITO}${AZUL}####${PADRAO}        ${NEGRITO}${VERDE}----${PADRAO}            ${NEGRITO}${AZUL}######${PADRAO}
                        ${NEGRITO}${AZUL}####${PADRAO}              ${NEGRITO}${VERDE}--${PADRAO}
                      ${NEGRITO}${AZUL}####${PADRAO}                    ${NEGRITO}${VERDE}--${PADRAO}
                    ${NEGRITO}${AZUL}##${PADRAO}                            ${NEGRITO}${VERDE}--${PADRAO}
                  ${NEGRITO}${AZUL}##${PADRAO}                                    ${NEGRITO}${VERDE}--${PADRAO}
                                                                                
                                                                                
                                                                                
     ${NEGRITO}##         ##  ##         ##         ##    ##        #####        #####
   ##  ##       ##  ##       ##  ##       ####  ##       ##          ##    ##
   ##  ##       ##  ##       ##  ##       ##  ####       ##          ##    ##
   ##  ##         ##         ##  ##       ##    ##        #####       #####${PADRAO}
"
################################################################################
# exibe mensagens de erro em vermelho
erro_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${VERMELHO}[ERROR] - $1${PADRAO}"
    else
        echo "[ERROR] - $1"
    fi
}
# exibi mensagens de informacao em verde
info_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${VERDE}[INFO] - $1${PADRAO}"
    else
        echo "[INFO] - $1"
    fi
}
# exibi mensagens de alerta em amarelo
alerta_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${AMARELO}[ATENCAO] - $1${PADRAO}"
    else
        echo "[ATENCAO] - $1"
    fi
}
# exibe mensagens em vermelho
red_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${VERMELHO}$1${PADRAO}"
    else
        echo "$1"
    fi
}
# exibi mensagens em amarelo
yellow_msg() {
    if [ "$USAR_CORES" -eq 1 ]; then
        echo -e "${AMARELO}$1${PADRAO}"
    else
        echo "$1"
    fi
}

mensagem_saida() {
    tput smso
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
        echo "################################################################################" >>$auditoria
        echo "" >>$auditoria
        if [ "$flag_renomea" = true ]; then
            if [ -f /u/sist/exec/cogumeloAzul.gnt ]; then
                mv /u/sist/exec/cogumeloAzul.gnt /u/sist/exec/integral.gnt
            fi
        fi
        echo

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
### Controle de acesso
verificar_usuario() {
    if [[ "$USER" != "avanco" && "$USER" != "root" ]]; then
        echo "Favor acionar o Suporte Avanco para realizar a configuracao"
        echo "" >>"$auditoria"
        echo "================================================================================" >>"$auditoria"
        echo "PROGRAMA: $(basename "$0") --> parametrizacao atualizador " >>$auditoria
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "TENTATIVA DE ACESSAR CONFIGURACAO DOS PARAMETROS" >>"$auditoria"
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "$(date +'%d/%m/%Y') - $(date +'%H:%M')" >>$auditoria
        echo "USUARIO: $USER" >>"$auditoria"
        echo "" >>"$auditoria"
        exit 1
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
            ler_arquivo_texto >/dev/null 2>&1
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
            echo "$USER, O SEU USUARIO NAO TEM PERMISSAO DE EXECUTAR ESSA ROTINA"
            echo "" >>"$auditoria"
            echo "================================================================================" >>"$auditoria"
            echo "PROGRAMA: $(basename "$0") --> atualizar integral               $(date +'%d/%m/%Y') - $(date +'%H:%M')" >>$auditoria
            echo "--------------------------------------------------------------------------------" >>$auditoria
            echo "TENTATIVA DE ATUALIZAR INTEGRAL SEM PERMISSAO" >>"$auditoria"
            echo "--------------------------------------------------------------------------------" >>$auditoria
            echo "USUARIO: $USER" >>"$auditoria"
            echo "--------------------------------------------------------------------------------" >>$auditoria
            echo "" >>"$auditoria"
            exit 1
        fi
    fi
}
# funcao para verificar se o sistema foi atualizado no dia
verifica_atualizacao() {
    local_abortado="Verificando atualizacao"
    ler_arquivo_texto
    if [ "$flag_esta_atualizado" = true ]; then
        clear
        tput smso
        echo "                           O INTEGRAL ESTA ATUALIZADO                           "
        echo ""
        tput rmso
        stty sane
        mensagem_saida
        echo "" >>$auditoria
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >>$auditoria
        echo "PROGRAMA: $(basename "$0") --> atualizar integral               $(date +'%d/%m/%Y') - $(date +'%H:%M')" >>$auditoria
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "INTEGRAL ESTAVA ATUALIZADO NA TENTATIVA DE ATUALIZACAO" >>$auditoria
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "USUARIO: $USER" >>"$auditoria"
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "" >>"$auditoria"
        sleep 2
        exit 0
    else
        echo "Atualizando..." >/dev/null
        cronometro_start_volta=$SECONDS
    fi
}

# Funcao para verificar o dia da semana e hora
verificar_dia() {
    local_abortado="Validando dia"
    carregar_parametros

    if [ $dia_semana_lido -eq 5 ] || [ $dia_semana_lido -eq 6 ] || [ $dia_semana_lido -eq 7 ]; then
        clear
        tput smso
        echo "                     O SISTEMA NAO PODE SER ATUALIZADO HOJE!                    "
        echo ""
        echo "                        TENTE NOVAMENTE NA SEGUNDA-FEIRA!                       "
        tput rmso
        stty sane
        mensagem_saida
        echo "" >>"$auditoria"
        echo "================================================================================" >>"$auditoria"
        echo "PROGRAMA: $(basename "$0") --> atualizar integral               $(date +'%d/%m/%Y') - $(date +'%H:%M')" >>$auditoria
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "TENTATIVA DE ATUALIZAR INTEGRAL NO FIM DE SEMANA" >>"$auditoria"
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "USUARIO: $USER" >>"$auditoria"
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "" >>"$auditoria"
        exit 1
    fi

    if [[ "$permitir_pos18" = "S" ]]; then
        return
    else
        if [ $hora_lida -ge 18 ]; then
            clear
            tput smso
            echo "               FAVOR EXECUTAR A ATUALIZACAO EM HORARIO COMERCIAL!               "
            echo ""
            tput rmso
            stty sane
            mensagem_saida
            echo "" >>"$auditoria"
            echo "================================================================================" >>"$auditoria"
            echo "PROGRAMA: $(basename "$0") --> atualizar integral               $(date +'%d/%m/%Y') - $(date +'%H:%M')" >>$auditoria
            echo "--------------------------------------------------------------------------------" >>$auditoria
            echo "TENTATIVA DE ATUALIZAR INTEGRAL EM HORARIO NAO PERMITIDO" >>"$auditoria"
            echo "--------------------------------------------------------------------------------" >>$auditoria
            echo "USUARIO: $USER" >>"$auditoria"
            echo "--------------------------------------------------------------------------------" >>$auditoria
            echo "" >>"$auditoria"
            exit 1
        fi
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
        echo "" >>"$auditoria"
        echo "================================================================================" >>"$auditoria"
        echo "PROGRAMA: $(basename "$0") --> atualizar integral               $(date +'%d/%m/%Y') - $(date +'%H:%M')" >>$auditoria
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "TENTATIVA DE ATUALIZAR INTEGRAL EM HORARIO NAO PERMITIDO" >>"$auditoria"
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "USUARIO: $USER" >>"$auditoria"
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "" >>"$auditoria"
        exit 1
    fi
    sleep 2
}

## Online
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

# funcao para criar diretorio
criar_diretorio() {
    local dir=$1
    if [ ! -d "$dir" ] && [[ "$USER" = "avanco" ]]; then
        mkdir -p "$dir"
        chmod 777 -R "$dir"
    fi
}

# diretorios a serem criados/verificados
criar_diretorio "/u/rede/avanco/atualizacoes"
criar_diretorio "$removidos"
criar_diretorio "/u/sist/controle"
criar_diretorio "/u/sist/logs"

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

# Funcao para limpar qualquer arquivo ou pasta que esteja errado no sist/exec
limpa_exec() {
    local_abortado="Limpando sist/exec"
    local data_clear=$(date +'%d/%m/%Y')
    local destino_mover="/u/rede/avanco/removidos/limpeza-dia-$data_atual"
    local rar_file="$removidos/removidos_$data_atual.rar"
    local log_removidos="/u/sist/logs/removidos_$data_atual.log"
    local ch_fazer_backup_limpar=1

    # criar diretorio para receber arquivos
    mkdir -p "$destino_mover"

    if [ ! -f "$log_removidos" ]; then
        echo "Arquivos e Pastas que estavam no 'u/sist/exec' no dia $data_clear" >"/u/sist/logs/removidos_$data_atual.log"
    fi

    # faz a busca e move o que não for gnt para outra pasta
    find "$local_gnt" -type f ! -name "*.gnt" -exec mv {} "$destino_mover" \;

    # gera um log
    ls -lh "$destino_mover" >>"/u/sist/logs/removidos_$data_atual.log"

    # testa a pasta
    if [ -z "$(ls -A $destino_mover)" ]; then
        rmdir "$destino_mover"
        echo "PASTA EXEC VERIFICADA!!!"
        ch_fazer_backup_limpar=0
        rm -rf "/u/sist/logs/removidos_$data_atual.log"
        return 0
    fi

    # fazer backup se existir arquivos que foram movidos para a pasta
    if [ "$ch_fazer_backup_limpar" -eq 1 ]; then
        alerta_msg "!!!ATENCAO!!!"
        yellow_msg "   VERIFICANDO E REALIZANDO LIMPEZA DE ARQUIVOS DESNECESSARIOS NO 'sist/exec'  "
        yellow_msg "AGUARDE..."
        nohup rar a -ep "$rar_file" "$destino_mover" >/dev/null 2>>"$erro_log_file" &
        rar_pid=$!

        wait $rar_pid
        rm -rf "$destino_mover"
        echo "================================================================================" >>$auditoria
        echo "PROGRAMA: $(basename "$0") --> limpa-exec                       $(date +'%d/%m/%Y') - $(date +'%H:%M')" >>$auditoria
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "PROCESSO DE LIMPEZA REALIZADO" >>$auditoria
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "ARQUIVO DE LOG PARA CONSULTA: 'removidos_$data_atual.log' " >>$auditoria
        echo "LOCAL DO LOG: '/u/sist/logs' " >>$auditoria
        echo "EXECUTADO PELO USUARIO: $USER" >>$auditoria
        echo "" >>$auditoria
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
        echo "CONEXAO COM A INTERNET OK"
    else
        # Mensagem de erro centralizada
        clear
        tput cup $(($(tput lines) / 2)) $(($(tput cols) / 2 - 20))
        echo "NAO HA CONEXAO COM A INTERNET"
        echo "================================================================================" >>$auditoria
        echo "PROGRAMA: $(basename "$0") --> testa-internet             $(date +'%d/%m/%Y') - $(date +'%H:%M')" >>$auditoria
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "VERIFICANDO CONEXAO COM INTERNET - SEM CONEXAO" >>$auditoria
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "" >>$auditoria
        exit 1
    fi
}
## PARTE DE BACKUPS E VALIDAÇÕES
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
        if rar a -ep "$bkp_destino/BKPTOTAL_$date" $local_gnt/*gnt | while read -r line; do
            ((contagem_arquivo++))
            porcentagem_bkp=$((contagem_arquivo * 100 / total_bkp_files))
            barra_progresso $porcentagem_bkp
        done; then
            info_msg "Backup concluido!"
        else
            erro_msg "Erro ao realizar Backup em $date!"
            log_error "Erro ao relizar Backup em $date"
        fi
    fi

    find /u/sist/exec-a/ -name "BKPTOTAL_*" -type f -printf '%T@ %p\n' | sort -n | head -n -4 | cut -d' ' -f2- | while read file; do
        echo "No dia $(date +'%d/%m/%Y as %H:%M:%S') - o backup foi removido de: $file" >>/u/sist/logs/log-de-remocao.log
        rm -f "$file"
    done

}
#
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
            "S" | "s" | "")
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

    # testa se o programa versao-release.gnt existe, se sim extrai as informações através dele.
    if [ -f "/u/sist/exec/versao-release.gnt" ]; then
        verifica_cobol
        versaoCobol="$inf_versaoCobol"
        inf_versaoLoja=$(cobrun versao-release.gnt | grep -oP '\d{2}/\d{2}/\d{2}' | tr -d '/')
        inf_releaseLoja=$(cobrun versao-release.gnt | grep -oP '[a-zA-Z]$')
        inf_releaseLojaAntes="$inf_releaseLoja"

        data_release_servidor=$(grep -oP '(?<=DATA RELEASE: )\d+' "$info_loja_txt")
    else
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
    fi
    validar_ver_rel
}

# Funcao para verificar qual o cobol usado
verifica_cobol() {
    resultado=$(cobrun 2>&1)
    versaoCobol=$(echo "$resultado" | sed -n 's/V\([0-9]\+\.[0-9]\+\).*/\1/p')
    inf_versaoCobol="$versaoCobol"
}

# Funcao para validar a versao no portal e no cliente
validar_ver_rel() {
    local_abortado="Verificando se esta na versao atual"
    baixar_controle
    novoPortal=$(grep -oP '(?<=Versao atual: )\d+' "$controle_ver_rel")
    letraRelease=$(grep -oP '(?<=Release atual: )[A-Z]+' "$controle_ver_rel")
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
        if [[ "$letraRelease" == "VAZIO" ]]; then
            echo "INTEGRAL ESTA ATUALIADO"
            echo "mostrando letra $letraReleas"
            atualizado_flag=true
            flag_release=true
            echo "$atualizado_flag" >$controle_flag/controle_flag.txt
            flag_esta_atualizado=true
        elif [[ "$inf_releaseLoja" < "$letraRelease" ]]; then
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

# Função para ler o arquivo e armazenar as informações em variáveis
arquivo_versao_release_atual() {
    novoPortal=$(grep -oP '(?<=Versao atual: )\d+' "$controle_ver_rel")
    versao_Portal=$(grep -oP '(?<=Versao atual: )\d+' "$controle_ver_rel")
    release_busca=$(grep -oP '(?<=Release atual: [A-Z] )\d{6}' "$controle_ver_rel")
    data_release="$release_busca"
    release_busca_letra=$(grep -oP '(?<=Release atual: )[A-Z]+' "$controle_ver_rel")
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
# Funcao para controlar registro de logs
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
        echo -e "${VERMELHO}${NEGRITO}[ERROR]${PADRAO} - Erro ao escrever no arquivo de log." >>"$erro_log_file"
    fi
}

# Funcao para criar e ou atualizar o arquivo de logERRO com as informacoes padroes
log_error() {
    manter_log_erro_atual
    local error="$1"
    echo "$(date '+%d/%m/%Y %H:%M:%S') - $error" >>"$erro_log_file"
}

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

# Funcao para chamar o script que realiza o download
baixar_atualizacoes() {
    clear
    local_abortado="Processo de Download das atualizacoes"
    abortado_controle="download"
    if [ "$flag_versao" = "false" ]; then
        echo "$atualizado_flag" >$controle_flag/controle_flag.txt
        baixar_versao
        sleep 1
    fi

    if [ "$flag_release" = "false" ]; then
        echo "$atualizado_flag" >$controle_flag/controle_flag.txt
        baixar_release
        sleep 1
    fi
}
#
# Funcao para obter o link da versao atual, com base em comparacao de data por trimestre
baixar_versao() {
    verifica_cobol
    arquivo_versao_release_atual
    versaoBusca="$versao_Portal"
    # Verificando a versao do COBOL
    if [ "$versaoCobol" == "4.0" ]; then
        URL_BUSCAR_VERSAO="$URL_BASE_VERSAO40"
        cobolBusca="40"
    elif [ "$versaoCobol" == "4.1" ]; then
        URL_BUSCAR_VERSAO="$URL_BASE_VERSAO41"
        cobolBusca="41"
    else
        echo -e "${VERMELHO}${NEGRITO}[ERROR]${PADRAO} - VERSAO DO COBOL INVALIDA."
        exit 1
    fi

    URL_ATUALIZADO="$URL_BUSCAR_VERSAO$versaoBusca.rar"
    if curl -k --output /dev/null --silent --head --fail "$URL_ATUALIZADO"; then
        echo "REALIZANDO DOWNLOAD DA VERSAO!"
        curl -k -# -o "$pasta_destino/versao$cobolBusca-$versaoBusca.rar" "$URL_ATUALIZADO"
        echo -e "\nDOWNLOAD COMPLETO!"
        echo -e "\n\nREALIZANDO TESTE DE INTEGRIDADE"
        sleep 1
        arquivo_versao_atual=$(find "$pasta_destino" -maxdepth 1 -type f -name "versao$cobolBusca-$versaoBusca.rar")
        testar_arquivos_versao=$(rar t "$arquivo_versao_atual" | wc -l)
        arquivo_atual_testando=0
        if rar t $arquivo_versao_atual | while read -r line; do
            ((arquivo_atual_testando++))
            porcentagem=$((arquivo_atual_testando * 100 / testar_arquivos_versao))

            barra_progresso $porcentagem
        done; then
            versao_exibir=$(tratar_datas "$versaoBusca")
            echo "DOWNLOAD DA VERSAO '$versao_exibir' CONCLUIDO E PROGRAMAS 'TESTADOS'!"
        else
            echo "ARQUIVO CORROMPIDO!"
            echo "ARQUIVO DA VERSAO $versaoBusca CORROMPIDO!"
        fi
        return 0
    else
        erro_msg "NAO FOI POSSIVEL ENCONTRAR O LINK PARA DOWNLOAD DA VERSAO!"
    fi
    sleep 2
}
#
# Funcao para verificar se a release e valida e mais recente
baixar_release() {
    verifica_cobol
    arquivo_versao_release_atual
    arquivo_release_atual=""
    buscarV40="release40"
    buscarV41="release"

    local rel="${release_busca:0:4}"
    local ver="${versao_Portal:0:4}"

    # Verificando a versao do COBOL
    if [ "$versaoCobol" == "4.0" ]; then
        URL_BUSCAR_RELEASE="$URL_BASE_RELEASE40"
        cobolBusca="40"
        releaseBusca=$buscarV40
    elif [ "$versaoCobol" == "4.1" ]; then
        URL_BUSCAR_RELEASE="$URL_BASE_RELEASE41"
        cobolBusca="41"
        releaseBusca=$buscarV41
    else
        echo -e "${VERMELHO}${NEGRITO}[ERROR]${PADRAO} - VERSAO DO COBOL INVALIDA."
        exit 1
    fi

    if [[ "$ch_release_existe" = false ]]; then
        echo
        letraRelease=""
    else
        URL_ATUALIZADO_RELEASE="$URL_BUSCAR_RELEASE$ver-a-$rel.rar"
        if curl -k --output /dev/null --silent --head --fail "$URL_ATUALIZADO_RELEASE"; then
            echo "REALIZANDO DOWNLOAD DA RELEASE!"
            curl -k -# -o "$pasta_destino/$releaseBusca-$ver-a-$rel.rar" "$URL_ATUALIZADO_RELEASE"
            echo -e "\nDOWNLOAD COMPLETO!"

            arquivo_release_atual=$(find "$pasta_destino" -maxdepth 1 -type f -name "$releaseBusca-$ver-a-$rel.rar")
            echo -e "\n\nREALIZANDO TESTE DE INTEGRIDADE"
            sleep 1

            testar_arquivos_release=$(rar t "$arquivo_release_atual" | wc -l)
            release_release_testando=0

            if rar t $arquivo_release_atual | while read -r line; do
                ((release_atual_testando++))
                porcentagem=$((arquivo_release_testando * 100 / testar_arquivos_release))
                #barra_progresso $porcentagem
            done; then

                release_download=$(tratar_datas "$release_busca")
                echo -e "\n\nDOWNLOAD DA RELEASE '$letraRelease, DO DIA $release_download' CONCLUIDO E PROGRAMAS 'TESTADOS'!!"
            else
                echo "Arquivo corrompido!"
                echo "Arquivo de release '$release_download - $release' corrompido!"
            fi

            echo "PACOTE DE ATUALIZACAO BAIXADO!"
            return 0
        else
            erro_msg "NAO FOI POSSIVEL ENCONTRAR O LINK PARA DOWNLOAD DA RELEASE!"
        fi
    fi
    sleep 1
}
#
definirPacote_por_cobol() {
    local_abortado="Definindo pacotes para serem instalados"
    local ver="${novoPortal:0:4}"
    local rel="${data_release:0:4}"
    # Define o diretorio com base na versao do Cobol
    if [ "$versaoCobol" == "4.0" ]; then
        arquivo_versao_atual=$(find "$pasta_destino" -maxdepth 1 -type f -name "versao40-$novoPortal.rar")
        arquivo_release_atual=$(find "$pasta_destino" -maxdepth 1 -type f -name "release40-$ver-a-$rel.rar")
        sleep 1
    elif [ "$versaoCobol" == "4.1" ]; then
        arquivo_versao_atual=$(find "$pasta_destino" -maxdepth 1 -type f -name "versao41-$novoPortal.rar")
        arquivo_release_atual=$(find "$pasta_destino" -maxdepth 1 -type f -name "release-$ver-a-$rel.rar")
        sleep 1
    else
        erro_msg "Versao do Cobol desconhecida: $versaoCobol"
        echo "Versao do Cobol desconhecida: $versaoCobol" >>$erro_log_file
        exit 1
    fi
}

# Funcao para baixar arquivo atualizado
baixar_controle() {
    if [[ -f "/u/sist/controle/versao_release.txt" ]]; then
        rm -rf "/u/sist/controle/versao_release.txt"
    fi
    local_abortado="Baixando controle de versao/release"
    echo "OBTENDO DETALHES DA VERSAO E RELEASE"
    if curl -k --output /dev/null --silent --head --fail "$url_versao_release"; then
        curl -k -# -o /u/sist/controle/versao_release.txt "$url_versao_release"

        if [ $? -eq 0 ]; then
            chmod 666 /u/sist/controle/versao_release.txt
            clear
            echo "DETALHES DA VERSAO E RELEASE OBTIDOS!"
            novoPortal=$(grep -oP '(?<=Versao atual: )\d+' "$controle_ver_rel")
            letraRelease=$(grep -oP '(?<=Release atual: )[A-Z]+' "$controle_ver_rel")
            data_release=$(grep -oP '(?<=Release atual: [A-Z] )\d{6}' "$controle_ver_rel")
            data_tratada_novoPortal=$(tratar_datas "$novoPortal")

            echo ""
            echo "ATUALIZACAO DISPONIVEL NO PORTAL AVANCO"
            echo "VERSAO ATUAL: $data_tratada_novoPortal"

            # verifica se a release esta marcada como "VAZIO"
            if [[ "$letraRelease" == "VAZIO" ]]; then
                letraRelease="VAZIO"
                data_release="VAZIO"
                ch_release_existe=false
                echo "RELEASE ATUAL: "
                echo
                alerta_msg "Somente a versao sera considerada nessa atualizacao."
                echo
            else

                data_tratada_dt_release=$(tratar_datas "$data_release")
                echo "RELEASE ATUAL: $data_tratada_dt_release - $letraRelease"
                echo ""
                ch_release_existe=true
            fi

        else
            echo "ERRO AO OBTER VERSAO E RELEASE RECENTES!"
            rm -f /u/sist/controle/versao_release.txt
        fi
    else
        echo -e "${VERMELHO}${NEGRITO}[ERROR]${PADRAO} - NAO FOI POSSIVEL OBTER AS INFORMACOES DE VERSAO E RELEASE."
        rm -f /u/sist/controle/versao_release.txt
    fi
}
#
### Sessão atualização e gravar atualizações
#
# Função para controlar atu-help
chamar_atu_help() {
    local_abortado="Func. Atualizar: Atu-help iniciando"
    local log_atu_help="/u/sist/logs/atu-help.log"
    local err_atu_help="/u/sist/logs/atu-help.err"
    sleep 1
    echo
    echo "Aguarde... Atualizando o 'Help'..."
    echo "LOG ATUALIZACAO DO HELP - $(date +'%d/%m/%Y') - $(date +'%H:%M') - USUARIO: $USER " >$log_atu_help
    echo >>$log_atu_help
    echo "LOG ATUALIZACAO DO HELP ERROR - $(date +'%d/%m/%Y') - $(date +'%H:%M') - USUARIO: $USER " >$err_atu_help
    echo >>$err_atu_help
    echo
    test $ch_normal_atu_help -eq 1 && atu-help manual >>$log_atu_help 2>>$err_atu_help
    if [ $? -ne 0 ]; then
        erro_msg "ERRO AO EXECUTAR 'ATU-HELP MANUAL'."
        echo "Erro ao executar 'atu-help manual'! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
    elif [ $? -eq 1 ]; then
        echo -e "${VERDE}${NEGRITO}[INFO]${PADRAO} - Help Atualizado"
        echo
        echo -e "  Se desejar, consulte o log e log.erro do 'Help' em: "
        echo -e "  /u/sist/logs/ --> nomes: ${SUBLINHADO}atu-help.log${PADRAO} e ${SUBLINHADO}atu-help.err${PADRAO}"
    fi
    local_abortado="Func. Atualizar: Atu-help finalizado"
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
    clear
    if [ "$atualizado_flag" != "true" ]; then
        fazer_bkp
        verifica_backup
    fi
    local_abortado="Func. Atualizar: Pre descompactacao"
    sleep 1
    clear
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
                barra_progresso $percent
            done; then
                info_msg "ATUALIZACAO DE VERSAO CONCLUIDA!"
                flag_pacote_descompactado=true
                versaoLoja="$novoPortal"

                rm -rf "$arquivo_versao_atual"
                info_msg "VERSAO ATUALIZADA PARA: '$novoPortal'"
                sleep 1
                if [[ "$ch_release_existe" = false ]]; then
                    # se for false, condições para serem gravadas
                    flag_pacote_descompactado=true
                    inf_releaseLoja=""
                    data_release=""
                    letraRelease=""

                else
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
                            barra_progresso $porcento
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
                fi
            else
                local_abortado="Func. Atualizar: Tentativa de descompactar"
                alerta_msg "NOVA VERSAO DISPONIVEL, MAS NAO FOI POSSIVEL ATUALIZAR. ENTRE EM CONTATO COM O SUPORTE AVANCO!"
                echo "Nova Versao Disponivel, mas nao foi possivel atualizar. Entre em contato com o suporte Avanco! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$erro_log_file
                exit 1
            fi
        fi
    elif [ "$inf_versaoLoja" == "$novoPortal" ]; then
        if [[ "$ch_release_existe" = false ]]; then
            echo "INTEGRAL ATUALIZADO!"
            flag_pacote_descompactado=true
            inf_releaseLoja=""
            data_release=""
        else
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
                        barra_progresso $porcento
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
        fi
    else
        local_abortado="Func. Atualizar: Validado que esta atualizado"
        echo "INTEGRAL JA ESTA COM VERSAO E RELEASE MAIS RECENTES!"
        echo "INTEGRAL JA ESTA COM VERSAO E RELEASE MAIS RECENTES! $(date +'%d/%m/%Y') - $(date +"%H:%M:%S")" >>$log_file
    fi

    sleep 1
    local_abortado="Func. Atualizar: Atu-help iniciando"
    echo "Aguarde..."
    chamar_atu_help
    baixar_extras
    info_msg "ATUALIZACAO REALIZADA COM SUCESSO!"
    rm -rf "$controle_flag/controle_flag.txt"
    local_abortado="Func. Atualizar: Fim"
    fim_atualizacao=true
    ativar_desativar_online
    if [ -f /u/sist/exec/cogumeloAzul.gnt ]; then
        mv /u/sist/exec/cogumeloAzul.gnt /u/sist/exec/integral.gnt
    fi
    log_info "ATUALIZACAO REALIZADA PELO ATUALIZADOR"
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

        if [ "$flag_load_parametros" = true ] && [[ "$logar_atualizando" == "N" ]]; then
            if [ -f /u/sist/exec/cogumeloAzul.gnt ]; then
                mv /u/sist/exec/cogumeloAzul.gnt /u/sist/exec/integral.gnt
            fi
        fi

        echo
        echo "INFORMACOES GRAVADAS COM SUCESSO!"
        echo
        echo "SISTEMA ATUALIZADO EM $data_configuracao"
    else
        echo -e "${VERMELHO}${NEGRITO}[ERROR]${PADRAO} - NAO FOI POSSIVEL GRAVAR AS INFORMACOES. $(date +"%d/%m/%Y") - $(date +"%H:%M")"
        echo "NAO FOI POSSIVEL GRAVAR AS INFORMACOES. $(date +"%d/%m/%Y") - $(date +"%H:%M")" >>$erro_log_file
    fi

    cronometro_start=$cronometro_start
    cronometro_stop="$(date +'%H:%M:%S')"
    cronometro_stop_volta=$SECONDS
    tempo_gasto=$((cronometro_stop_volta - cronometro_start_volta))
    tempo_gasto_formatado=$(date -u -d @${tempo_gasto} +"%M min e %S seg")
    echo "      $(date +"%d/%m/%y")      -      $cronometro_start      -    $cronometro_stop      -  $tempo_gasto_formatado  " >>"/u/sist/logs/infos_extras.log"
    echo "--------------------------------------------------------------------------------" >>"/u/sist/logs/infos_extras.log"
    echo -e "$avanco"
    sleep 2
}
### Funções extras
## Barra de progresso
barra_progresso() {
    local progresso=$1
    progresso=$((progresso > 100 ? 100 : progresso)) # Garante que o valor máximo seja 100

    # Define o espaço necessário para a palavra "PROGRESSO: []" e a porcentagem
    local label_space="PROGRESSO: []"
    local percent_space=" 100%"

    # Calcula o tamanho da barra com base no tamanho do terminal
    local cols=$(tput cols)
    local bar_size=$((cols - ${#label_space} - ${#percent_space}))

    # Calcula a posição atual da barra
    local pos=$((progresso * bar_size / 100))

    # Gera a barra de progresso
    local barra=""
    for ((j = 0; j < pos; j++)); do
        barra+="#"
    done
    for ((j = pos; j < bar_size; j++)); do
        barra+="."
    done

    # Exibe a barra de progresso na mesma linha
    echo -ne "\rPROGRESSO: [$barra] $progresso%"
}

# Função para baixar ajuda rapida atualizada
mostrar_ajuda() {
    TMP_ajuda=$(mktemp /tmp/ajuda-atualizador.XXXXXX)
    TMP_manual=$(mktemp /tmp/manual-atualizador.XXXXXX)
    local $1
    $url_ajuda
    $url_manual
    clear
    if [ $1 = 1 ]; then
        echo
        if curl -k --output /dev/null --silent --head --fail "$url_ajuda"; then
            curl -k -# -o "$TMP_ajuda" "$url_ajuda"
            if [ $? -eq 0 ]; then
                chmod 444 "$TMP_ajuda"
                cat "$TMP_ajuda"
            else
                echo "ERRO AO LER MANUAL DE AJUDA."
                rm -f "$TMP_ajuda"
                exit 1
            fi
        else
            echo "ERRO: A URL DO MANUAL NAO ESTA ACESSIVEL."
            rm -f "$TMP_ajuda"
            exit 1
        fi
    elif [ $1 = 2 ]; then
        echo
        if curl -k --output /dev/null --silent --head --fail "$url_manual"; then
            curl -k -# -o "$TMP_manual" "$url_manual"
            if [ $? -eq 0 ]; then
                chmod 444 "$TMP_manual"
                cat "$TMP_manual"
            else
                echo "ERRO AO LER MANUAL DE AJUDA."
                rm -f "$TMP_manual"
                exit 1
            fi
        else
            echo "ERRO: A URL DO MANUAL NAO ESTA ACESSIVEL."
            rm -f "$TMP_manual"
            exit 1
        fi
    else
        echo "OPCAO INVALIDA"
    fi

    rm -rf /tmp/manual-atualizador.*
    rm -rf /tmp/ajuda-atualizador.*
}

# Funcao para atualizar o script sempre para a versao mais recente
nova_versao() {
    local url_teste_versao="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/controle/versao-atualizador.txt"
    local url_atualizador="https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/programa/atualizador.rar"

    clear
    if curl -k --output /dev/null --silent --head --fail "$url_teste_versao"; then
        curl -k -s -o "/tmp/versao_remota.txt" "$url_teste_versao"
        versao_do_atualizador=$(cat /tmp/versao_remota.txt)
    else
        erro_msg "ERRO: NAO FOI POSSIVEL OBTER DETALHES DE NOVA VERSAO DO ATUALIZADOR."
        exit 1
    fi

    # comparando versoes do atualizador
    if [ $versaoPrograma != $versao_do_atualizador ]; then
        cp "/u/bats/atualizador" "/u/bats/atualizadorOLD"
        echo "BAIXANDO VERSAO MAIS RECENTE DO ATUALIZADOR"
        if curl -k --output /dev/null --silent --head --fail "$url_atualizador"; then
            curl -k -L -# -o "/u/bats/atualizador.rar" "$url_atualizador"
            echo ""
            rar e -o+ -idq "/u/bats/atualizador.rar" "/u/bats"
            if [ $? -eq 0 ]; then
                rm -rf /u/bats/atualizador.rar
            else
                echo -e "[ERRO] - Falha ao extrair o arquivo."
                cp "/u/bats/atualizadorOLD" "/u/bats/atualizador"
                exit 1
            fi
            echo "EXECUTE O ATUALIZADOR NOVAMENTE!"
            if [ -f "/u/bats/baixarAtualizacao" ]; then
                rm -f "/u/bats/baixarAtualizacao"
            fi
            sleep 1
            exit 0
        else
            echo -e "${VERMELHO}${NEGRITO}[ERROR]${PADRAO} - A URL DO ATUALIZADOR NAO ESTA ACESSIVEL."
            rm -f "/u/bats/atualizador"
            cp "/u/bats/atualizadorOLD" "/u/bats/atualizador"
            exit 1
        fi
    else
        echo "Atualizador na versao atual"
        echo
        echo "-Versao: $versaoPrograma"
        echo
        exit 0
    fi
}

# Funcao para somente conceder permissão e mudar dono e grupo
somente_permissao() {
    chmod 777 /u/sist/exec/*.gnt
    chown avanco:sist /u/sist/exec/*
    chown avanco.sist /u/sist/logs/*
    chown avanco.sist /u/sist/controle/*
    chmod 777 -R /u/sist/logs/*
    chmod 777 -R /u/sist/controle/*
    adicionar_cron_avanco
}

# Função para criar rotina no crontab da avanco
adicionar_cron_avanco() {
    local cron_job="0 6,20 * * * . /etc/profile ; /u/bats/atualizador --testar-atualizado >/dev/null 2>&1"
    local comentario="# ATUALIZADOR AUTOMATICO - TESTAR SE FOI ATUALIZADO MANUALMENTE - NAO REMOVER"

    # backup do cron antes da modificação
    echo "NAO REMOVER E NAO ALTERAR" >/u/sist/controle/bkp-cron-avanco.txt
    crontab -u avanco -l >>/u/sist/controle/bkp-cron-avanco.txt

    if ! crontab -u avanco -l | grep -q "/u/bats/atualizador --testar-atualizado"; then
        (
            crontab -u avanco -l
            echo ""
            echo "$comentario"
            echo "$cron_job"
        ) | crontab -u avanco -
    fi
}

# Função para testar se o Integral está atualizado e gravar no log
testar_atualizado() {
    baixar_controle >/dev/null 2>&1

    if [ ! -f "/u/sist/exec/versao-release.gnt" ]; then
        echo "PROGRAMA 'versao-release.gnt' NAO ENCONTRADO!" >>$erro_log_file
        return 1
    fi

    # lendo o que está gravado no arquivo do atualizador
    local data_atualizacao_gravada=$(grep -oP '(?<=DATA: )\d+/\d+/\d+' "$info_loja_txt")
    local cobol_gravado=$(grep -oP '(?<=VERSAO COBOL: )\d+.\d+' "$info_loja_txt")
    local versaoLoja_gravada=$(grep -oP '(?<=VERSAO INTEGRAL: )\d+' "$info_loja_txt")
    local releaseLoja_gravada=$(grep -oP '(?<=RELEASE: )[[:alpha:]]' "$info_loja_txt")
    local data_release_servidor_gravada=$(grep -oP '(?<=DATA RELEASE: )\d+' "$info_loja_txt")

    # lendo o que é gerado através do versao-release.gnt
    local versaoLoja_testado=$(cobrun versao-release.gnt | grep -oP '\d{2}/\d{2}/\d{2}' | tr -d '/')
    local releaseLoja_testado=$(cobrun versao-release.gnt | grep -oP '[a-zA-Z]$')

    # datas tratadas para comparacao em formato YYYYMMDD
    local versaoLoja_gravada_ttd=$(converter_datas "$versaoLoja_gravada")
    local versaoLoja_testado_ttd=$(converter_datas "$versaoLoja_testado")

    # gravando detalhes do versao-release.gnt
    local possivel_hora=$(ls -lh versao-release.gnt | awk '{print $8}')
    local possivel_dia=$(stat -c %y versao-release.gnt | cut -d'-' -f3 | cut -d' ' -f1)
    local possivel_mes=$(stat -c %y versao-release.gnt | cut -d'-' -f2)
    local possivel_ano=$(stat -c %y versao-release.gnt | cut -d'-' -f1)

    if [ "$releaseLoja_testado" == "$letraRelease" ]; then
        data_release_testado="$data_release"
    fi

    if [ "$versaoLoja_gravada_ttd" != "$versaoLoja_testado_ttd" ]; then
        echo "################################################################################" >>$log_file
        echo "- INFORMACAO GRAVADA EM: $(date +'%d/%m/%Y') - $(date +'%H:%M:%S')" >>$log_file
        echo "- POSSIVEL ATUALIZACAO MANUAL" >>$log_file
        echo "- DETALHES DE QUANDO OCORREU POSSIVEL ATUALIZACAO: " >>$log_file
        echo "- DATA: $possivel_dia/$possivel_mes/$possivel_ano - HORA: $possivel_hora"
        echo "" >>$log_file
        echo "- VERSAO COBOL: $cobol_gravado" >>$log_file
        echo "- DATA DA ULTIMA ATUALIZACAO EXECUTADA PELO ATUALIZADOR: $data_atualizacao_gravada" >>$log_file
        echo "- POSSIVEL VERSAO INTEGRAL ANTES: $versaoLoja_gravada" >>$log_file
        echo "- POSSIVEL RELEASE INTEGRAL ANTES: $releaseLoja_gravada" >>$log_file
        echo "" >>$log_file
        echo "- POSSIVEL VERSAO INSTALADA: $versaoLoja_testado" >>$log_file
        echo "- POSSIVEL RELEASE INSTALADA: $data_release_testado - $releaseLoja_testado" >>$log_file
        echo "################################################################################" >>$log_file
    else
        if [ "$releaseLoja_gravada" != "$releaseLoja_testado" ]; then
            echo "################################################################################" >>$log_file
            echo "- INFORMACAO GRAVADA EM: $(date +'%d/%m/%Y') - $(date +'%H:%M:%S')" >>$log_file
            echo "- POSSIVEL ATUALIZACAO MANUAL" >>$log_file
            echo "- DETALHES DE QUANDO OCORREU POSSIVEL ATUALIZACAO: " >>$log_file
            echo "- DATA: $possivel_dia/$possivel_mes/$possivel_ano - HORA: $possivel_hora" >>$log_file
            echo "" >>$log_file
            echo "- VERSAO COBOL: $cobol_gravado" >>$log_file
            echo "- POSSIVEL VERSAO INTEGRAL ANTES: $versaoLoja_gravada" >>$log_file
            echo "- POSSIVEL RELEASE INTEGRAL ANTES: $releaseLoja_gravada" >>$log_file
            echo "" >>$log_file
            echo "- POSSIVEL VERSAO INSTALADA: $versaoLoja_testado" >>$log_file
            echo "- POSSIVEL RELEASE INSTALADA: $data_release_testado - $releaseLoja_testado" >>$log_file
            echo "################################################################################" >>$log_file
        fi
    fi
}

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
            rm -rf $arquivo_parametros
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
                rm -rf $arquivo_parametros
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
        permitir_pos18=$(grep -oP '^PERMITIR ATUALIZAR APOS 18H - \K\S+' "$arquivo_parametros")
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
        permitir_pos18=$(grep -oP '^PERMITIR ATUALIZAR APOS 18H - \K\S+' "$arquivo_parametros")
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
        echo "PERMITIR ATUALIZAR APOS 18H - N" >>$arquivo_parametros
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

default_parametros() {
    echo "DESLOGAR USUARIOS - N" >$arquivo_parametros
    echo "LOGAR ATUALIZANDO - N" >>$arquivo_parametros
    echo "AVISAR ATUALIZACAO - N" >>$arquivo_parametros
    echo "AVISAR EXTRAS - N" >>$arquivo_parametros
    echo "BAIXAR AUTOMATICAMENTE - N" >>$arquivo_parametros
    echo "INSTALAR AUTOMATICAMENTE - N" >>$arquivo_parametros
    echo "PERMITIR ATUALIZAR APOS 18H - N" >>$arquivo_parametros
    echo "TODOS AUTORIZADOS - N" >>$arquivo_parametros
    echo "AUTORIZADOS - avanco" >>$arquivo_parametros
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
            alerta_msg "ESSE RECURSO ESTARA DISPONIVEL EM BREVE!!!"
            menu_principal
            return 1
            #clear
            #echo "REVERTER ATUALIZACAO"
            #menu_restaura
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
            chamar_atualizacao
            sleep 1
            clear
            ;;
        2)
            clear
            alerta_msg "ESSE RECURSO ESTARA DISPONIVEL EM BREVE!!!"
            menu_principal
            return 1
            #clear
            #tput cup 4 29
            #echo "INFORME O ID DO PACOTE"
            #informar_pacote
            ;;
        3)
            clear
            alerta_msg "ESSE RECURSO ESTARA DISPONIVEL EM BREVE!!!"
            menu_principal
            return 1
            #clear
            #tput cup 4 27
            #echo "LISTAR PACOTE DISPONIVEIS"
            #verificar_pacote
            ;;
        4)
            clear
            alerta_msg "ESSE RECURSO ESTARA DISPONIVEL EM BREVE!!!"
            menu_principal
            return 1
            #clear
            #tput cup 4 29
            #echo "INSIRA O LINK ABAIXO: "
            #baixar_via_link
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
            fazer_bkp
            verifica_backup
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
        echo " 4  -  TESTAR CONEXAO INTERNET"
        tput cup 12 22
        echo " 5  -  VERIFICAR ONLINE DE VENDAS"
        tput cup 13 22
        echo " 6  -  AVISAR ATUALIZACAO"
        tput cup 14 22
        echo " 7  -  Baixar Extras"
        tput cup 15 22
        echo " 9  -  MENU PRINCIPAL"
        tput cup 16 22
        echo "99  -  SAIR"
        tput cup 18 26
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
            echo "CONCEDENDO PERMISSAO TOTAL AO INTEGRAL"
            if [ $USER = avanco ] || [ $USER = root ]; then
                chmod 777 /u/sist/exec/*.gnt 2>>"$validados_gnt"
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
            checar_internet
            ;;
        5)
            clear
            testar_online
            ;;
        6)
            clear
            alerta_msg "ESSE RECURSO ESTARA DISPONIVEL EM BREVE!!!"
            menu_principal
            return 1
            #yellow_msg "!!!ATENCAO!!!"
            #yellow_msg "SERA ENVIADO UMA MENSAGEM PARA OS USUARIOS LOGADOS"
            #yellow_msg "QUE O INTEGRAL SERA ATUALIZADO EM INSTANTES!!!"
            ;;
        7)
            clear
            baixar_extras
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
            #mostrar_ajuda 1
            echo "$manual_uso"
            ;;
        2)
            #clear
            #mostrar_ajuda 2
            clear
            alerta_msg "ESSE RECURSO ESTARA DISPONIVEL EM BREVE!!!"
            menu_principal
            return 1
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

# Funcao para corrigir erros do atualizador
menu_correcoes() {
    local opcao_menu
    clear
    while true; do
        tput cup 5 24
        echo -ne "\e[1;36mMENU DE CORRECOES DO ATUALIZADOR\e[0m"
        tput cup 8 22
        echo " 1  -  INFORMAR VERSAO E RELEASE"
        tput cup 9 22
        echo " 2  -  PERMISSAO TOTAL NO sist/exec"
        tput cup 10 22
        echo " 3  -  LIMPAR EXEC"
        tput cup 11 22
        echo " 4  -  LIBERAR ACESSO AO INTEGRAL"
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
            echo "SERA NECESSARIO INFORMAR A VERSAO E RELEASE!"
            criar_info_loja
            ;;
        2)
            clear
            echo "CONCEDENDO PERMISSAO TOTAL AO INTEGRAL"
            if [ "$(id -u)" -ne 0 ] || [ $USER = avanco ] || [ $USER = root ]; then
                somente_permissao
            else
                yellow_msg "FAVOR ACIONAR O SUPORTE AVANCO PARA CONCEDER AS PERMISSOES"
                exit 1
            fi
            ;;
        3)
            clear
            echo "LIMPANDO ARQUIVOS DESNECESSARIOS DENTRO DO sist/exec"
            limpa_exec
            ;;

        4)
            clear
            if [ -f "/u/sist/exec/cogumeloAzul.gnt" ]; then
                mv /u/sist/exec/cogumeloAzul.gnt /u/sist/exec/integral.gnt
                echo "FAVOR ACESSAR O INTEGRAL NOVAMENTE!"
                echo "UTILIZE O COMANDO:"
                echo "cobrun integral"
                exit 0
            fi
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

# Função para verificar pacotes disponiveis na pasta /u/rede/avanco/atualizacoes/pacotes
verificar_pacote() {
    local testar_existe

    if [ ! -d "/u/rede/avanco/atualizacoes/pacotes" ]; then
        mkdir -p /u/rede/avanco/atualizacoes/pacotes
    fi

    testar_existe=$(ls /u/rede/avanco/atualizacoes/pacotes | wc -l)

    if [ "$testar_existe" -eq 0 ]; then
        yellow_msg "NAO EXISTE NENHUM PACOTE DISPONIVEL NA PASTA CORRETA!"
        echo "FAVOR COLOCAR O PACOTE EM: "
        echo "/u/rede/avanco/atualizacoes/pacotes"
    else
        instalar_pacotes
    fi
}

# Função para instalar os pacotes verificados
instalar_pacotes() {
    clear
    local pacote_disponivel
    echo "EXISTEM OS SEGUINTES PACOTES: "
    tput cup 0 62
    echo "[M]enu ou [S]air"
    pacote_disponivel=$(ls -p /u/rede/avanco/atualizacoes/pacotes | grep -v /)
    select pacote in ${pacote_disponivel}; do
        if [ "$REPLY" = "S" ] || [ "$REPLY" = "s" ]; then
            exit 0
        elif [ "$REPLY" = "M" ] || [ "$REPLY" = "m" ]; then
            menu_principal
        fi

        if [[ -n $pacote ]]; then
            echo "SERA INSTALADO O PACOTE: $pacote"

            rar lb /u/rede/avanco/atualizacoes/pacotes/$pacote >/tmp/gnt-pacote-$pacote.txt

            echo "REALIZANDO BACKUP DO(S) PROGRAMA(S)... AGUARDE"
            while read -r arquivo; do
                if [ -f "/u/sist/exec/$arquivo" ]; then
                    rar a /u/sist/exec-a/bkpADP$pacote "/u/sist/exec/$arquivo"
                else
                    echo "O '$arquivo' NAO EXISTE NO '/u/sist/exec'."
                fi
            done </tmp/gnt-pacote-$pacote.txt

            echo "DESCOMPACTANDO O PACOTE '$pacote'... AGUARDE"
            rar e -o+ /u/rede/avanco/atualizacoes/pacotes/$pacote /u/sist/exec
            # Remover o arquivo temporário após o backup e extração
            rm -f /tmp/gnt-pacote-$pacote.txt
            echo
            echo "PACOTE $pacote INSTALADO COM SUCESSO!!!"
            echo
            read -p "DESEJA REMOVER O PACOTE INSTALADO? [S/n]" confirma_remocao
            case $confirma_remocao in
            "S" | "s" | "")
                rm -f /u/rede/avanco/atualizacoes/pacotes/$pacote
                ;;
            "N" | "n")
                return 1
                ;;
            *)
                clear
                echo "OPCAO INVALIDA!"
                ;;
            esac
        else
            echo "OPCAO ESCOLHIDA INVALIDA. TENTE NOVAMENTE."
        fi
    done
}

# Função para baixar atualizar para ser compilado.
preparar_compilado() {
    senha_hash="4c7eb6992c2cbd574ac6e48b96ca8a6926b5d6c02efce08e382728e4197ca506"

    read -sp "DIGITE A SENHA: " senha_digitada
    echo
    senha_digitada_hash=$(echo -n "$senha_digitada" | sha256sum | awk '{print $1}')

    if [ "$senha_digitada_hash" == "$senha_hash" ]; then
        echo "Iniciando Download para compilacao..."
        curl -L -o /u/login-suporte/luizgustavo/atualizador.Compilar https://raw.githubusercontent.com/ketteiGustavo/atualizador/refs/heads/main/codigo/atualizador.Compilar.sh
        if [ $? -eq 0 ]; then
            cd /u/login-suporte/luizgustavo/shc-master/src/
            ./shc -f "/u/login-suporte/luizgustavo/atualizador.Compilar" -ro "/u/login-suporte/luizgustavo/atualizador.Compilado"
            ls -lh /u/login-suporte/luizgustavo/atualizador.Compilado
            rm -rf /u/login-suporte/luizgustavo/atualizador.Compilar
        else
            echo "NAO FOI POSSIVEL BAIXAR O ATUALIZADOR PARA COMPILAR"
        fi
    else
        red_msg "SENHA INCORRETA!!!"
        red_msg "ROTINA NAO AUTORIZADA"
        echo "TENTATIVA DE UTILIZAR COMPILADOR. USUARIO: $USER - DATA: $(date +'%d/%m/%Y %H:%M')" >>/u/rede/avanco/luizgustavo/atualizador.log
        exit 1
    fi
}

# Função para ativar, editar, mostrar, desativar ou remover configuração do crontab
configurar_cron() {
    local cron_command=". /etc/profile; /u/bats/atualizador --atu-cron"

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
            if crontab -l | grep -Fq "$cron_command"; then
                if crontab -l | grep -Fq "#.*$cron_command"; then
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
            if crontab -l | grep -Fq "$cron_command"; then
                echo "# ATUALIZADOR AUTOMATICO - NAO REMOVER - NAO ALTERAR"
                crontab -l | grep "$cron_command"
                if [ -f "$config_cron" ]; then
                    more "$config_cron"
                    echo
                else
                    echo "NAO FOI ENCONTRADO O ARQUIVO DA CONFIGURACAO QUE ESTA NO CRON!"
                fi
            else
                echo "NAO FOI ENCONTRADO NO CRON A CONFIGURACAO!"
                rm -rf "$config_cron" 2>>/dev/null
            fi
            ;;
        4)
            # Desativar atualizador no cron
            if crontab -l | grep -Fq "$cron_command"; then
                if ! crontab -l | grep -Fq "^#.*$cron_command"; then
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
            "terca" | "ter")
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
                    echo "# ATUALIZADOR AUTOMATICO - NAO REMOVER - NAO ALTERAR"
                    echo "0 $hora_informada * * $dia_definido . /etc/profile; /u/bats/atualizador --atu-cron 2>> /u/sist/logs/.cron-erro.log"
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
    export TERM=xterm
    if [ "$(id -u)" -ne 0 ]; then
        clear
        tput smso
        echo "ACESSO NEGADO!!!"
        sleep 2
        tput rmso
        echo "" >>"$auditoria"
        echo "================================================================================" >>"$auditoria"
        echo "PROGRAMA: $(basename "$0") --> configuracoes do crontab" >>$auditoria
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "TENTATIVA DE ACESSAR CONFIGURACAO DO CRONTAB" >>"$auditoria"
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "$(date +'%d/%m/%Y') - $(date +'%H:%M')" >>$auditoria
        echo "USUARIO: $USER" >>"$auditoria"
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "" >>"$auditoria"
        exit 1
    else

        inf_versaoCobol=$(grep -oP '(?<=VERSAO COBOL: )\d+.\d+' "$info_loja_txt")
        versaoCobol="$inf_versaoCobol"
        ch_normal_atu_help=0
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
# funcao em testes
ativar_no_cron() {
    (
        crontab -l
        echo ""
        echo "# ATUALIZADOR AUTOMATICO - RECURSOS EXTRAS - NAO REMOVER #"
        echo "0 9,11,14,16 * * 1-4 /u/bats/atualizador --extras-atualizador >/dev/null 2>> /u/sist/logs/.erro-cron.log"
        echo "30 9,14 * * 1-4 /u/bats/atualizador --extras-atualizador >/dev/null 2>> /u/sist/logs/.erro-cron.log"
        echo ""
    ) | crontab -

}

# Função para chamar opção de atualização na ordem
chamar_atualizacao() {
    clear
    echo "ATUALIZAR"
    verificar_dia
    carregar_parametros
    usuario_permitido
    checar_internet
    verifica_atualizacao
    iniciar
    ler_arquivo_texto
    limpa_exec
    atualizar
    ler_arquivo_texto >/dev/null 2>&1
    gravando_atualizacoes
    ativar_desativar_online
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
        echo "Falha na autenticacao. Encerrando o atualizador."
        exit 1
    fi

    echo "BACKUPS DISPONIVEIS:                             (9) para menu ou (99) para sair"
    echo ""
    backups=$(ls ${bkp_destino}/BKPTOTAL_* | sort)
    select backup in ${backups}; do
        if [ "$REPLY" = "99" ]; then
            exit 0
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
        erro_msg "NAO FOI POSSIVEL ENCONTRAR AS INFORMACOES DO BACKUP NO ARQUIVO DE LOG."
        echo "NAO FOI POSSIVEL ENCONTRAR AS INFORMACOES DO BACKUP NO ARQUIVO DE LOG." >>$erro_log_file
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
    echo -n "-Programa: $(basename "$0")"
    echo
    echo "-Versao  : $versaoPrograma"
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

# Função para alterar o status do online pela linha de comando
testar_online() {
    echo
    local teste_status_online
    local opcao
    if [[ -z "$1" ]]; then
        clear
        tput cup 2 21
        echo "OPCAO PARA VERIFICAR/ALTERAR O ONLINE"
        tput cup 5 24
        echo " 1  -  ATIVAR O ONLINE"
        tput cup 6 24
        echo " 2  -  DESATIVAR O ONLINE"
        tput cup 7 24
        echo " 3  -  VISUALIZAR O ONLINE"
        tput cup 8 24
        echo " 9  -  VOLTAR AO MENU PRINCIPAL"
        tput cup 9 24
        echo "99  -  SAIR"
        tput cup 11 26
        echo -n "OPCAO: "
        read opcao
        case $opcao in
        1)
            clear
            cobrun status-online.gnt "A" 2>&1
            echo "ONLINE DE VENDAS ATIVADO!"
            ;;
        2)
            clear
            cobrun status-online.gnt "D" 2>&1
            echo "ONLINE DE VENDAS DESATIVADO!"
            ;;
        3)
            clear
            teste_status_online=$(cobrun status-online.gnt "L")
            if [ $teste_status_online = "ATIVADO" ]; then
                echo "ONLINE DE VENDAS ATIVADO!"
            else
                echo "ONLINE DE VENDAS DESATIVADO!"
            fi
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
        esac
    else
        while getopts ":Lade" opt; do
            case ${opt} in
            L)
                clear
                teste_status_online=$(cobrun status-online.gnt "L")
                if [ $teste_status_online = "ATIVADO" ]; then
                    echo "ONLINE DE VENDAS ATIVADO!"
                else
                    echo "ONLINE DE VENDAS DESATIVADO!"
                fi
                exit 0
                ;;
            A)
                clear
                cobrun status-online.gnt "A" 2>&1
                echo "ONLINE DE VENDAS ATIVADO!"
                exit 0
                ;;
            D)
                clear
                cobrun status-online.gnt "D" 2>&1
                echo "ONLINE DE VENDAS DESATIVADO!"
                exit 0
                ;;
            *)
                clear
                echo "OPCAOO INVALIDA."
                echo "USE '-L' PARA VISUALIZAR O STATUS DO ONLINE DE VENDAS."
                echo "USE '-A' PARA ATIVAR O ONLINE DE VENDAS."
                echo "USE '-D' PARA DESATIVAR O ONLINE DE VENDAS."
                ;;
            esac
        done
    fi
}

# Função para ser baixado e configurado scripts e programas extras
baixar_extras() {
    echo
    if [ "$distro_nome" = "Debian" ]; then
        if [ -f "/u/bats/xmlstarlet" ]; then
            rm -rf /u/bats/xmlstarlet
        fi
    elif [ "$distro_nome" = "Slackware" ]; then
        if [ ! -f "/u/bats/xmlstarlet" ]; then
            echo "CONFIGURANDO XMLSTARTLET"
            # Usando o link raw para baixar o binário corretamente
            curl -L -# -o "/u/bats/xmlstarlet" "https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/extras/xmlstarlet.Slackware"
            chmod +x /u/bats/xmlstarlet
        fi
    fi
    echo
    if [ ! -f "/u/bats/gera-xml-por-tag.sh" ]; then
        echo "CONFIGURANDO GERA-XML"
        curl -# -o "/u/bats/gera-xml-por-tag.sh" "https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/extras/gera-xml-por-tag.sh"
        chmod +x /u/bats/gera-xml-por-tag.sh
    fi

    if [ ! -f "/u/bats/verificar-processo" ]; then
        echo "CONFIGURANDO VERIFICA PROCESSO"
        curl -# -o "/u/bats/verificar-processo" "https://raw.githubusercontent.com/ketteiGustavo/atualizador/main/extras/verificar-processo"
        chmod 777 "/u/bats/verificar-processo"
    fi
    echo
}

###############################
# Tratamento das opcoes que serao responsaveis por controlar na linha de comando
# ------------------------------------------------------------------------------

case "$1" in
-h | --help | -a | --ajuda)
    clear
    echo "$manual_uso"
    exit 0
    ;;
-V | -v | --version | --versao)
    # Extrai a versao diretamente do cabecalho do programa
    clear
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
    clear
    checar_internet
    ler_arquivo_texto
    baixar_atualizacoes
    exit 0
    ;;
--baixar-versao)
    clear
    checar_internet
    baixar_versao
    exit 0
    ;;
--baixar-release)
    clear
    checar_internet
    baixar_release
    exit 0
    ;;
-b | --backup)
    clear
    fazer_bkp
    verifica_backup
    exit 0
    ;;
-m | --menu)
    clear
    menu_principal
    exit 0
    ;;
-up | --update)
    clear
    checar_internet
    # criar rotina pra baixar nova versao do atualizador.
    echo "Buscando update para o Atualizador..."
    nova_versao
    exit 0
    ;;
--man)
    clear
    alerta_msg "ESSE RECURSO ESTARA DISPONIVEL EM BREVE!!!"
    #checar_internet
    #man atualizador
    exit 0
    ;;
--testar-internet)
    clear
    checar_internet
    if [ $? -eq 0 ]; then
        echo "CONEXAO COM A INTERNET OK!"
        exit 0
    else
        exit 1
    fi
    ;;
-o | --obter)
    clear
    checar_internet
    # Busca no servidor a versao e release atualizada e exibi no terminal
    baixar_controle
    exit 0
    ;;
--online)
    clear
    shift
    testar_online "$@"
    exit 0
    ;;
-r | --restore)
    clear
    alerta_msg "ESSE RECURSO ESTARA DISPONIVEL EM BREVE!!!"
    #echo "OPCAO DE RESTAURACAO"
    #menu_restaura
    exit 0
    ;;
-l | --log)
    clear
    ler_logs
    exit 0
    ;;
--limpa-exec)
    clear
    limpa_exec
    exit 0
    ;;
-P)
    clear
    verificar_usuario
    shift
    clear
    echo "PARAMETRIZACAO"
    parametros "$@"
    exit 0
    ;;
--cron)
    clear
    if [ $USER != root ]; then
        echo "Favor acionar o Suporte Avanco para realizar a configuracao"
        echo "" >>"$auditoria"
        echo "================================================================================" >>"$auditoria"
        echo "PROGRAMA: $(basename "$0") --> configuracoes do crontab" >>$auditoria
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "TENTATIVA DE ACESSAR CONFIGURACAO DO CRONTAB" >>"$auditoria"
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "$(date +'%d/%m/%Y') - $(date +'%H:%M')" >>$auditoria
        echo "USUARIO: $USER" >>"$auditoria"
        echo "--------------------------------------------------------------------------------" >>$auditoria
        echo "" >>"$auditoria"
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
--extras-cron)
    clear
    echo ""
    exit 0
    ;;
--extras-atualizador)
    clear
    chmod -R 777 /u/sist/logs
    chmod -R 777 /u/sist/controle
    exit 0
    ;;
--compilar)
    clear
    preparar_compilado
    exit 0
    ;;
--testar-atualizado)
    testar_atualizado
    exit 0
    ;;
*)
    clear
    if test -n "$1"; then
        echo OPCAO INVALIDA: $1
        echo -e "Utilize a opcao -h ou --help para obter ajuda"
        exit 1
    fi
    ;;
esac

# Chamandos as funcoes na ordem
verificar_dia
carregar_parametros
usuario_permitido
checar_internet
verifica_atualizacao
iniciar
limpa_exec
ler_arquivo_texto >/dev/null 2>&1
atualizar
gravando_atualizacoes
nova_versao >/dev/null 2>&1
exit 0
