import 'package:flame/components.dart';
import 'package:flame/geometry.dart';

import 'enemy.dart';

// Component này phụ trách viên đạn trong game
class Bullet extends SpriteComponent with Hitbox, Collidable {
  // Tốc độ của đạn
  double _speed = 450;

  // Hướng mà viên đạn di chuyển
  // Mặc định là từ dưới lên trên
  Vector2 direction = Vector2(0, -1);

  // Sức công phá của đạn
  // Nó đại diện cho tàu vũ trụ đã bắn ra viên đạn
  final int level;

  Bullet({
    required Sprite? sprite,
    required Vector2? position,
    required Vector2? size,
    required this.level,
  }) : super(sprite: sprite, position: position, size: size);

  @override
  void onMount() {
    super.onMount();

    // Thêm một HitboxCircle với bán kính là 0,4 là
    // kích thước nhỏ nhất của component này
    final shape = HitboxCircle(definition: 0.4);
    addShape(shape);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, Collidable other) {
    super.onCollision(intersectionPoints, other);

    // Nếu other Collidable là kẻ thù -> loại bỏ viên đạn này
    if (other is Enemy) {
      this.remove();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Di chuyển viên đạn đến vị trí mới với tốc độ và hướng đã định nghĩa.
    this.position += direction * this._speed * dt;

    // Nếu viên đạn đi qua ranh giới trên của màn hình -> xóa bỏ nó
    if (this.position.y < 0) {
      remove();
    }
  }
}
