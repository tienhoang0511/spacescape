import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flame/sprite.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/overlays/pause_menu.dart';
import '../widgets/overlays/pause_button.dart';
import '../widgets/overlays/game_over_menu.dart';

import '../models/player_data.dart';
import '../models/spaceship_details.dart';

import 'enemy.dart';
import 'player.dart';
import 'bullet.dart';
import 'command.dart';
import 'power_ups.dart';
import 'enemy_manager.dart';
import 'knows_game_size.dart';
import 'power_up_manager.dart';
import 'audio_player_component.dart';

// Lớp này chịu trách nhiệm cho việc khởi tạo và chạy game-loop.
class SpacescapeGame extends BaseGame
    with HasCollidables, HasDraggableComponents {
  // Biển tham chiếu đến người chơi component
  late Player _player;

  // Biến tham chiếu đến sprite sheet chính.
  late SpriteSheet spriteSheet;

  // Tham chiếu đến quản lý đối tượng kẻ thù
  late EnemyManager _enemyManager;

  // Tham chiếu đến quản lý sức mạnh của đối tượng
  late PowerUpManager _powerUpManager;

  // Hiển thị điểm số phía trên góc trái màn hình.
  late TextComponent _playerScore;

  // Hiển thị lượng máu của nhân vật góc trên phải màn hình.
  late TextComponent _playerHealth;

  // Trình quản lý âm thanh
  late AudioPlayerComponent _audioPlayerComponent;

  // Danh sách các lệnh sẽ được xử lý trong cập nhật hiện tại.
  final _commandList = List<Command>.empty(growable: true);

  // Danh sách các lệnh sẽ được xử lý trong cập nhật tiếp theo.
  final _addLaterCommandList = List<Command>.empty(growable: true);

  // Cờ cho biết trò chơi bắt đầu hay chưa
  bool _isAlreadyLoaded = false;

  // Phương thức này được gọi bởi Flame trước khi game-loop bắt đầu.
  //  Việc tải các assets và thêm components sẽ được thực hiện tại đây.
  @override
  Future<void> onLoad() async {
    // Khởi tạo và bắt đầu game
    if (!_isAlreadyLoaded) {
      // Tải và lưu trữ tất cả các hình ảnh để sử dụng sau này.
      await images.loadAll([
        'simpleSpace_tilesheet@2.png',
        'freeze.png',
        'icon_plusSmall.png',
        'multi_fire.png',
        'nuke.png',
      ]);

      // Khởi tạo âm thanh
      _audioPlayerComponent = AudioPlayerComponent();
      add(_audioPlayerComponent);

      // Tải hình nền và set repeat cho hình nền
      ParallaxComponent _stars = await ParallaxComponent.load(
        [
          ParallaxImageData('stars1.png'),
          ParallaxImageData('stars2.png'),
        ],
        repeat: ImageRepeat.repeat,
        baseVelocity: Vector2(0, -50),
        velocityMultiplierDelta: Vector2(0, 1.5),
      );
      add(_stars);

      // Tải hình ảnh sprite các đối tượng  trong game
      spriteSheet = SpriteSheet.fromColumnsAndRows(
        image: images.fromCache('simpleSpace_tilesheet@2.png'),
        columns: 8,
        rows: 6,
      );

      /// Vì `context` không có trong phương thức onLoad (),
      /// nên không thể tải [PlayerData] hiện tại ở đây.
      /// Vì vậy, ta sẽ khởi tạo phi thuyền cho người chơi
      /// với giá trị SpaceshipType.Canary mặc định.
      final spaceshipType = SpaceshipType.Canary;
      final spaceship = Spaceship.getSpaceshipByType(spaceshipType);

      _player = Player(
        spaceshipType: spaceshipType,
        sprite: spriteSheet.getSpriteById(spaceship.spriteId),
        size: Vector2(64, 64),
        position: viewport.canvasSize / 2,
      );

      // Cho player căn giữa
      _player.anchor = Anchor.center;
      add(_player);

      // Khởi tạo bộ quản lý kẻ thù
      _enemyManager = EnemyManager(spriteSheet: spriteSheet);
      add(_enemyManager);

      // Khởi tạo bộ quản lý
      _powerUpManager = PowerUpManager();
      add(_powerUpManager);

      // Create a basic joystick component with a joystick on left
      // and a fire button on right.
      final joystick = JoystickComponent(
        gameRef: this,
        directional: JoystickDirectional(
          size: 100,
        ),
        actions: [
          JoystickAction(
            actionId: 0,
            size: 60,
            margin: const EdgeInsets.all(
              30,
            ),
          ),
        ],
      );

      // Make sure to add player as an observer of this joystick.
      joystick.addObserver(_player);
      add(joystick);

      // Create text component for player score.
      _playerScore = TextComponent(
        'Score: 0',
        position: Vector2(10, 10),
        textRenderer: TextPaint(
          config: TextPaintConfig(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'BungeeInline',
          ),
        ),
      );

      // Setting isHud to true makes sure that this component
      // does not get affected by camera's transformations.
      _playerScore.isHud = true;

      add(_playerScore);

      // Create text component for player health.
      _playerHealth = TextComponent(
        'Health: 100%',
        position: Vector2(size.x - 10, 10),
        textRenderer: TextPaint(
          config: TextPaintConfig(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'BungeeInline',
          ),
        ),
      );

      // Anchor to top right as we want the top right
      // corner of this component to be at a specific position.
      _playerHealth.anchor = Anchor.topRight;

      // Setting isHud to true makes sure that this component
      // does not get affected by camera's transformations.
      _playerHealth.isHud = true;

      add(_playerHealth);

      // Set this to true so that we do not initilize
      // everything again in the same session.
      _isAlreadyLoaded = true;
    }
  }

  // Phương thức này được gọi khi phiên trò chơi được gán vào
  // tới widget tree của Flutter.
  @override
  void onAttach() {
    if (buildContext != null) {
      // Lấy PlayerData
      final playerData = Provider.of<PlayerData>(buildContext!, listen: false);
      // Cập nhật loại tàu vũ trụ hiện tại của người chơi.
      _player.setSpaceshipType(playerData.spaceshipType);
    }
    _audioPlayerComponent.playBgm('9. Space Invaders.wav'); // Phát âm thanh nền
    super.onAttach();
  }

  // Gọi lúc class này bị xóa
  @override
  void onDetach() {
    _audioPlayerComponent.stopBgm(); // dừng âm thanh nền
    super.onDetach();
  }

  @override
  void prepare(Component c) {
    super.prepare(c);
    // Nếu thành phần đang được chuẩn bị là loại KnowsGameSize,
    // gọi onResize () trên nó để nó lưu trữ kích thước màn hình trò chơi hiện tại.
    if (c is KnowsGameSize) {
      c.onResize(this.size);
    }
  }

  @override
  void onResize(Vector2 canvasSize) {
    super.onResize(canvasSize);

    // Lặp lại tất cả các thành phần của kiểu KnowsGameSize và sau đó thay đổi kích thước.
    this.components.whereType<KnowsGameSize>().forEach((component) {
      component.onResize(this.size);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Chạy từng lệnh từ _commandList trên mỗi
    // thành phần từ danh sách thành phần. Chạy ()
    // phương thức của Command là no-op nếu lệnh là
    // không hợp lệ cho thành phần đã cho.
    _commandList.forEach((command) {
      components.forEach((component) {
        command.run(component);
      });
    });

    // Remove all the commands that are processed and
    // add all new commands to be processed in next update.
    _commandList.clear();
    _commandList.addAll(_addLaterCommandList);
    _addLaterCommandList.clear();

    // Update score and health components with latest values.
    _playerScore.text = 'Score: ${_player.score}';
    _playerHealth.text = 'Health: ${_player.health}%';

    /// Display [GameOverMenu] when [Player.health] becomes
    /// zero and camera stops shaking.
    if (_player.health <= 0 && (!camera.shaking)) {
      this.pauseEngine(); // tạm dừng trò chơi
      this.overlays.remove(PauseButton.ID);
      this.overlays.add(GameOverMenu.ID);
    }
  }

  @override
  void render(Canvas canvas) {
    // Draws a rectangular health bar at top right corner.
    canvas.drawRect(
      Rect.fromLTWH(size.x - 110, 10, _player.health.toDouble(), 20),
      Paint()..color = Colors.blue,
    );

    super.render(canvas);
  }

  // Xử lý lifecyle
  @override
  void lifecycleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (this._player.health > 0) {
          this.pauseEngine(); // tạm dừng trò chơi
          this.overlays.remove(PauseButton.ID);
          this.overlays.add(PauseMenu.ID);
        }
        break;
    }

    super.lifecycleStateChange(state);
  }

  // Adds given command to command list.
  void addCommand(Command command) {
    _addLaterCommandList.add(command);
  }

  // Resets the game to inital state. Should be called
  // while restarting and exiting the game.
  void reset() {
    // First reset player, enemy manager and power-up manager .
    _player.reset();
    _enemyManager.reset();
    _powerUpManager.reset();

    // Now remove all the enemies, bullets and power ups
    // from the game world. Note that, we are not calling
    // Enemy.destroy() because it will unnecessarily
    // run explosion effect and increase players score.
    components.whereType<Enemy>().forEach((enemy) {
      enemy.remove();
    });

    components.whereType<Bullet>().forEach((bullet) {
      bullet.remove();
    });

    components.whereType<PowerUp>().forEach((powerUp) {
      powerUp.remove();
    });
  }
}
