import 'package:flutter_test/flutter_test.dart';

import 'package:bikeng_app/app/app.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const BiKengApp());
  });
}
