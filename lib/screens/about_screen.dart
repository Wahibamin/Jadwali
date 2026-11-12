import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UrlLauncherCallback =
    Future<bool> Function(Uri uri, {required LaunchMode mode});

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, this.urlLauncher = _launchUrl});

  final UrlLauncherCallback urlLauncher;

  static final Uri _whatsAppUri = Uri.parse('https://wa.me/967775566952');

  static Future<bool> _launchUrl(Uri uri, {required LaunchMode mode}) {
    return launchUrl(uri, mode: mode);
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    var didLaunch = false;

    try {
      didLaunch = await urlLauncher(
        _whatsAppUri,
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      didLaunch = false;
    }

    if (!didLaunch && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح واتساب. يرجى المحاولة مرة أخرى.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عن التطبيق')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.event_note_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'المخطط اليومي الذكي',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'تطبيق عربي لإدارة المهام اليومية، متابعة الصلوات، '
                  'وتحليل مستوى الإنجاز دون الحاجة إلى اتصال بالإنترنت.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Text(
                  'تطوير: وهيب الكبودي',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _openWhatsApp(context),
                  icon: const Icon(Icons.chat),
                  label: const Text('تواصل معي عبر واتساب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
