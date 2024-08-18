#!/bin/bash

bkp_local="/home/luiz/Documentos/testes"
logal_gnt="/home/luiz/Documentos/testes/exec"
BKP_DESTINO="/home/luiz/Documentos/testes/exec-a"
flag_versao=false
flag_release=false

clear

if [ -e "$bkp_local/versao40-090724.rar" ]; then
    rar lb "$bkp_local/versao40*" > "$bkp_local/programasVersao.txt"
    total_bkp_versao=$(cat "$bkp_local/programasVersao.txt" | wc -l )
    contagem_versao=0
    flag_versao=true
else
    flag_versao=false
fi

if [ -e "$bkp_local/release40-0907-a-1207.rar" ]; then
    rar lb "$bkp_local/release40*" > "$bkp_local/programasRelease.txt"
    total_bkp_release=$(cat "$bkp_local/programasRelease.txt" | wc -l )
    contagem_release=0
    flag_release=true
else
    flag_release=false
fi

echo "atual flag da versao: $flag_versao"
echo "atual flag da release: $flag_release"

fazer_bkp () {

    if [ $flag_versao = true ]; then
        arquivos_bkp_versao=()
        while IFS= read -r arquivo; do
            caminho_completo="$logal_gnt/$arquivo"
            if [ -f "$caminho_completo" ]; then
                arquivos_bkp_versao+=("$caminho_completo")
            else
                echo "Programa $caminho_completo nao encontrado."
            fi
        done < "$bkp_local/programasVersao.txt"

        if rar a "$BKP_DESTINO/BKPTOTAL_VERSAO_160724" "${arquivos_bkp_versao[@]}" | while read -r line; do
            ((contagem_versao++))
            porcentagem_bkp_versao=$((contagem_versao * 100 / total_bkp_versao))
            echo -ne "CRIANDO BACKUP: [$porcentagem_bkp_versao%]\r"
        done
        then
            echo "bkp concluido"
        else
            echo "erro ao fazer bkp"
        fi
    fi

    if [ $flag_release = true ]; then
        arquivos_bkp_release=()
        while IFS= read -r arquivo; do
            caminho_completo="$logal_gnt/$arquivo"
            if [ -f "$caminho_completo" ]; then
                arquivos_bkp_release+=("$caminho_completo")
            else
                echo "Programa $caminho_completo nao encontrado."
            fi
        done < "$bkp_local/programasRelease.txt"

        if rar a "$BKP_DESTINO/BKPRELEASE_160724" "${arquivos_bkp_release[@]}" | while read -r line; do
            ((contagem_release++))
            porcentagem_bkp_release=$((contagem_release * 100 / total_bkp_release))
            echo -ne "CRIANDO BACKUP: [$porcentagem_bkp_release%]\r"
        done
        then
            echo "bkp concluido"
        else
            echo "erro ao fazer bkp"
        fi
    fi

    if [ -e "$bkp_local/programasVersao.txt" ]; then
        rm "$bkp_local/programasVersao.txt"
    fi
    if [ -e "$bkp_local/programasRelease.txt" ]; then
        rm "$bkp_local/programasRelease.txt"
    fi
}

fazer_bkp