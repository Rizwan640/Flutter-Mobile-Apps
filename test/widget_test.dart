import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mobile_apps/main.dart';

void main() {
  testWidgets('home screen displays the welcome message', (tester) async {
    await tester.pumpWidget(const FlutterMobileApps());

    expect(find.text('Hello, Rizwan!'), findsOneWidget);
    expect(find.text('Your Flutter project is ready.'), findsOneWidget);
  });
}
