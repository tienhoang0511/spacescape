import 'package:flame/components.dart';

// Lớp này đại diện cho một lệnh sẽ được chạy
// trên mọi component của kiểu T được thêm vào phiên trò chơi.
class Command<T extends Component> {

  // Một hàm callback sẽ được chạy trong
  // component có kiểu T.
  void Function(T target) action;

  Command({required this.action});

  // Runs the callback on given component
  // if it is of type T.
  // Chạy hàm callback trong component đã khởi tạo
  // nếu nó thuộc loại T.
  void run(Component c) {
    if (c is T) {
      action.call(c);
    }
  }
}
