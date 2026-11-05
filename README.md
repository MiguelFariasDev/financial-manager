# Caderno — finanças pessoais

App Flutter (iOS/Android) de finanças pessoais no estilo **Broadsheet**: serifa (Source Serif 4), papel, ciano para ação e magenta só para o que exige atenção. Tema claro e escuro.

Implementa o protótipo exportado do Claude Design (`Finance App.dc.html`), com o **Início na opção A ("Primeira página")**. As opções B e C do protótipo não foram implementadas, por decisão do projeto.

## Decisões de produto
- Sem login. Dados só no aparelho (`shared_preferences`, JSON).
- Importação manual (OFX/CSV).

## Telas
Início · Movimentações · Cartões · Detalhe do cartão · Fatura (com registro de pagamento) · Parcelamento · Planejamento · Perfil · Cadastro rápido (com compra parcelada e prévia do cronograma) · Importação · Edição de compra.

## Rodar
```bash
flutter pub get
flutter run
flutter test      # lógica de valores + smoke test das telas
flutter analyze
```

## Estrutura
```
lib/
  theme/     tokens (paleta clara/escura) e ThemeData
  data/      modelos e dados de exemplo (seed)
  state/     AppState (ChangeNotifier) + persistência local
  util/      formatação pt-BR, export CSV/JSON
  widgets/   componentes compartilhados e ícones Phosphor (duotone)
  screens/   uma tela por arquivo
  sheets/    bottom sheets (cadastro, importação, pagamento, edição)
```

## Importação de extratos (OFX / CSV)
Botão de importar em Movimentações (ou no Perfil) → escolher arquivo → **prévia** (a importar / já existiam / para revisar) → confirmar. Nada é gravado antes da confirmação.

- **OFX** 1.x (SGML) e 2.x (XML), incluindo arquivos em Latin-1/Windows-1252; conta corrente e cartão.
- **CSV** com separador `,` `;` ou tab, cabeçalho detectado (mesmo com linhas antes dele), datas `dd/mm/aaaa`, `aaaa-mm-dd` e `dd/mm/aa`, valores como `1.234,56`, `-12.30`, `(12,30)`, colunas de débito/crédito. Exportações de cartão do Nubank (valores positivos = compra) são reconhecidas.
- **Duplicatas:** linhas com o mesmo identificador (FITID) já importado são ignoradas; sem identificador, uma movimentação existente com o mesmo dia e valor absorve uma linha do arquivo (lançamentos manuais raramente têm a mesma descrição do banco). Reimportar o mesmo arquivo não duplica nada.
- **Categorias:** usa a coluna de categoria do CSV ou palavras-chave na descrição. O que não casa vira "Outros" com a marca **Sem categoria**; toque na movimentação para escolher.
- **Desfazer:** cada importação é um lote e pode ser desfeita inteira no Perfil.
- **Limites:** arquivos de até 10 MB; planilhas Excel e PDF são recusados com mensagem. Movimentações de meses/anos diferentes aparecem ao navegar pelo mês em Movimentações; só as de novembro/2026 entram nas contas do Início.
- **Cartões:** extratos de cartão entram como movimentações de crédito, mas ainda **não alimentam as faturas** dos cartões cadastrados.

## O que ainda é demonstração (não é dado real)
- **Dados de exemplo:** contas, cartões, movimentações, saldo em contas e a data de referência (**4 de novembro de 2026**, em `lib/data/seed.dart`) vêm do protótipo. O que o usuário faz no app (lançamentos, pagamentos de fatura, meta, limites, renomear parcelas, tema) é persistido.
- **Exportar CSV/backup:** copia o conteúdo para a área de transferência (o protótipo só mostrava um aviso). Falta gravar arquivo/compartilhar.
- **Pagamento de fatura:** marca a fatura como paga, mas não lança a saída na conta escolhida.

## Créditos
- Fonte Source Serif 4 (SIL OFL) e ícones [Phosphor](https://phosphoricons.com) (MIT, `assets/fonts/PHOSPHOR-LICENSE.txt`). O pacote `phosphor_flutter` não compila nas versões atuais do Flutter (`IconData` virou `final`), então a fonte duotone foi embutida e mapeada em `lib/widgets/phosphor_data.dart`.
