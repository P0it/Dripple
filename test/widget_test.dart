import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dripple/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DrippleApp()));
    await tester.pumpAndSettle();

    expect(find.text('DRIPPLE'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
  });
}
