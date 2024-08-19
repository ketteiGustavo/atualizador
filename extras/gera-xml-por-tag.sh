#!/bin/bash

# Atribui o primeiro argumento passado para o script à variável 'tag'.
tag="$1"

# Atribui o segundo argumento passado para o script à variável 'arquivo_entrada'.
# Este é o arquivo XML de entrada.
arquivo_entrada="$2"

# Atribui o terceiro argumento passado para o script à variável 'arquivo_saida'.
# Este será o arquivo onde o resultado será salvo.
arquivo_saida="$3"

# Utiliza o xmlstarlet para selecionar o conteúdo dos elementos XML com base na tag fornecida.
# -N x="http://www.portalfiscal.inf.br/nfe": Define um namespace prefixado como 'x'.
# -t -c "//x:$tag": Define a saida como texto e seleciona o conteúdo dos elementos que correspondem ao valor citado na variavel $tag dentro do namespace "x"
# -n "$arquivo_entrada": Especifica o arquivo XML de entrada.

# O resultado é passado para o sed para remover o namespace XML.
# sed 's/xmlns="http:\/\/www\.portalfiscal\.inf\.br\/nfe"//g': Remove a declaração de namespace XML.

# O resultado é passado para o tr para remover as quebras de linha.
# tr -d '\n': Remove todas as quebras de linha do resultado.
# Adiciona o resultado processado ao final do arquivo de saída.

xmlstarlet sel -N x="http://www.portalfiscal.inf.br/nfe" \
    -t -c "//x:$tag" \
    -n "$arquivo_entrada" | \
sed 's/xmlns="http:\/\/www\.portalfiscal\.inf\.br\/nfe"//g' | \
tr -d '\n' | \
sed "s|</[a-zA-Z0-9_:]\+>||g" >> "$arquivo_saida"

# Modifica o arquivo de saída para adicionar uma quebra de linha após cada fechamento da tag especificada.
# -i: Edita o arquivo de saída no local.
# s|</$tag>|</$tag>\n|g: Substitui cada ocorrência do fechamento da tag com o fechamento da tag seguido por uma quebra de linha.
sed -i "s|<$tag|\n<$tag|g" $arquivo_saida
