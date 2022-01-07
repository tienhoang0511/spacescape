import 'dart:math';

import 'package:flame/geometry.dart';
import 'package:flame/particles.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player_data.dart';
import '../models/spaceship_details.dart';

import 'game.dart';
import 'enemy.dart';
import 'bullet.dart';
import 'command.dart';
import 'knows_game_size.dart';
import 'audio_player_component.dart';

// Lớp này đại diện cho nhân vật người chơi trong trò chơi (phi thuyền)
class Player extends SpriteComponent
    with
        KnowsGameSize,
        Hitbox,
        Collidable,
        JoystickListener,
        HasGameRef<SpacescapeGame> {
  // Điều khiển hướng người chơi sẽ di chuyển.
  Vector2 _moveDirection = Vector2.zero();

  // Máu của người chơi
  int _health = 100;
  int get health => _health;

  // Phi thuyền
  Spaceship _spaceship;

  // Loại của phi thuyền
  SpaceshipType spaceshipType;

  // Tham chiếu đến dữ liệu của người chơi PlayerData
  late PlayerData _playerData;

  int get score => _playerData.currentScore;

  // Nếu đúng, phi thuyền sẽ bắn 3 viên đạn cùng một lúc.
  bool _shootMultipleBullets = false;

  // Kiểm soát thời gian hoạt động của power up
  late Timer _powerUpTimer;

  // tạo số ngẫu nhiên
  Random _random = Random();

  // Phương thức này tạo ra một vectơ ngẫu nhiên sao cho
  // thành phần x của nó nằm giữa [-100 đến 100] và
  // thành phần y nằm giữa [200, 400]
  Vector2 getRandomVector() {
    return (Vector2.random(_random) - Vector2(0.5, -1)) * 200;
  }

  Player({
    required this.spaceshipType,
    Sprite? sprite,
    Vector2? position,
    Vector2? size,
  })  : this._spaceship = Spaceship.getSpaceshipByType(spaceshipType),
        super(sprite: sprite, position: position, size: size) {
    // Đặt hẹn giờ power up thành 4 giây.
    // Sau 4 giây, chế độ bắn nhiều viên cùng lúc sẽ bị vô hiệu hóa
    _powerUpTimer = Timer(4, callback: () {
      _shootMultipleBullets = false;
    });
  }

  @override
  void onMount() {
    super.onMount();
    // Thêm một hitbox hình tròn với bán kính là 0,8
    // là kích thước nhỏ nhất của thành phần này.
    final shape = HitboxCircle(definition: 0.8);
    addShape(shape);

    _playerData = Provider.of<PlayerData>(gameRef.buildContext!, listen: false);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, Collidable other) {
    super.onCollision(intersectionPoints, other);

    // Nếu thực thể other là Kẻ thù, giảm 10 máu của người chơi.
    if (other is Enemy) {
      // Làm cho màn hình rung
      gameRef.camera.shake(intensity: 20);

      _health -= 10;
      if (_health <= 0) {
        _health = 0;
      }
    }
  }

  // Phương thức này được gọi bởi lớp game cho mọi frame
  @override
  void update(double dt) {
    super.update(dt);

    _powerUpTimer.update(dt);

    // Tăng vị trí hiện tại của người chơi theo (tốc độ * thời gian delta) dọc theo hướng di chuyển.
    // Thời gian Delta là thời gian đã trôi qua kể từ lần cập nhật cuối cùng.
    // Đối với các thiết bị có tốc độ khung hình cao hơn, thời gian delta sẽ nhỏ hơn
    // và đối với các thiết bị có tốc độ khung hình thấp hơn, nó sẽ lớn hơn.
    // Nhân tốc độ với delta time sẽ đảm bảo tốc độ của người chơi vẫn giữ nguyên bất kể tốc độ khung hình của thiết bị.
    this.position += _moveDirection.normalized() * _spaceship.speed * dt;

    // Set vị trí của player sao cho nó không nằm ngoài kích thước màn hình.
    this.position.clamp(
          Vector2.zero() + this.size / 2,
          gameSize - this.size / 2,
        );

    final particleComponent = ParticleComponent(
      particle: Particle.generate(
        count: 10,
        lifespan: 0.1,
        generator: (i) => AcceleratedParticle(
          acceleration: getRandomVector(),
          speed: getRandomVector(),
          position: (this.position.clone() + Vector2(0, this.size.y / 3)),
          child: CircleParticle(
            radius: 1,
            paint: Paint()..color = Colors.white,
          ),
        ),
      ),
    );

    gameRef.add(particleComponent);
  }

  // Thay đổi hướng di chuyển hiện tại với hướng di chuyển mới truyền vào
  void setMoveDirection(Vector2 newMoveDirection) {
    _moveDirection = newMoveDirection;
  }

  // Cần điều khiển bắn đạn
  @override
  void joystickAction(JoystickActionEvent event) {
    if (event.id == 0 && event.event == ActionEvent.down) {
      Bullet bullet = Bullet(
        sprite: gameRef.spriteSheet.getSpriteById(28),
        size: Vector2(64, 64),
        position: this.position.clone(),
        level: _spaceship.level,
      );

      // Căn giữa và thêm viên đạn vào màn chơi
      bullet.anchor = Anchor.center;
      gameRef.add(bullet);

      // Phát ra hiệu ứng bắn đạn
      gameRef.addCommand(Command<AudioPlayerComponent>(action: (audioPlayer) {
        audioPlayer.playSfx('laserSmall_001.ogg');
      }));

      // Nếu có nhiều viên đạn -> thêm hai viên đạn nữa (mặc định là 3 viên cùng lúc)
      // các viên đạn được xoay (+-PI/6) radian đến viên đạn đầu tiên.
      if (_shootMultipleBullets) {
        for (int i = -1; i < 2; i += 2) {
          Bullet bullet = Bullet(
            sprite: gameRef.spriteSheet.getSpriteById(28),
            size: Vector2(64, 64),
            position: this.position.clone(),
            level: _spaceship.level,
          );

          // Anchor it to center and add to game world.
          bullet.anchor = Anchor.center;
          bullet.direction.rotate(i * pi / 6);
          gameRef.add(bullet);
        }
      }
    }
  }

  // Cần điều khiển xử lý di chuyển
  @override
  void joystickChangeDirectional(JoystickDirectionalEvent event) {
    switch (event.directional) {
      case JoystickMoveDirectional.moveUp:
        this.setMoveDirection(Vector2(0, -1));
        break;
      case JoystickMoveDirectional.moveUpLeft:
        this.setMoveDirection(Vector2(-1, -1));
        break;
      case JoystickMoveDirectional.moveUpRight:
        this.setMoveDirection(Vector2(1, -1));
        break;
      case JoystickMoveDirectional.moveRight:
        this.setMoveDirection(Vector2(1, 0));
        break;
      case JoystickMoveDirectional.moveDown:
        this.setMoveDirection(Vector2(0, 1));
        break;
      case JoystickMoveDirectional.moveDownRight:
        this.setMoveDirection(Vector2(1, 1));
        break;
      case JoystickMoveDirectional.moveDownLeft:
        this.setMoveDirection(Vector2(-1, 1));
        break;
      case JoystickMoveDirectional.moveLeft:
        this.setMoveDirection(Vector2(-1, 0));
        break;
      case JoystickMoveDirectional.idle:
        this.setMoveDirection(Vector2.zero());
        break;
    }
  }

  // Cộng điểm và tiền của người chơi
  //  và cũng có thể thêm nó vào [PlayerData.money].
  void addToScore(int points) {
    _playerData.currentScore += points;
    _playerData.money += points;

    // Lưu dữ liệu người chơi vào bộ nhớ
    _playerData.save();
  }

  // Tăng máu
  void increaseHealthBy(int points) {
    _health += points;
    // Clamps health to 100.
    if (_health > 100) {
      _health = 100;
    }
  }

  // Đặt lại điểm số, sức khỏe và vị trí của người chơi.
  // Được gọi khi khởi động lại và thoát trò chơi.
  void reset() {
    _playerData.currentScore = 0;
    this._health = 100;
    this.position = gameRef.viewport.canvasSize / 2;
  }

  // Thay đổi kiểu tàu vũ trụ hiện tại với kiểu tàu vũ trụ đã cho.
  // Phương thức này cũng xử lý việc cập nhật các chi tiết bên trong tàu vũ trụ
  // cũng như sprite của tàu vũ trụ.
  void setSpaceshipType(SpaceshipType spaceshipType) {
    this.spaceshipType = spaceshipType;
    this._spaceship = Spaceship.getSpaceshipByType(spaceshipType);
    sprite = gameRef.spriteSheet.getSpriteById(_spaceship.spriteId);
  }

  // Cho phép người chơi bắn nhiều viên đạn trong 4 giây khi hàm được gọi.
  void shootMultipleBullets() {
    _shootMultipleBullets = true;
    _powerUpTimer.stop();
    _powerUpTimer.start();
  }
}
