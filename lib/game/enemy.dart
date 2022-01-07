import 'dart:math';

import 'package:flame/geometry.dart';
import 'package:flame/particles.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import 'game.dart';
import 'bullet.dart';
import 'player.dart';
import 'command.dart';
import 'knows_game_size.dart';
import 'audio_player_component.dart';

import '../models/enemy_data.dart';

// Lớp này đại diện cho một kẻ thù component.
class Enemy extends SpriteComponent
    with KnowsGameSize, Hitbox, Collidable, HasGameRef<SpacescapeGame> {
  // Tốc độ của kẻ thù.
  double _speed = 250;

  // Hướng mà Kẻ thù này sẽ di chuyển.
  // Mặc định theo từ trên xuống dưới.
  Vector2 moveDirection = Vector2(0, 1);

  // Thời gian kẻ thù bị đóng băng
  late Timer _freezeTimer;

  // Tạo số ngẫu nhiên.
  Random _random = Random();

  // Dữ liệu của kẻ thù
  final EnemyData enemyData;

  // Máu của kẻ thù này
  int _hitPoints = 10;

  // Hiển thị máu của kẻ thù
  TextComponent _hpText = TextComponent(
    '10 HP',
    textRenderer: TextPaint(
      config: TextPaintConfig(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'BungeeInline',
      ),
    ),
  );

  // Hàm tạo ra một vectơ ngẫu nhiên với góc của nó
  // từ 0 đến 360 độ.
  Vector2 getRandomVector() {
    return (Vector2.random(_random) - Vector2.random(_random)) * 500;
  }

  // Trả về một vectơ hướng ngẫu nhiên
  // Dùng cho đối tượng có hướng di chuyển ngẫu nhiên
  Vector2 getRandomDirection() {
    return (Vector2.random(_random) - Vector2(0.5, -1)).normalized();
  }

  Enemy({
    required Sprite? sprite,
    required this.enemyData,
    required Vector2? position,
    required Vector2? size,
  }) : super(sprite: sprite, position: position, size: size) {
    // Rotates the enemy component by 180 degrees. This is needed because
    // all the sprites initially face the same direct, but we want enemies to be
    // moving in opposite direction.
    // Xoay thành phần đối phương 180 độ.
    // Vì tất cả các đối tượng ban đầu có cùng hướng nhìn,
    // nhưng kẻ thù chuyển động ngược chiều -> xoay để đối mặt trực tiếp với nhau.
    angle = pi;

    // Đặt tốc độ từ dữ liệu của Địch.
    _speed = enemyData.speed;

    // Set hitpoint to correct value from enemyData.
    // Sửa hitpoint theo giá trị level từ dữ liệu của địch
    _hitPoints = enemyData.level * 10;
    _hpText.text = '$_hitPoints HP';

    // Đặt thời gian đóng băng thành 2 giây. Sau 2 giây tốc độ sẽ được thiết lập lại.
    _freezeTimer = Timer(2, callback: () {
      _speed = enemyData.speed;
    });

    // Nếu kẻ thù này có thể di chuyển theo chiều ngang,
    // -> Ngẫu nhiên hóa hướng di chuyển.
    if (enemyData.hMove) {
      moveDirection = getRandomDirection();
    }
  }

  @override
  void onMount() {
    super.onMount();

    // Thêm một HitboxCircle với bán kính là 0,8
    // kích thước nhỏ nhất của component này.
    final shape = HitboxCircle(definition: 0.8);
    addShape(shape);

    // Vì component hiện tại đã được xoay bởi pi radian,
    // nên văn bản cần được xoay lại bằng pi radian
    // để nó được hiển thị chính xác.
    _hpText.angle = pi;

    // Đặt văn bản phía sau kẻ thù
    _hpText.position = Vector2(50, 80);

    // Thêm text vào con của component hiện tại
    addChild(_hpText);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, Collidable other) {
    super.onCollision(intersectionPoints, other);

    if (other is Bullet) {
      // Nếu other là một viên đạn,
      // giảm máu theo cấp của viên đạn 10 lần.
      _hitPoints -= other.level * 10;
    } else if (other is Player) {
      // Nếu other là Người chơi,
      // giảm máu xuống 0
      _hitPoints = 0;
    }
  }

  // Xóa/tiêu diệt đối tượng kẻ thù này
  void destroy() {
    // Phát hiệu ứng tiêu diệt kẻ thù.
    gameRef.addCommand(Command<AudioPlayerComponent>(action: (audioPlayer) {
      audioPlayer.playSfx('laser1.ogg');
    }));

    this.remove();

    // Trước khi chết, đăng ký một lệnh để tăng điểm của người chơi lên 1.
    final command = Command<Player>(action: (player) {
      // Sử dụng thuộc tính killPoint của kẻ thù để tăng điểm của người chơi.
      player.addToScore(enemyData.killPoint);
    });
    gameRef.addCommand(command);

    // Tạo hiệu ứng va chạm
    // Tạo ra 20 hạt hình tròn màu trắng với tốc độ và gia tốc ngẫu nhiên,
    // tại vị trí hiện tại của kẻ thù này.
    // Mỗi hạt tổn tại 0,1 giây và sẽ bị xóa sau đó.
    final particleComponent = ParticleComponent(
      particle: Particle.generate(
        count: 20,
        lifespan: 0.1,
        generator: (i) => AcceleratedParticle(
          acceleration: getRandomVector(),
          speed: getRandomVector(),
          position: this.position.clone(),
          child: CircleParticle(
            radius: 2,
            paint: Paint()..color = Colors.white,
          ),
        ),
      ),
    );

    gameRef.add(particleComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Đồng bộ hóa text và giá trị của hitPoints.
    _hpText.text = '$_hitPoints HP';

    // Nếu hitPoints đã giảm xuống 0 -> kẻ thù này đã bị tiêu diệt
    // -> xóa khỏi màn
    if (_hitPoints <= 0) {
      destroy();
    }

    _freezeTimer.update(dt);

    // Cập nhật vị trí của kẻ thù
    this.position += moveDirection * _speed * dt;

    // Nếu kẻ thù rời khỏi màn hình -> xóa.
    if (this.position.y > this.gameSize.y) {
      remove();
    } else if ((this.position.x < this.size.x / 2) ||
        (this.position.x > (this.gameSize.x - size.x / 2))) {
      // Kẻ thù đang đi ra ngoài giới hạn màn hình dọc, cho chạy ngược lại theo hướng x
      moveDirection.x *= -1;
    }
  }

  // Tạm dừng đối phương trong 2 giây khi hàm đóng băng được gọi
  void freeze() {
    _speed = 0;
    _freezeTimer.stop();
    _freezeTimer.start();
  }
}
