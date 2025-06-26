import 'package:PiliPlus/models/common/enum_with_label.dart';
import 'package:PiliPlus/pages/dynamics/view.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/later/view.dart';
import 'package:PiliPlus/pages/media/view.dart';
import 'package:flutter/material.dart';

enum NavigationBarType implements EnumWithLabel {
  home,
  dynamics,
  media,
  later;

  @override
  String get label {
    return switch (this) {
      NavigationBarType.home => '首页',
      NavigationBarType.dynamics => '动态',
      NavigationBarType.media => '媒体库',
      NavigationBarType.later => '稍后再看',
    };
  }

  Icon get icon {
    return switch (this) {
      NavigationBarType.home => const Icon(Icons.home_outlined, size: 23),
      NavigationBarType.dynamics =>
        const Icon(Icons.motion_photos_on_outlined, size: 21),
      NavigationBarType.media =>
        const Icon(Icons.video_collection_outlined, size: 21),
      NavigationBarType.later =>
        const Icon(Icons.watch_later_outlined, size: 21),
    };
  }

  Icon get selectIcon {
    return switch (this) {
      NavigationBarType.home => const Icon(Icons.home, size: 21),
      NavigationBarType.dynamics =>
        const Icon(Icons.motion_photos_on, size: 21),
      NavigationBarType.media => const Icon(Icons.video_collection, size: 21),
      NavigationBarType.later => const Icon(Icons.watch_later, size: 21),
    };
  }

  Widget get page {
    return switch (this) {
      NavigationBarType.home => const HomePage(),
      NavigationBarType.dynamics => const DynamicsPage(),
      NavigationBarType.media => const MediaPage(),
      NavigationBarType.later => const LaterPage(),
    };
  }
}
