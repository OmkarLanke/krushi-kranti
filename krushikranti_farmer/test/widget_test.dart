import 'package:flutter_test/flutter_test.dart';
import 'package:krushikranti_farmer/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // We use KrushiKrantiApp, not MyApp
    await tester.pumpWidget(const KrushiKrantiApp());

    // Verify our text exists
    expect(find.text('Krushi Kranti Farmer App\nReady for Dev'), findsOneWidget);
  });
}