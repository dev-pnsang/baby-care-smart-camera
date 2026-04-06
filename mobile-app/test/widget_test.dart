import 'package:flutter_test/flutter_test.dart';
import 'package:baby_care_smart_cam/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const BabyCareSmartCamApp());
    await tester.pump();
    expect(find.text('Bi'), findsWidgets);
  });
}
