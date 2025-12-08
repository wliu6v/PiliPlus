import 'package:PiliPlus/models/common/later_view_type.dart';
import 'package:PiliPlus/pages/common/common_controller.dart';
import 'package:PiliPlus/pages/later/base_controller.dart';
import 'package:PiliPlus/pages/later/controller.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LaterPageController extends GetxController with ScrollOrRefreshMixin {
  final LaterBaseController baseCtr = Get.putOrFind(LaterBaseController.new);

  @override
  ScrollController get scrollController {
    // 获取当前激活的 LaterController 的 scrollController
    final currentType = _getCurrentType();
    try {
      final laterCtr = Get.find<LaterController>(
        tag: currentType.type.toString(),
      );
      return laterCtr.scrollController;
    } catch (_) {
      // 如果找不到，创建并返回第一个类型的 controller
      final laterCtr = Get.put(
        LaterController(currentType),
        tag: currentType.type.toString(),
      );
      return laterCtr.scrollController;
    }
  }

  LaterViewType _getCurrentType() {
    final index = baseCtr.currentTabIndex.value;
    if (index >= 0 && index < LaterViewType.values.length) {
      return LaterViewType.values[index];
    }
    return LaterViewType.values.first;
  }

  LaterController? _getCurrentController() {
    try {
      final currentType = _getCurrentType();
      return Get.find<LaterController>(
        tag: currentType.type.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> onRefresh() {
    final laterCtr = _getCurrentController();
    if (laterCtr != null) {
      return laterCtr.onRefresh();
    }
    return Future.value();
  }

  @override
  void toTopOrRefresh() {
    final laterCtr = _getCurrentController();
    if (laterCtr != null && laterCtr.scrollController.hasClients) {
      if (laterCtr.scrollController.position.pixels == 0) {
        // 在顶部，刷新
        EasyThrottle.throttle(
          'topOrRefresh',
          const Duration(milliseconds: 500),
          laterCtr.onRefresh,
        );
      } else {
        // 不在顶部，滚动到顶部
        laterCtr.scrollController.animToTop();
      }
    }
  }
}

