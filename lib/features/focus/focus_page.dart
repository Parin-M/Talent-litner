import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/models/app_settings.dart';
import '../../core/services/music_service.dart';

class FocusPage extends StatefulWidget {
  final AppSettings settings;
  const FocusPage({super.key, required this.settings});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  Timer? _timer;
  int _selectedMinutes = 30;
  int _remaining = 30 * 60;
  final TextEditingController _customController = TextEditingController(text: '60');
  final AudioPlayer _alarmPlayer = AudioPlayer();
  bool _running = false;
  bool _musicPlaying = false;

  String s(String key) => AppStrings.t(context, key);

  @override
  void initState() {
    super.initState();
    unawaited(_alarmPlayer.setReleaseMode(ReleaseMode.stop));
  }

  void _selectMinutes(int minutes) {
    if (_running) return;
    setState(() {
      _selectedMinutes = minutes.clamp(1, 180).toInt();
      _remaining = _selectedMinutes * 60;
    });
  }

  Future<void> _applyCustomMinutes() async {
    if (_running) return;
    final value = int.tryParse(_customController.text.trim());
    if (value == null || value < 1 || value > 600) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s('focus_custom_invalid'))),
      );
      return;
    }
    setState(() {
      _selectedMinutes = value;
      _remaining = value * 60;
    });
  }

  Future<void> _playAlarm() async {
    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.play(BytesSource(_makeAlarmWave()));
    } catch (_) {
      // Keep a native system alert as fallback if the audio engine is unavailable.
      try { await SystemSound.play(SystemSoundType.alert); } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 250));
      try { await SystemSound.play(SystemSoundType.alert); } catch (_) {}
    }
  }

  Future<void> _toggle() async {
    if (!_running && _remaining == 0) {
      setState(() => _remaining = _selectedMinutes * 60);
    }
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    if (widget.settings.musicEnabled && !_musicPlaying) {
      try {
        await MusicService.instance.play(widget.settings.musicTrack, volume: widget.settings.musicVolume);
        if (mounted) setState(() => _musicPlaying = true);
      } catch (_) {}
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (_remaining <= 1) {
        _timer?.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
        if (_musicPlaying) {
          await MusicService.instance.stop();
          if (mounted) setState(() => _musicPlaying = false);
        }
        await _playAlarm();
        if (widget.settings.haptics) {
          try {
            await Vibration.vibrate(pattern: [0, 350, 180, 350, 180, 600]);
          } catch (_) {
            try { await HapticFeedback.vibrate(); } catch (_) {}
          }
        }
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(s('focus_done')),
              content: Text('${_selectedMinutes} ${s('focus_minutes')}'),
              actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(s('great')))],
            ),
          );
        }
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _selectedMinutes * 60;
    });
  }

  String _formatTime() {
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _customController.dispose();
    _alarmPlayer.dispose();
    if (_musicPlaying) MusicService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _selectedMinutes * 60;
    final progress = total == 0 ? 0.0 : (1 - _remaining / total).clamp(0.0, 1.0).toDouble();
    return Scaffold(
      appBar: AppBar(title: Text(s('focus_mode'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  Icon(Icons.self_improvement_outlined, size: 54, color: scheme.primary),
                  const SizedBox(height: 10),
                  Text(s('focus_title'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(s('focus_sub'), textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 28),
                  Stack(alignment: Alignment.center, children: [
                    SizedBox(width: 220, height: 220, child: CircularProgressIndicator(value: progress, strokeWidth: 12)),
                    Text(_formatTime(), style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 28),
                  Text(s('select_duration'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final minutes in [15, 30, 45])
                        ChoiceChip(
                          label: Text('${minutes} ${s('focus_minutes')}'),
                          selected: _selectedMinutes == minutes,
                          onSelected: _running ? null : (_) => _selectMinutes(minutes),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          enabled: !_running,
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          decoration: InputDecoration(
                            labelText: s('focus_custom_minutes'),
                            helperText: s('focus_custom_range'),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: FilledButton(
                          onPressed: _running ? null : _applyCustomMinutes,
                          child: Text(s('apply')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(children: [
                    Expanded(child: FilledButton.icon(onPressed: _toggle, icon: Icon(_running ? Icons.pause : Icons.play_arrow), label: Text(_running ? s('pause') : s('start_focus')))),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(onPressed: _reset, tooltip: s('reset'), icon: const Icon(Icons.restart_alt)),
                  ]),
                  if (widget.settings.musicEnabled) ...[
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_musicPlaying ? Icons.music_note : Icons.music_off),
                      title: Text(s('focus_music')),
                      trailing: Switch(value: _musicPlaying, onChanged: (_) => _toggleMusic()),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMusic() async {
    if (_musicPlaying) {
      await MusicService.instance.pause();
      if (mounted) setState(() => _musicPlaying = false);
    } else {
      try {
        await MusicService.instance.play(widget.settings.musicTrack, volume: widget.settings.musicVolume);
        if (mounted) setState(() => _musicPlaying = true);
      } catch (_) {}
    }
  }
}

Uint8List _makeAlarmWave() {
  const sampleRate = 22050;
  const int segments = 5;
  const double segmentSeconds = .42;
  const double pauseSeconds = .13;
  final totalSeconds = segments * segmentSeconds + (segments - 1) * pauseSeconds;
  final sampleCount = (sampleRate * totalSeconds).round();
  final dataBytes = sampleCount * 2;
  final bytes = Uint8List(44 + dataBytes);
  final view = ByteData.sublistView(bytes);
  void ascii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes[offset + i] = value.codeUnitAt(i);
    }
  }
  ascii(0, 'RIFF');
  view.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  view.setUint32(16, 16, Endian.little);
  view.setUint16(20, 1, Endian.little);
  view.setUint16(22, 1, Endian.little);
  view.setUint32(24, sampleRate, Endian.little);
  view.setUint32(28, sampleRate * 2, Endian.little);
  view.setUint16(32, 2, Endian.little);
  view.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  view.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    final cycle = segmentSeconds + pauseSeconds;
    final pos = t % cycle;
    final active = t < totalSeconds - pauseSeconds && pos < segmentSeconds;
    var value = 0.0;
    if (active) {
      final freq = (t / cycle).floor().isEven ? 880.0 : 660.0;
      final edge = math.min(1.0, math.min(pos / .015, (segmentSeconds - pos) / .015));
      value = math.sin(2 * math.pi * freq * t) * .72 * edge;
    }
    view.setInt16(44 + i * 2, (value * 32767).round().clamp(-32768, 32767).toInt(), Endian.little);
  }
  return bytes;
}
