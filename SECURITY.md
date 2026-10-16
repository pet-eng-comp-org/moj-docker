# Segurança

## Como relatar uma vulnerabilidade

**Não abra issue pública para falha de segurança.** Use o relato privado do GitHub: aba
[Security](https://github.com/pet-eng-comp-org/moj-docker/security) › *Report a vulnerability*.
Só quem mantém o projeto vê o relato.

Ajuda muito incluir, até onde der:

- o tipo de problema (por exemplo: escapar da jaula do juiz, ler arquivo de outro contest,
  forjar o IP de origem);
- os arquivos envolvidos e a versão (tag, branch ou commit);
- alguma configuração especial necessária para reproduzir;
- o passo a passo para reproduzir;
- uma prova de conceito, se houver;
- o impacto: o que alguém conseguiria fazer explorando a falha.

Respondemos o mais rápido possível, mantemos você informado do andamento da correção e podemos
pedir mais detalhes.

## O que é deste projeto e o que é do MOJ

Este repositório empacota o MOJ: composes, Dockerfiles, a primeira subida automática, a
configuração do nginx e o CI. Uma falha nessas partes é daqui. Uma falha no próprio MOJ (a API,
a jaula, o agente do juiz) é dos [autores do MOJ](https://github.com/cd-moj); se você não souber
de qual lado é, relate aqui que nós encaminhamos.

## Sugestões para esta política

Abra um [pull request](https://github.com/pet-eng-comp-org/moj-docker/pulls) ou uma
[issue](https://github.com/pet-eng-comp-org/moj-docker/issues/new).
