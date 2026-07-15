import 'package:flutter_test/flutter_test.dart';
import 'package:ferragem_store/main.dart';

void main() {
  testWidgets('App carrega sem erros', (WidgetTester tester) async {
    await tester.pumpWidget(const FerragemStoreApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Ferragem Store - Produtos'), findsOneWidget);
  });
}
