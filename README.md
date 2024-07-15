<h1 align="center">
    <p> ATUALIZADOR INTEGRAL</p>
</h1>

[![Mantido](https://img.shields.io/badge/Mantido%3F-sim-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity)
[![Maintainer !](https://img.shields.io/badge/mantenedor-luizgustavo-blue)](https://github.com/ketteiGustavo)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-D70A53?style=for-the-badge&logo=debian&logoColor=white)
![Slackware](https://img.shields.io/badge/-Slackware-%231357BD?style=for-the-badge&logo=slackware&logoColor=white)
[![Notion !](https://img.shields.io/badge/Notion-%23000000.svg?style=for-the-badge&logo=notion&logoColor=white)](https://www.notion.so/Manual-Atualizador-Autom-tico-em-constru-o-44c13ed760b9426aaa7b0752f7e606e7?pvs=4)

<div align="center">
  Nos ajude com esse projeto
  <br />
  <br />
  <a href="https://github.com/ketteiGustavo/atualizador/issues/new?assignees=&labels=&projects=&template=bug_report.md&title=">Reporte um Bug</a>
  ·
  <a href="https://github.com/ketteiGustavo/atualizador/issues/new?assignees=&labels=&projects=&template=solicitar-um-recurso.md&title=">Solicitar um Recurso</a>
  ·
  <a href="https://github.com/ketteiGustavo/atualizador/discussions">Faça uma pergunta</a>
</div>

<div align="center">
<br />
</div>

## 📖 SOBRE O PROJETO

A ideia desse projeto é facilitar a atualização do Integral nos servidores dos clientes, eliminando etapas que o usuário teria que digitar os inúmeros comandos necessários para atualizar, que vão desde realizar backup, validar cobol, descompactar, permissão total e etc...

## 🗂️ ÍNDICE
<details closed="closed">
<summary>Ver mais</summary>

- [Sobre](#-sobre-o-projeto)
- [Instruções](#-instruções-de-instalação)
- [Ferramentas](#-ferramentas)
- [Links Úteis](#-links-úteis)
- [Contribua com esse projeto](#-contribuindo-com-esse-projeto)
- [Suporte](#-suporte)
- [Licenças](#-licenças)
- [Gitflow](#-gitflow)
- [Contribuições](#-contribuições-e-contribuidores)


</details>

##

## 📋 INSTRUÇÕES DE INSTALAÇÃO
<details closed="closed">
<summary>Como instalar</summary>

### Pré-requisitos

- Sistema Integral
- Conexão com a Internet
- Putty
- VPN (se necessário)
- Acesso ao servidor por terminal Putty

#### Etapas

O configurarAtualizador deve ser executado como root, pois ele irá gravar as permissões corretas nos programas e nas páginas atualizadas dos manuais.

- 1º Execute o comando abaixo, para realizar o Download mais recente da configuração inicial. Caso tenha o pacote offline execute a etapa da instalação offline.


```bash
root@servidor$ wget "bit.ly/configurarAtualizador" -P "/u/rede/avanco"

```

- 2º Execute o comando para iniciar a configuração

##### obs.: Necessário rodar como 'ROOT'
```bash
root@servidor$ bash /u/rede/avanco/configurarAtualizador.sh
```
- 3º Execute o comando do Atualizador
##### obs.: Nesse momento deverá estar como usuario 'Avanco'
```bash
avanco@servidor$ atualizador
```

#### Caso queira ver o manual completo com as etapas [acesse aqui]()

</details>

## MANUAL
<details open="open">
<summary>Opções</summary>

 - [Obtendo ajuda](#-ajuda-rápida)
 - [Manual Completo](#-manual-atualizador)
</details>

### AJUDA RÁPIDA
Nessa opção você obterá ajuda rápida para alguns recursos e comandos disponíveis no. Para conseguir visualizar o help do atualizador basta digitar:
```bash
avanco@servidor$ atualizador --help
```
ou

```bash
avanco@servidor$ atualizador -h
```


### MANUAL ATUALIZADOR
Caso queria ler o manual completo acesse:
```bash
avanco@servidor$ man atualizador
```
Caso ainda prefira ler através de um arquivo PDF, basta [acessar aqui]()

## 🔨 FERRAMENTAS
o Atualizador foi construído em Shell Script, caso queria conhecer mais sobre a linguagem, acesse o link abaixo.
- [Shell Script](https://pt.wikipedia.org/wiki/Shell_script)

[![My Skills](https://skillicons.dev/icons?i=bash)](https://skillicons.dev)

## 🔗 LINKS ÚTEIS
- [Avanço Informática](https://novo.avancoinfo.net/session/login)
- [Info Varejo](https://www.infovarejo.com.br/)
- [Atendimento Telegram](https://t.me/avancoinformatica_bot)
- [Atendimento Portal](https://novo.avancoinfo.net/novoPortal/atendimento)

## 🤝 CONTRIBUINDO COM ESSE PROJETO
Primeiramente, obrigado por reservar um tempo para contribuir! Contribuições são o que torna a comunidade de código aberto um lugar tão incrível para aprender, inspirar e criar. Quaisquer contribuições que você fizer beneficiarão a todos os outros e serão muito apreciadas.

Tente criar relatórios de bugs que sejam:

- Reproduzível. Inclua etapas para reproduzir o problema.
- Específico. Inclua o máximo de detalhes possível: qual versão, qual ambiente, etc.
- Único. Não duplique problemas abertos existentes.
- Escopo para um único bug. Um bug por relatório.

Siga o [Código de Conduta](documentos/CODIGO_DE_CONDUTA.md) desse proejto.

## 🆘 SUPORTE
Entre em contato com o mantenedor em um dos seguintes locais:
- [Discusões no GitHub](https://github.com/ketteiGustavo/atualizador/discussions)
- Através do perfil no [GitHub](https://github.com/ketteiGustavo)
- Ou através desse [e-mail](mailto:luiz.gustavo@avancoinfo.com.br)

## 📋 LICENÇAS

## 🔐 GITFLOW
Qualquer alteração ou manutenção deve ser realizada em Branch 'manutencao', após ser validada e ok, subir para 'main'.


## 🤝 CONTRIBUIÇÕES E CONTRIBUIDORES

Um agradecimento especial a todas as pessoas que contribuíram para este projeto.

<table>
  <tr>
    <td align="center">
      <a href="#">
        <img src="https://avatars.githubusercontent.com/u/140563277?v=4" width="100px;" alt="Luiz Gustavo Profile Picture"/><br>
        <sub>
          <b>Luiz Gustavo</b><br>
        </sub>
        <sub>
          <b>Desenvolvedor
        </sub>
      </a>
    </td>
  </tr>
</table>

