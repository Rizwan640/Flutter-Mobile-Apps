import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mobile_apps/main.dart';

void main() {
  testWidgets('AURIX home screen shows local AI setup status', (tester) async {
    await tester.pumpWidget(const AurixApp());

    expect(find.text('AURIX'), findsOneWidget);
    expect(find.text('Hello, Rizwan.'), findsOneWidget);
    expect(find.text('LOCAL AI ENGINE'), findsOneWidget);
    expect(find.text('SETUP PENDING'), findsOneWidget);
  });
}
