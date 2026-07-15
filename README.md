# Ferragem Store

Aplicacao Flutter offline para gestao simples de loja de ferragens.

## Funcionalidades
- Cadastro, edicao, remocao e pesquisa de produtos, com categorias
- Controlo de stock com alertas de stock baixo e ajuste manual (entrada/saida)
- Caixa (POS) com carrinho, calculo de total e baixa automatica de stock
- Historico de vendas
- Relatorios: vendas do dia, vendas dos ultimos 7 dias, valor total em stock,
  produtos mais vendidos e alertas de stock baixo
- Persistencia local com `SharedPreferences` (funciona 100% offline)

## Estrutura
- `lib/models`: modelos de dados (Product, Sale, SaleItem)
- `lib/services/store_controller.dart`: logica de negocio e persistencia
- `lib/screens/home_screen.dart`: navegacao e ecrans (Produtos, Caixa, Stock, Relatorios)
- `lib/main.dart`: tema e arranque da app

## Como executar
Este repositorio contem apenas o codigo Dart/Flutter (pasta `lib`), sem as
pastas nativas `android/` e `ios/`. Para correr no seu computador:

```bash
flutter create .
flutter pub get
flutter run
```

O comando `flutter create .` gera as pastas nativas necessarias sem apagar
o codigo em `lib/`.

## Gerar o APK

```bash
flutter build apk --release
```

O ficheiro fica em `build/app/outputs/flutter-apk/app-release.apk`.

## Proximos passos sugeridos
- Migrar a persistencia para `Hive` ou `SQLite` para maior robustez
- Adicionar leitura de codigo de barras nos produtos
- Exportar relatorios em PDF ou Excel
