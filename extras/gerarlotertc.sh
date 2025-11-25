#!/bin/sh
###############################################################
# AVANCO INFORMATICA
#
# DATA: 07/10/2025
#
# GERACAO DE ARQUIVOS TXT COM LAYOUT DE IMPORTACAO NF-E EM LOTE
# PARAMETRO 1: DIRETORIO DE ORIGEM DOS ARQUIVOS XML
# PARAMETRO 2: DIRETORIO DE DESTINO DOS ARQUIVOS TXT
# PARAMETRO 3: DIRETORIO DE DESTINO DOS ARQUIVOS XML PROCESSADOS
###############################################################

# CRIA DIRETÃ“RIOS CASO NÃƒO EXISTAM
#set -x
mkdir -p "$2"
mkdir -p "$3"
data=`date +%Y-%m-%d`

# CARREGA VARIAVEIS AMBIENTE DE ACORDO COM S.O
if cat /etc/os-release | grep ubuntu; then
    . /etc/bash.bashrc
else
     . /etc/profile
fi

#echo $PATH
# CRIACAO DE DIRETORIO DE LOG
path="/u/rede/avanco/log-xml/"
mkdir -p $path
log=$path"importador.log"

/u/bats/extrair_todos_xmls_txt.sh "$1"  2>> $log

for i in `find "$1" -name "*.xml"`
do
	OLDDIR="$(pwd)"
	cd "$3"
	cnpj=$(xmlstarlet sel -t -v "//*[local-name()='dest']/*[local-name()='CNPJ']" "$i")

	# Criar diretório com permissões adequadas
	mkdir -p ${cnpj}/${data}

	saida=`echo -n "${3}/${cnpj}/${data}"`
	cd "$OLDDIR" 
        if cp "$i" "$saida" 2>> "$log"; then
	   rm -f "$i"
	else
	   echo "Erro: Falha ao copiar o arquivo $i para $saida." >> "$log"
	fi	
done

for i in `find "$1" -name "*.txt"`
do
	mv -f $i "$2" 2>> $log	
done

cd $COBPATH
nohup cobrun fun677 >> $log
