import 'package:flame/components.dart';

/// Component dữ liệu gắn vào mỗi đám mây để lưu tốc độ parallax riêng.
class CloudData extends Component {
  final double speedMultiplier;
  CloudData({required this.speedMultiplier});
}
