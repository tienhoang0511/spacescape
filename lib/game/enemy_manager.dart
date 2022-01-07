import 'dart:math';

import 'package:flame/sprite.dart';
import 'package:flame/components.dart';
import 'package:provider/provider.dart';

import 'game.dart';
import 'enemy.dart';
import 'knows_game_size.dart';

import '../models/enemy_data.dart';
import '../models/player_data.dart';

// Lớp component này đảm nhiệm việc sinh ra các component mới của kẻ thù
// một cách ngẫu nhiên từ phía trên màn hình.
// Nó sử dụng hỗn hợp HasGameRef để nó có thể thêm các component con.
class EnemyManager extends BaseComponent
    with KnowsGameSize, HasGameRef<SpacescapeGame> {
  // Timer khởi tạo của đối phương trong khoảng 1 thời gian được định nghĩa trước
  late Timer _timer;

  // Kiểm soát thời gian EnemyManager ngừng tạo kẻ thù mới.
  late Timer _freezeTimer;

  // Biến tham chiếu đến spriteSheet, nó chứa các sprite của kẻ thù
  SpriteSheet spriteSheet;

  // Tạo giá trị ngẫu nhiên
  Random random = Random();

  EnemyManager({required this.spriteSheet}) : super() {
    // Đặt bộ đếm thời gian để gọi _spawnEnemy() sau mỗi 1 giây,
    // cho đến khi bộ đếm thời gian dừng lại
    _timer = Timer(1, callback: _spawnEnemy, repeat: true);

    // Đặt thời gian đóng băng thành 2 giây.
    // Sau 2 giây, bộ đếm thời gian tạo đối tượng sẽ bắt đầu lại.
    _freezeTimer = Timer(2, callback: () {
      _timer.start();
    });
  }

  // Sinh ra kẻ thù mới ở vị trí ngẫu nhiên phía trên màn hình.
  void _spawnEnemy() {
    Vector2 initialSize = Vector2(64, 64);

    // random.nextDouble() tạo ra một số ngẫu nhiên từ 0 đến 1.
    // Nhân nó với gameSize.x để đảm bảo rằng giá trị vẫn nằm trong khoảng
    // từ 0 đến chiều rộng của màn hình.
    Vector2 position = Vector2(random.nextDouble() * gameSize.x, 0);

    // Kích hoạt vector sao cho hình ảnh kẻ thù vẫn còn trong màn hình.
    position.clamp(
      Vector2.zero() + initialSize / 2,
      gameSize - initialSize / 2,
    );

    if (gameRef.buildContext != null) {
      // Nhận điểm hiện tại và tìm ra cấp độ tối đa của kẻ thù
      // có thể được sinh ra cho điểm số đó.
      int currentScore =
          Provider.of<PlayerData>(gameRef.buildContext!, listen: false)
              .currentScore;
      int maxLevel = mapScoreToMaxEnemyLevel(currentScore);

      /// Lấy ra một đối tượng dữ liệu kẻ thù [EnemyData] ngẫu nhiên từ danh sách.
      final enemyData = _enemyDataList.elementAt(random.nextInt(maxLevel * 4));

      Enemy enemy = Enemy(
        sprite: spriteSheet.getSpriteById(enemyData.spriteId),
        size: initialSize,
        position: position,
        enemyData: enemyData,
      );

      // set sprite của kẻ thù được căn giữa.
      enemy.anchor = Anchor.center;

      // Thêm kẻ thù vào danh sách components của phiên trò chơi
      gameRef.add(enemy);
    }
  }

  // Đối với điểm người chơi hiện có, hàm này trả về level tối đa
  // của kẻ thù sẽ được tạo ra trong các lần tiếp theo
  int mapScoreToMaxEnemyLevel(int score) {
    int level = 1;

    if (score > 1500) {
      level = 4;
    } else if (score > 500) {
      level = 3;
    } else if (score > 100) {
      level = 2;
    }

    return level;
  }

  @override
  void onMount() {
    super.onMount();
    // Bắt đầu đếm giờ ngay khi quản lý kẻ thù chuẩn bị
    // được thêm vào phiên trò chơi.
    _timer.start();
  }

  @override
  void onRemove() {
    super.onRemove();
    // Dừng bộ đếm thời gian nếu lớp quản lý kẻ thù hiện tại bị xóa khỏi
    // phiên trò chơi.
    _timer.stop();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Cập nhật các bộ hẹn giờ với thời gian là delta
    _timer.update(dt);
    _freezeTimer.update(dt);
  }

  // Dừng và khởi động lại timer tạo kẻ thù. Hàm này sẽ được gọi
  // khi khởi động lại và thoát trò chơi.
  void reset() {
    _timer.stop();
    _timer.start();
  }

  // Hàm này xử lý đóng băng
  // Dừng timer tạo ra các kẻ thù
  // Bắt đầu timer đóng băng
  void freeze() {
    _timer.stop();
    _freezeTimer.stop();
    _freezeTimer.start();
  }

  /// Danh sách dữ liệu của kẻ thù
  /// Hiện tại kịch bản gồm 15 đối tượng kẻ thù
  static const List<EnemyData> _enemyDataList = [
    EnemyData(
      killPoint: 1,
      speed: 200,
      spriteId: 8,
      level: 1,
      hMove: false,
    ),
    EnemyData(
      killPoint: 2,
      speed: 200,
      spriteId: 9,
      level: 1,
      hMove: false,
    ),
    EnemyData(
      killPoint: 4,
      speed: 200,
      spriteId: 10,
      level: 1,
      hMove: false,
    ),
    EnemyData(
      killPoint: 4,
      speed: 200,
      spriteId: 11,
      level: 1,
      hMove: false,
    ),
    EnemyData(
      killPoint: 6,
      speed: 250,
      spriteId: 12,
      level: 2,
      hMove: false,
    ),
    EnemyData(
      killPoint: 6,
      speed: 250,
      spriteId: 13,
      level: 2,
      hMove: false,
    ),
    EnemyData(
      killPoint: 6,
      speed: 250,
      spriteId: 14,
      level: 2,
      hMove: false,
    ),
    EnemyData(
      killPoint: 6,
      speed: 250,
      spriteId: 15,
      level: 2,
      hMove: true,
    ),
    EnemyData(
      killPoint: 10,
      speed: 350,
      spriteId: 16,
      level: 3,
      hMove: false,
    ),
    EnemyData(
      killPoint: 10,
      speed: 350,
      spriteId: 17,
      level: 3,
      hMove: false,
    ),
    EnemyData(
      killPoint: 10,
      speed: 400,
      spriteId: 18,
      level: 3,
      hMove: true,
    ),
    EnemyData(
      killPoint: 10,
      speed: 400,
      spriteId: 19,
      level: 3,
      hMove: false,
    ),
    EnemyData(
      killPoint: 10,
      speed: 400,
      spriteId: 20,
      level: 4,
      hMove: false,
    ),
    EnemyData(
      killPoint: 50,
      speed: 250,
      spriteId: 21,
      level: 4,
      hMove: true,
    ),
    EnemyData(
      killPoint: 50,
      speed: 250,
      spriteId: 22,
      level: 4,
      hMove: false,
    ),
    EnemyData(
      killPoint: 50,
      speed: 250,
      spriteId: 23,
      level: 4,
      hMove: false,
    )
  ];
}
