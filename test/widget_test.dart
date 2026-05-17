import 'package:block_dash/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home screen shows core actions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(BlockDashApp(prefs: prefs));

    expect(find.text('BLOCK\nDASH'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });
}
