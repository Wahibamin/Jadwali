import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwali/screens/about_screen.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  testWidgets('shows Arabic app information and handles launch failure', (
    tester,
  ) async {
    Uri? launchedUri;
    LaunchMode? launchedMode;

    await tester.pumpWidget(
      MaterialApp(
        home: AboutScreen(
          urlLauncher: (uri, {required mode}) async {
            launchedUri = uri;
            launchedMode = mode;
            return false;
          },
        ),
      ),
    );

    expect(find.text('عن التطبيق'), findsOneWidget);
    expect(find.text('المخطط اليومي الذكي'), findsOneWidget);
    expect(find.text('تطوير: وهيب الكبودي'), findsOneWidget);
    expect(find.byIcon(Icons.chat), findsOneWidget);
    expect(find.text('تواصل معي عبر واتساب'), findsOneWidget);

    await tester.tap(find.text('تواصل معي عبر واتساب'));
    await tester.pumpAndSettle();

    expect(launchedUri, Uri.parse('https://wa.me/967775566952'));
    expect(launchedMode, LaunchMode.externalApplication);
    expect(
      find.text('تعذر فتح واتساب. يرجى المحاولة مرة أخرى.'),
      findsOneWidget,
    );
  });
}
