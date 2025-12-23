import 'package:flutter_test/flutter_test.dart';
import 'package:krushikranti_admin/main.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KrushiKrantiAdminApp());

    // Verify splash screen loads
    expect(find.text('Krushi Kranti'), findsOneWidget);
    expect(find.text('Admin Portal'), findsOneWidget);
  });
}
