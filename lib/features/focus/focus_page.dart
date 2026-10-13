import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
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
  bool _running = false;
  bool _musicPlaying = false;
  final AudioPlayer _alarmPlayer = AudioPlayer();

  String s(String key) => AppStrings.t(context, key);

  void _selectMinutes(int minutes) {
    if (_running || minutes < 1 || minutes > 600) return;
    setState(() {
      _selectedMinutes = minutes;
      _remaining = minutes * 60;
    });
  }

  Future<void> _chooseCustomDuration() async {
    if (_running) return;
    final controller = TextEditingController(
      text: [15, 30, 45].contains(_selectedMinutes) ? '' : '$_selectedMinutes',
    );
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s('custom_minutes')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 3,
          decoration: InputDecoration(
            labelText: s('enter_minutes'),
            helperText: s('minutes_range'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text.trim());
              if (minutes != null && minutes >= 1 && minutes <= 600) {
                Navigator.pop(dialogContext, minutes);
              }
            },
            child: Text(s('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && mounted) _selectMinutes(value);
  }

  Future<void> _playAlarm() async {
    if (widget.settings.haptics) {
      try { HapticFeedback.vibrate(); } catch (_) {}
    }
    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.stop);
      await _alarmPlayer.setVolume(1.0);
      await _alarmPlayer.play(BytesSource(_buildAlarmWav()));
    } catch (_) {
      // Fallback in case a device cannot initialize the bundled alert player.
      for (var i = 0; i < 3; i++) {
        try { await SystemSound.play(SystemSoundType.alert); } catch (_) {}
        if (i < 2) await Future<void>.delayed(const Duration(milliseconds: 450));
      }
    }
  }

  Uint8List _buildAlarmWav() {
    // Generate an audible three-pulse WAV in memory so the completion alarm
    // does not depend on a device-specific alert sound or a packaged asset.
    const sampleRate = 8000;
    const seconds = 1.15;
    final sampleCount = (sampleRate * seconds).round();
    final bytes = Uint8List(44 + sampleCount * 2);
    final header = ByteData.sublistView(bytes);
    void writeTag(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes[offset + i] = value.codeUnitAt(i);
      }
    }
    writeTag(0, 'RIFF');
    header.setUint32(4, bytes.length - 8, Endian.little);
    writeTag(8, 'WAVE');
    writeTag(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    writeTag(36, 'data');
    header.setUint32(40, sampleCount * 2, Endian.little);

    const pulsePeriod = .36;
    const pulseLength = .23;
    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final local = t % pulsePeriod;
      var envelope = 0.0;
      if (local < pulseLength) {
        final fadeIn = math.min(1.0, local / .018);
        final fadeOut = math.min(1.0, (pulseLength - local) / .045);
        envelope = fadeIn * fadeOut;
      }
      final frequency = local < .115 ? 880.0 : 660.0;
      final sample = (math.sin(2 * math.pi * frequency * t) * envelope * 0.72 * 32767).round();
      header.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes;
  }

  Future<void> _toggle() async {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    if (widget.settings.musicEnabled && !_musicPlaying) {
      try {
        await MusicService.instance.play(
          widget.settings.musicTrack,
          volume: widget.settings.musicVolume,
        );
        if (mounted) setState(() => _musicPlaying = true);
      } catch (_) {}
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || !_running) return;
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
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(s('focus_done')),
            content: Text('$_selectedMinutes ${s('focus_minutes')}'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(s('great')),
              ),
            ],
          ),
        );
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
    if (_musicPlaying) MusicService.instance.stop();
    unawaited(_alarmPlayer.dispose());
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
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  color: scheme.primary,
                  alignment: Alignment.center,
                  child: const Icon(Icons.self_improvement_outlined, size: 30, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(s('focus_title'), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w300)),
                const SizedBox(height: 4),
                Text(s('focus_sub'), textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 22),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(width: 190, height: 190, child: CircularProgressIndicator(value: progress, strokeWidth: 8)),
                    Text(_formatTime(), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w300)),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(s('select_duration'), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final minutes in [15, 30, 45])
                      ChoiceChip(
                        label: Text('$minutes ${s('focus_minutes')}'),
                        selected: _selectedMinutes == minutes,
                        onSelected: _running ? null : (_) => _selectMinutes(minutes),
                      ),
                    OutlinedButton.icon(
                      onPressed: _running ? null : _chooseCustomDuration,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(
                        [15, 30, 45].contains(_selectedMinutes)
                            ? s('custom_minutes')
                            : '$_selectedMinutes ${s('focus_minutes')}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _toggle,
                        icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                        label: Text(_running ? s('pause') : s('start_focus')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(onPressed: _reset, tooltip: s('reset'), icon: const Icon(Icons.restart_alt)),
                  ],
                ),
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
