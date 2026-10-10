import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/services/music_service.dart';
import '../../core/theme/app_theme.dart';
import '../about/about_page.dart';
import '../insights/achievements_page.dart';

class SettingsPage extends StatefulWidget {
  final AppSettings settings;
  final Future<void> Function() onImport;
  final Future<void> Function() onExport;
  final List<Deck>? decks;

  const SettingsPage({super.key, required this.settings, required this.onImport, required this.onExport, this.decks});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final music = MusicService.instance;
  bool previewPlaying = false;
  String s(String key) => AppStrings.t(context, key);

  @override
  void dispose() {
    if (previewPlaying) music.stop();
    super.dispose();
  }

  Future<void> _languagePicker() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final q = controller.text.trim().toLowerCase();
          final list = AppSettings.languages.where((item) => q.isEmpty || '${item.nativeName} ${item.name} ${item.code}'.toLowerCase().contains(q)).toList();
          return AlertDialog(
            title: Text(s('choose_language')),
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: Column(
                children: [
                  TextField(controller: controller, onChanged: (_) => setDialogState(() {}), decoration: InputDecoration(hintText: s('search'), prefixIcon: const Icon(Icons.search_outlined))),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final lang = list[index];
                        final active = lang.code == widget.settings.languageCode;
                        return ListTile(
                          leading: CircleAvatar(child: Text(lang.code.split('-').first.toUpperCase())),
                          title: Text(lang.nativeName, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(_localizedLanguageName(lang.code, widget.settings.languageCode)),
                          trailing: active ? Icon(Icons.check_circle, color: Theme.of(dialogContext).colorScheme.primary) : null,
                          onTap: () async {
                            await widget.settings.setLanguage(lang.code);
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(s('cancel')))],
          );
        },
      ),
    );
    controller.dispose();
  }

  String _localizedLanguageName(String targetCode, String uiCode) {
    const native = <String, String>{
      'fa':'فارسی','en':'English','de':'Deutsch','de-CH':'Deutsch (Schweiz)','de-AT':'Deutsch (Österreich)','nl':'Nederlands','es':'Español','pt':'Português','fr':'Français','da':'Dansk','no':'Norsk','fi':'Suomi','sv':'Svenska','is':'Íslenska','el':'Ελληνικά','ar':'العربية','he':'עברית','ja':'日本語','ko':'한국어','it':'Italiano','tr':'Türkçe',
    };
    return native[targetCode] ?? targetCode;
  }

  Future<void> _togglePreview() async {
    try {
      if (previewPlaying) {
        await music.pause();
      } else {
        await music.play(widget.settings.musicTrack, volume: widget.settings.musicVolume);
      }
      if (mounted) setState(() => previewPlaying = !previewPlaying);
    } catch (_) {
      if (mounted) setState(() => previewPlaying = false);
    }
  }

  Future<void> _openAchievements() async {
    final decks = widget.decks ?? <Deck>[];
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AchievementsPage(decks: decks, settings: widget.settings)));
  }

  Future<void> _openRepository() async {
    final opened = await launchUrl(Uri.parse('https://github.com/Parin-M/parin-litner'), mode: LaunchMode.externalApplication);
    if (!opened && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('about_open_error'))));
  }

  Widget _switchRow(String key, IconData icon, bool value) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon),
      title: Text(s(key), style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(s('${key}_sub')),
      value: value,
      onChanged: (v) => widget.settings.setBool(key, v),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) {
        final compact = widget.settings.compactSettings;
        return Scaffold(
          appBar: AppBar(title: Text(s('settings'))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            children: [
              _Section(title: s('language'), icon: Icons.language_outlined, compact: compact, child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.translate_outlined), title: Text(s('ui_language'), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(AppStrings.names[widget.settings.languageCode] ?? widget.settings.languageCode), trailing: const Icon(Icons.chevron_right), onTap: _languagePicker)),
              const SizedBox(height: 12),
              _Section(
                title: s('appearance'),
                icon: Icons.palette_outlined,
                compact: compact,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s('visual_style'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(avatar: const Icon(Icons.light_mode_outlined, size: 17), label: Text(s('mode_light')), selected: widget.settings.appearanceMode == 'light', onSelected: (v) { if (v) widget.settings.setAppearanceMode('light'); }),
                      ChoiceChip(avatar: const Icon(Icons.dark_mode_outlined, size: 17), label: Text(s('mode_dark')), selected: widget.settings.appearanceMode == 'dark', onSelected: (v) { if (v) widget.settings.setAppearanceMode('dark'); }),
                      ChoiceChip(avatar: const Icon(Icons.blur_on_outlined, size: 17), label: Text(s('mode_aero')), selected: widget.settings.appearanceMode == 'aero', onSelected: (v) { if (v) widget.settings.setAppearanceMode('aero'); }),
                      ChoiceChip(avatar: const Icon(Icons.brightness_2_outlined, size: 17), label: Text(s('mode_amoled')), selected: widget.settings.appearanceMode == 'amoled', onSelected: (v) { if (v) widget.settings.setAppearanceMode('amoled'); }),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(s('theme'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 104,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppTheme.themes.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 9),
                      itemBuilder: (_, index) {
                        final theme = AppTheme.themes[index];
                        final active = index == widget.settings.themeIndex;
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => widget.settings.setTheme(index),
                          child: Container(
                            width: 128,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [theme.primary, theme.secondary]),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: active ? Colors.white : Colors.white54, width: active ? 3 : 1),
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(active ? Icons.check_circle : Icons.palette_outlined, color: Colors.white),
                              const SizedBox(height: 4),
                              Text('${index + 1}. ${_localizedThemeName(widget.settings.languageCode, index)}', maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                  SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(s('glass')), subtitle: Text(s('glass_sub')), value: widget.settings.glass, onChanged: (v) => widget.settings.setBool('glass', v)),
                  if (widget.settings.glass) Row(children: [Expanded(child: Slider(value: widget.settings.glassOpacity, min: .30, max: .90, divisions: 12, onChanged: widget.settings.setGlassOpacity)), Text('${(widget.settings.glassOpacity * 100).round()}%')]),
                ]),
              ),
              const SizedBox(height: 12),
              _Section(title: s('experience'), icon: Icons.tune_outlined, compact: compact, child: Column(children: [
                _switchRow('animations', Icons.auto_awesome_outlined, widget.settings.animations),
                _switchRow('haptics', Icons.vibration_outlined, widget.settings.haptics),
                _switchRow('auto_reveal', Icons.flip_outlined, widget.settings.autoReveal),
                _switchRow('progress', Icons.linear_scale_outlined, widget.settings.showProgress),
                _switchRow('timer', Icons.timer_outlined, widget.settings.showTimer),
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.flag_outlined), title: Text(s('daily_goal')), trailing: Text('${widget.settings.dailyGoal}'), subtitle: Slider(value: widget.settings.dailyGoal.toDouble(), min: 5, max: 100, divisions: 19, onChanged: (v) => widget.settings.setDailyGoal(v.round()))),
              ])),
              const SizedBox(height: 12),
              _Section(title: s('study_preferences'), icon: Icons.school_outlined, compact: compact, child: Column(children: [
                _switchRow('show_xp', Icons.bolt_outlined, widget.settings.showXp),
                _switchRow('confirm_exit', Icons.exit_to_app_outlined, widget.settings.confirmExit),
                _switchRow('compact_settings', Icons.density_small_outlined, widget.settings.compactSettings),
              ])),
              const SizedBox(height: 12),
              _Section(title: s('music'), icon: Icons.music_note_outlined, compact: compact, child: Column(children: [
                SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(s('music_study')), value: widget.settings.musicEnabled, onChanged: (v) async { await widget.settings.setBool('music_enabled', v); if (!v) { await music.stop(); if (mounted) setState(() => previewPlaying = false); } }),
                if (widget.settings.musicEnabled) ...[
                  DropdownButtonFormField<String>(initialValue: widget.settings.musicTrack, isExpanded: true, decoration: InputDecoration(labelText: s('music')), items: [for (final track in MusicService.tracks) DropdownMenuItem(value: track.id, child: Text(track.title))], onChanged: (v) async { if (v != null) { await widget.settings.setMusicTrack(v); if (previewPlaying) await music.play(v, volume: widget.settings.musicVolume); } }),
                  Row(children: [const Icon(Icons.volume_down_outlined), Expanded(child: Slider(value: widget.settings.musicVolume, min: .05, max: .8, divisions: 15, onChanged: (v) async { await widget.settings.setMusicVolume(v); if (previewPlaying) await music.setVolume(v); })), const Icon(Icons.volume_up_outlined)]),
                  Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton.icon(onPressed: _togglePreview, icon: Icon(previewPlaying ? Icons.pause : Icons.play_arrow), label: Text(s('music_btn')))),
                ],
              ])),
              const SizedBox(height: 12),
              _Section(title: s('backup'), icon: Icons.backup_outlined, compact: compact, child: Row(children: [Expanded(child: OutlinedButton.icon(onPressed: widget.onExport, icon: const Icon(Icons.upload_file_outlined), label: Text(s('export')))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: widget.onImport, icon: const Icon(Icons.download_outlined), label: Text(s('import'))))])),
              const SizedBox(height: 12),
              _Section(title: s('extra'), icon: Icons.auto_awesome_outlined, compact: compact, child: Column(children: [
                ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.workspace_premium_outlined)), title: Text(s('achievement_center'), style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(s('achievement_center_sub')), trailing: const Icon(Icons.chevron_right), onTap: _openAchievements),
                const Divider(height: 1),
                ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.info_outline)), title: Text(s('about'), style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(s('about_creator')), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutPage()))),
                const Divider(height: 1),
                ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.code_rounded)), title: Text(s('about_github'), style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(s('about_repo_desc')), trailing: const Icon(Icons.open_in_new_rounded), onTap: _openRepository),
              ])),
            ],
          ),
        );
      },
    );
  }
}

