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

## O que ainda é demonstração (não é dado real)
- **Dados de exemplo:** contas, cartões, movimentações, saldo em contas, histórico de importações e a data de referência (**4 de novembro de 2026**, em `lib/data/seed.dart`) vêm do protótipo. O que o usuário faz no app (lançamentos, pagamentos de fatura, meta, limites, renomear parcelas, tema) é persistido.
- **Importação:** o fluxo (carregamento, erro de `.xlsx`, resumo) é o do protótipo, mas **não lê arquivos nem importa nada ainda**. Falta seletor de arquivos e parsers OFX/CSV.
- **"Desfazer" importação:** só mostra o aviso.
- **Exportar CSV/backup:** copia o conteúdo para a área de transferência (o protótipo só mostrava um aviso). Falta gravar arquivo/compartilhar.
- **Pagamento de fatura:** marca a fatura como paga, mas não lança a saída na conta escolhida.

## Créditos
- Fonte Source Serif 4 (SIL OFL) e ícones [Phosphor](https://phosphoricons.com) (MIT, `assets/fonts/PHOSPHOR-LICENSE.txt`). O pacote `phosphor_flutter` não compila nas versões atuais do Flutter (`IconData` virou `final`), então a fonte duotone foi embutida e mapeada em `lib/widgets/phosphor_data.dart`.
