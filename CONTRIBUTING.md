# Como contribuir

Correções, documentação e ideias em issues são bem-vindas. As regras são poucas.

## Código de conduta

Quem participa do projeto segue o [Código de Conduta](CODE_OF_CONDUCT.md).

## Fluxo

- A `main` é o que está em produção: cada merge nela é implantado na instância do PET em até
  um minuto. Por isso ninguém trabalha direto nela.
- Abra o pull request contra a `development`. Quando ela junta um conjunto de mudanças
  testadas, um PR leva a `development` para a `main`.
- Todo PR, inclusive de quem mantém o projeto, passa por revisão.
- O CI constrói as três imagens, roda o lint e o teste de ponta a ponta (sobe a stack, cadastra
  um problema e confere o veredicto de um envio em cada linguagem). O PR só entra com tudo verde.

## Antes de abrir o PR

Construa as imagens e rode o teste de ponta a ponta na sua máquina:

```sh
git submodule update --init
docker buildx bake --load
tests/e2e/run.sh
```

O teste usa um projeto e volumes próprios (`moj-e2e`), não encosta numa instância que já exista
na máquina e apaga tudo no fim. Com `MANTER=1` a stack fica de pé em <http://localhost:18080>.

E rode o lint com a mesma configuração do CI:

```sh
docker run --rm -e RUN_LOCAL=true -e USE_FIND_ALGORITHM=true \
  --env-file .github/super-linter.env -v "$PWD":/tmp/lint \
  ghcr.io/super-linter/super-linter:slim-v8.7.0
```

## O código do MOJ

O que está em `vendor/` é dos autores do MOJ, e este repositório não o altera. Correção no MOJ
em si vai para os repositórios originais ([cdmoj](https://github.com/cd-moj/cdmoj),
[mojtools](https://github.com/cd-moj/mojtools), [cdjudge](https://github.com/cd-moj/cdjudge));
aqui entra só o PR que move o submódulo para o commit que traz a correção.

## Developer's Certificate of Origin 1.1

Ao contribuir, você declara o que está abaixo (o texto oficial, em inglês):

<pre>
By making a contribution to this project, I certify that:

 (a) The contribution was created in whole or in part by me and I
     have the right to submit it under the open source license
     indicated in the file; or

 (b) The contribution is based upon previous work that, to the best
     of my knowledge, is covered under an appropriate open source
     license and I have the right under that license to submit that
     work with modifications, whether created in whole or in part
     by me, under the same open source license (unless I am
     permitted to submit under a different license), as indicated
     in the file; or

 (c) The contribution was provided directly to me by some other
     person who certified (a), (b) or (c) and I have not modified
     it.

 (d) I understand and agree that this project and the contribution
     are public and that a record of the contribution (including all
     personal information I submit with it, including my sign-off) is
     maintained indefinitely and may be redistributed consistent with
     this project or the open source license(s) involved.
</pre>
