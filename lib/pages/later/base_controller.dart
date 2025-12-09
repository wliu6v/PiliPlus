import 'package:PiliPlus/models/common/later_view_type.dart';
import 'package:PiliPlus/models_new/later/list.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'dart:async';

class LaterBaseController extends GetxController {
  RxBool enableMultiSelect = false.obs;
  RxInt checkedCount = 0.obs;

  RxList<int> counts = List.filled(LaterViewType.values.length, -1).obs;

  late double dx = 0;
  late final RxBool isPlayAll = Pref.enablePlayAll.obs;
  
  // 当前激活的 tab 索引
  RxInt currentTabIndex = 0.obs;

  // 撤销相关
  RxBool showUndo = false.obs;
  LaterItemModel? deletedItem;
  int? deletedIndex;
  Timer? undoTimer;
  bool isDeleteRequestCompleted = false; // 删除请求是否已完成

  void setIsPlayAll(bool isPlayAll) {
    if (this.isPlayAll.value == isPlayAll) return;
    this.isPlayAll.value = isPlayAll;
    GStorage.setting.put(SettingBoxKey.enablePlayAll, isPlayAll);
  }

  void showUndoButton(LaterItemModel item, int index) {
    // 取消之前的定时器
    undoTimer?.cancel();
    
    deletedItem = item;
    deletedIndex = index;
    isDeleteRequestCompleted = false;
    showUndo.value = true;
    
    // 5秒后自动隐藏
    undoTimer = Timer(const Duration(seconds: 5), () {
      showUndo.value = false;
      deletedItem = null;
      deletedIndex = null;
      isDeleteRequestCompleted = false;
    });
  }

  void hideUndoButton() {
    undoTimer?.cancel();
    showUndo.value = false;
    deletedItem = null;
    deletedIndex = null;
    isDeleteRequestCompleted = false;
  }

  void markDeleteRequestCompleted() {
    isDeleteRequestCompleted = true;
  }

  @override
  void onClose() {
    undoTimer?.cancel();
    super.onClose();
  }
}