String _localizedThemeName(String code, int index) {
  const names = <String, List<String>>{
    'fa':['آسمان','اقیانوس','نعنایی','زمرد','لیمویی','طلایی','مرجانی','رز','یاسی','لاوندر','نیلی','بنفش','قرمز','خاکی','فیروزه‌ای','آبی یخی','سبز تیره','توتی','گرافیتی','شیشه خالص','طلوع','غروب','هلویی','زردآلو','شن','برنز','مسی','یاقوت','شرابی','آلویی','ارکیده','مه بنفش','نیمه‌شب','سرمه‌ای','قطبی','یخچال','جنگل','کاج','خزه','زیتونی','مریم‌گلی','سبزآبی','آکوآ','فیروزه روشن','لاجوردی','کبالت','یاقوت کبود','آمیتیست','زغالی','سنگی'],
    'da':['Himmel','Ocean','Mint','Smaragd','Lime','Guld','Korall','Rose','Lilla','Lavendel','Indigo','Lilla','Rød','Jord','Turkis','Iseblå','Mørkegrøn','Bær','Grafit','Rent glas','Solopgang','Solnedgang','Fersken','Abrikos','Sand','Bronze','Kobber','Rubin','Vin','Blomme','Orkidé','Violet tåge','Midnat','Marineblå','Arktisk','Gletsjer','Skov','Fyr','Mos','Oliven','Salvie','Blågrøn','Aqua','Cyan','Azurblå','Kobolt','Safir','Ametyst','Kul','Skifer'],
    'de':['Himmel','Ozean','Minze','Smaragd','Limette','Gold','Koralle','Rose','Flieder','Lavendel','Indigo','Violett','Rot','Erde','Türkis','Eisblau','Dunkelgrün','Beere','Graphit','Reines Glas','Sonnenaufgang','Sonnenuntergang','Pfirsich','Aprikose','Sand','Bronze','Kupfer','Rubin','Wein','Pflaume','Orchidee','Violetter Nebel','Mitternacht','Marineblau','Arktis','Gletscher','Wald','Kiefer','Moos','Olive','Salbei','Petrol','Aqua','Cyan','Azur','Kobalt','Saphir','Amethyst','Anthrazit','Schiefer'],
    'fi':['Taivas','Meri','Minttu','Smaragdi','Lime','Kulta','Koralli','Ruusu','Syreeni','Laventeli','Indigo','Violetti','Punainen','Maa','Turkoosi','Jäänsininen','Tummanvihreä','Marja','Grafiitti','Puhdas lasi','Auringonnousu','Auringonlasku','Persikka','Aprikoosi','Hiekka','Pronssi','Kupari','Rubiini','Viini','Luumu','Orkidea','Violettisumu','Keskiyö','Laivastonsininen','Arktinen','Jäätikkö','Metsä','Mänty','Sammal','Oliivi','Salvia','Sinivihreä','Aqua','Syaani','Taivaansininen','Koboltti','Safiiri','Ametisti','Hiili','Liuskekivi'],
    'no':['Himmel','Hav','Mynte','Smaragd','Lime','Gull','Korall','Rose','Syrin','Lavendel','Indigo','Lilla','Rød','Jord','Turkis','Isblå','Mørkegrønn','Bær','Grafitt','Rent glass','Soloppgang','Solnedgang','Fersken','Aprikos','Sand','Bronse','Kobber','Rubin','Vin','Plomme','Orkidé','Fiolett tåke','Midnatt','Marineblå','Arktisk','Isbre','Skog','Furu','Mose','Oliven','Salvie','Blågrønn','Aqua','Cyan','Asurblå','Kobolt','Safir','Ametyst','Kull','Skifer'],
    'is':['Himinn','Haf','Mynta','Smaragð','Límóna','Gull','Kórall','Rós','Lilac','Lavender','Indigo','Fjólublár','Rauður','Jörð','Túrkís','Ísblár','Dökkgrænn','Ber','Grafít','Hreint gler','Sólarupprás','Sólsetur','Ferskja','Apríkósa','Sandur','Brons','Kopar','Rúbín','Vín','Plóma','Orkídea','Fjólublá þoka','Miðnætti','Dökkblár','Heimskaut','Jökull','Skógur','Fura','Mosi','Ólívu','Salvía','Blágrænn','Aqua','Cyan','Azure','Kóbalt','Safír','Amþyst','Kol','Leirsteinn'],
    'ja':['空','海','ミント','エメラルド','ライム','ゴールド','コーラル','ローズ','ライラック','ラベンダー','インディゴ','パープル','レッド','アース','ターコイズ','アイスブルー','ダークグリーン','ベリー','グラファイト','ピュアガラス','日の出','夕焼け','ピーチ','アプリコット','サンド','ブロンズ','カッパー','ルビー','ワイン','プラム','オーキッド','バイオレットミスト','ミッドナイト','ネイビー','アークティック','グレイシャー','フォレスト','パイン','モス','オリーブ','セージ','ティール','アクア','シアン','アズール','コバルト','サファイア','アメジスト','チャコール','スレート'],
    'ko':['하늘','바다','민트','에메랄드','라임','골드','코랄','로즈','라일락','라벤더','인디고','퍼플','레드','어스','터콰이즈','아이스 블루','다크 그린','베리','그래파이트','퓨어 글래스','일출','석양','피치','살구','샌드','브론즈','코퍼','루비','와인','플럼','오키드','바이올렛 미스트','미드나이트','네이비','아틱','글레이셔','포레스트','파인','모스','올리브','세이지','틸','아쿠아','시안','애저','코발트','사파이어','아메시스트','차콜','슬레이트'],
  };
  final list = names[code] ?? names['de']!;
  return list[index.clamp(0, list.length - 1).toInt()];
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool compact;

  const _Section({required this.title, required this.icon, required this.child, required this.compact});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final padding = compact ? 12.0 : 18.0;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: scheme.brightness == Brightness.dark ? .96 : .88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: .20)),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: scheme.brightness == Brightness.dark ? .05 : .08), blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [Icon(icon, color: scheme.primary), const SizedBox(width: 8), Expanded(child: Text(title, style: TextStyle(fontSize: compact ? 16 : 18, fontWeight: FontWeight.w900)))]),
          const Divider(height: 22),
          child,
        ],
      ),
    );
  }
}
