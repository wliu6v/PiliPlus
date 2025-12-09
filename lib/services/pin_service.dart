import 'dart:convert';
import 'package:PiliPlus/utils/storage.dart';
import 'package:get/get.dart';

/// Pin 项目类型
enum PinType {
  video, // 视频
  article, // 专栏
}

/// Pin 状态变化通知
class PinNotifier {
  static final RxBool _pinChanged = false.obs;
  
  /// 监听 Pin 状态变化
  static RxBool get pinChanged => _pinChanged;
  
  /// 通知 Pin 状态已变化
  static void notifyChanged() {
    _pinChanged.value = !_pinChanged.value;
  }
}

/// Pin 数据模型
class PinItem {
  final PinType type;
  final String id; // bvid 或 cv id
  final String? aid; // 视频的 aid（可选）
  final String title;
  final String cover;
  final String? author; // 作者名称（可选）
  final int? authorMid; // 作者 mid（可选）

  PinItem({
    required this.type,
    required this.id,
    this.aid,
    required this.title,
    required this.cover,
    this.author,
    this.authorMid,
  });

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'id': id,
        'aid': aid,
        'title': title,
        'cover': cover,
        'author': author,
        'authorMid': authorMid,
      };

  factory PinItem.fromJson(Map<String, dynamic> json) => PinItem(
        type: PinType.values[json['type'] as int],
        id: json['id'] as String,
        aid: json['aid'] as String?,
        title: json['title'] as String,
        cover: json['cover'] as String,
        author: json['author'] as String?,
        authorMid: json['authorMid'] as int?,
      );
}

/// Pin 服务
class PinService {
  static const String _key = 'pinnedItem';

  /// 获取当前 Pin 的项目
  static PinItem? getPinnedItem() {
    try {
      final data = GStorage.localCache.get(_key);
      if (data == null) return null;
      if (data is String) {
        // 兼容旧格式（JSON 字符串）
        return PinItem.fromJson(jsonDecode(data));
      } else if (data is Map) {
        // 新格式（直接 Map）
        return PinItem.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 设置 Pin 项目（新的会顶掉旧的）
  static Future<void> setPinnedItem(PinItem item) async {
    await GStorage.localCache.put(_key, item.toJson());
    PinNotifier.notifyChanged();
  }

  /// 取消 Pin
  static Future<void> unpin() async {
    await GStorage.localCache.delete(_key);
    PinNotifier.notifyChanged();
  }

  /// 检查是否有 Pin 的项目
  static bool hasPinnedItem() {
    return GStorage.localCache.get(_key) != null;
  }
}

