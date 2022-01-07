import 'package:flame/components.dart';

// Thêm mixin này vào bất kỳ lớp nào bắt nguồn từ BaseComponent sẽ cho phép
// các thành phần đó có quyền truy cập vào gameSize hiện tại.
mixin KnowsGameSize on BaseComponent {
  late Vector2 gameSize;

  void onResize(Vector2 newGameSize) {
    gameSize = newGameSize;
  }
}
