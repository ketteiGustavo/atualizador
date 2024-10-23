#!/bin/bash

funcao(){
    local arq="$1"
    if [ -e $arq ]; then
        if grep 'nfeProc' "$arq"  > /dev/null 2>&1 || grep 'cteProc' "$arq" > /dev/null 2>&1 || grep 'cteOSProc' "$arq" > /dev/null 2>&1; then
            tmpfile="/tmp/$(date +%N).xml"
            cnpj=$(grep -io "<dest><cnpj>[0-9]\+</cnpj>" $arq | grep -io "[0-9]\+")
            data=$(date +%Y-%m-%d)
            dirbk="/u/rede/xml/bck-xml/$cnpj/$data"
            dirsaida="/u/rede/xml/xml-txt"
            mkdir -p "$dirbk"
            cp $arq $tmpfile
            if cat $arq | grep 'cteProc' > /dev/null 2>&1 || cat $arq | grep 'cteOSProc' > /dev/null 2>&1; then
                tipo="cte"
                output="$dirsaida/$(echo $arq | sed 's|.xml|.cte|g' | sed 's|.XML|.cte|g')"
            else
                tipo="nfe"
                output="$dirsaida/$(echo $arq | sed 's|.xml|.txt|g' | sed 's|.XML|.txt|g')"
            fi
            for tag in $TAGS; do
                if [ "$tag" = "infNFe" ] || [ "$tag" = "infCte" ]; then
                    if [ "$tipo" = "nfe" ]; then
                        localname="infNFe"
                    else
                        localname="infCte"
                    fi
                    ID=$(xmlstarlet sel -t -v "//*[local-name()='$localname']/@Id" "$tmpfile")
                    echo "<$localname Id=$ID>" > "$output"
                else
                    xmlstarlet sel -N x="http://www.portalfiscal.inf.br/$tipo" -t -c "//x:$tag" -n "$tmpfile" | tr -d '\n' >> "$output"
                    echo "" >> $output
                fi
                if [ "$tag" = "det" ]; then
                    sed -i 's|</det>|</det>\n|g' "$output"
                fi
            done
            sed -i '/^$/d' "$output"
            sed -i "s/ xmlns=\"http:\/\/www\.portalfiscal\.inf\.br\/$tipo\"//g" "$output"
            sed -i "s|</[a-zA-Z0-9_:]\+>||g" "$output"
            rm -f "$tmpfile"
            mv "$arq" "$dirbk"
        fi
    fi
}

cd /u/rede/xml/xml

export -f funcao
export ARQUIVOS="$(find . -iname '*.xml')"
export TAGS="infCte infCTe ide emit toma rem dest vPrest imp infCarga infDoc infModal infProt"
if [ ! -z "$ARQUIVOS" ]; then
    echo $ARQUIVOS | xargs -n 1 -P 4 bash -c 'funcao "$0"'
fi

