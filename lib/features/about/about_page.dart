import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n/app_strings.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  static const _repoUrl = 'https://github.com/Parin-M/parin-litner';

  Future<void> _openRepository(BuildContext context) async {
    final uri = Uri.parse(_repoUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t(context, 'about_open_error'))));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = (String key) => AppStrings.t(context, key);
    return Scaffold(
      appBar: AppBar(title: Text(s('about'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 36), children: [
        Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
          Container(width: 92, height: 92, padding: const EdgeInsets.all(10), decoration: BoxDecoration(borderRadius: BorderRadius.zero, color: scheme.primaryContainer), child: Image.asset('assets/parin_litner_icon.png')),
          const SizedBox(height: 18),
          const Text('Parin Litner', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('${s('about_creator_desc')}\n\n${s('about_ai')}', style: TextStyle(fontSize: 16, height: 1.65, color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
        ]))),
        const SizedBox(height: 14),
        Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), leading: CircleAvatar(backgroundColor: scheme.primaryContainer, child: Icon(Icons.code_rounded, color: scheme.onPrimaryContainer)), title: Text(s('about_github'), style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(s('about_repo_desc')), trailing: const Icon(Icons.open_in_new_rounded), onTap: () => _openRepository(context))),
        Card(child: ListTile(leading: Icon(Icons.info_outline, color: scheme.primary), title: Text(s('about_version_title')), subtitle: Text('7.2.0 • ${s('about_android_compat')}'))),
        const SizedBox(height: 14),
        Center(child: Text(s('about_love'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant), textAlign: TextAlign.center)),
      ]),
    );
  }
}
