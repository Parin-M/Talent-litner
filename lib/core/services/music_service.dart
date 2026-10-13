import 'package:audioplayers/audioplayers.dart';

class MusicTrack {
  final String id;
  final String title;
  final String asset;
  const MusicTrack(this.id, this.title, this.asset);
}

class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();

  final AudioPlayer player = AudioPlayer();
  static const tracks = <MusicTrack>[
    MusicTrack('lofi_night', 'Lo-fi Night', 'audio/lofi_night.wav'),
    MusicTrack('rainy_focus', 'Rainy Focus', 'audio/rainy_focus.wav'),
    MusicTrack('deep_focus', 'Deep Focus', 'audio/deep_focus.wav'),
  ];

  Future<void> play(String id, {double volume = .35}) async {
    final track = tracks.firstWhere((t) => t.id == id, orElse: () => tracks.first);
    await player.stop();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(volume.clamp(0.0, 1.0).toDouble());
    await player.play(AssetSource(track.asset));
  }

  Future<void> playAlarm() async {
    await player.stop();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(1.0);
    await player.play(AssetSource('audio/focus_alarm.wav'));
  }

  Future<void> pause() => player.pause();
  Future<void> resume() => player.resume();
  Future<void> stop() => player.stop();
  Future<void> setVolume(double value) => player.setVolume(value.clamp(0.0, 1.0).toDouble());
  Future<void> dispose() => player.dispose();
}
