import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:provider/provider.dart';

import 'game.dart';

import '../models/settings.dart';

/// Lớp này phụ trách việc quản lý âm thanh của game
class AudioPlayerComponent extends Component with HasGameRef<SpacescapeGame> {
  @override
  Future<void>? onLoad() async {
    // Khởi tạo âm thanh nền và tải các file âm thanh tương tác của game
    FlameAudio.bgm.initialize();

    await FlameAudio.audioCache.loadAll([
      'laser1.ogg',
      'powerUp6.ogg',
      '9. Space Invaders.wav',
      'laserSmall_001.ogg'
    ]);

    return super.onLoad();
  }

  // Nếu settings bật thì phát âm thanh nền
  void playBgm(String filename) {
    if (gameRef.buildContext != null) {
      if (Provider.of<Settings>(gameRef.buildContext!, listen: false)
          .backgroundMusic) {
        FlameAudio.bgm.play(filename);
      }
    }
  }

  // Nếu settings được bật thì phát âm thanh tương tác
  void playSfx(String filename) {
    if (gameRef.buildContext != null) {
      if (Provider.of<Settings>(gameRef.buildContext!, listen: false)
          .soundEffects) {
        FlameAudio.play(filename);
      }
    }
  }

  // Dừng âm thanh nền
  void stopBgm() {
    FlameAudio.bgm.stop();
  }
}
