import 'package:PiliPlus/models/common/enum_with_label.dart';

enum MineDisplayType implements EnumWithLabel {
  none('不展示'),
  favorite('我的收藏'),
  history('观看记录'),
  download('离线缓存'),
  ;

  @override
  final String label;

  const MineDisplayType(this.label);
}
