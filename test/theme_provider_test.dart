import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwali/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('uses the required default theme settings', () async {
    final preferences = await SharedPreferences.getInstance();
    final provider = ThemeProvider(preferences);
    addTearDown(provider.dispose);

    expect(provider.isDarkMode, isFalse);
    expect(provider.primaryColorValue, Colors.indigo.toARGB32());
  });

  test('loads saved settings and persists subsequent changes', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'is_dark_mode': true,
      'primary_color_value': Colors.teal.toARGB32(),
    });
    final preferences = await SharedPreferences.getInstance();
    final provider = ThemeProvider(preferences);
    addTearDown(provider.dispose);
    var notificationCount = 0;
    provider.addListener(() => notificationCount++);

    expect(provider.isDarkMode, isTrue);
    expect(provider.primaryColorValue, Colors.teal.toARGB32());

    await provider.toggleDarkMode(false);
    await provider.changePrimaryColor(Colors.purple);

    expect(provider.isDarkMode, isFalse);
    expect(provider.primaryColorValue, Colors.purple.toARGB32());
    expect(preferences.getBool('is_dark_mode'), isFalse);
    expect(preferences.getInt('primary_color_value'), Colors.purple.toARGB32());
    expect(notificationCount, 2);
  });
}
