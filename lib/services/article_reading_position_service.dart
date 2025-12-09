import 'dart:convert';
import 'package:PiliPlus/utils/storage.dart';

/// 专栏阅读位置服务
class ArticleReadingPositionService {
  static const String _key = 'articleReadingPositions';
  static const int _maxArticles = 50;

  /// 获取专栏的阅读位置
  static double? getReadingPosition(String articleId) {
    try {
      final data = GStorage.localCache.get(_key);
      if (data == null) return null;
      
      Map<String, dynamic> positions;
      if (data is String) {
        positions = Map<String, dynamic>.from(jsonDecode(data));
      } else {
        positions = Map<String, dynamic>.from(data);
      }
      
      final position = positions[articleId];
      if (position is num) {
        return position.toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 保存专栏的阅读位置
  static Future<void> saveReadingPosition(String articleId, double position) async {
    try {
      final data = GStorage.localCache.get(_key);
      Map<String, dynamic> positions;
      
      if (data == null) {
        positions = {};
      } else if (data is String) {
        positions = Map<String, dynamic>.from(jsonDecode(data));
      } else {
        positions = Map<String, dynamic>.from(data);
      }
      
      // 更新或添加位置
      positions[articleId] = position;
      
      // 如果超过最大数量，移除最旧的（按插入顺序，这里简化处理，移除第一个）
      if (positions.length > _maxArticles) {
        final keys = positions.keys.toList();
        // 移除最旧的（第一个）
        positions.remove(keys.first);
      }
      
      await GStorage.localCache.put(_key, positions);
    } catch (e) {
      // 忽略错误
    }
  }

  /// 清除专栏的阅读位置
  static Future<void> clearReadingPosition(String articleId) async {
    try {
      final data = GStorage.localCache.get(_key);
      if (data == null) return;
      
      Map<String, dynamic> positions;
      if (data is String) {
        positions = Map<String, dynamic>.from(jsonDecode(data));
      } else {
        positions = Map<String, dynamic>.from(data);
      }
      
      positions.remove(articleId);
      await GStorage.localCache.put(_key, positions);
    } catch (e) {
      // 忽略错误
    }
  }

  /// 获取所有保存的阅读位置数量
  static int getSavedCount() {
    try {
      final data = GStorage.localCache.get(_key);
      if (data == null) return 0;
      
      Map<String, dynamic> positions;
      if (data is String) {
        positions = Map<String, dynamic>.from(jsonDecode(data));
      } else {
        positions = Map<String, dynamic>.from(data);
      }
      
      return positions.length;
    } catch (e) {
      return 0;
    }
  }
}

