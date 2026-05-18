import 'package:block_dash/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home screen shows core actions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(BlockDashApp(prefs: prefs));

    expect(find.text('BLOCK\nDASH'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('RATE US'), findsOneWidget);
    expect(find.text('SETTINGS'), findsNothing);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('SFX'), findsOneWidget);
    expect(find.text('Background Music'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Contact Us'), findsOneWidget);
  });
}
