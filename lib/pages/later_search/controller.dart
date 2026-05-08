import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models_new/later/data.dart';
import 'package:PiliPlus/models_new/later/list.dart';
import 'package:PiliPlus/pages/common/multi_select/base.dart';
import 'package:PiliPlus/pages/common/search/common_search_controller.dart';
import 'package:PiliPlus/pages/later/base_controller.dart';
import 'package:PiliPlus/pages/later/controller.dart' show BaseLaterController;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LaterSearchController
    extends CommonSearchController<LaterData, LaterItemModel>
    with
        CommonMultiSelectMixin<LaterItemModel>,
        DeleteItemMixin,
        BaseLaterController {
  dynamic mid = Get.arguments['mid'];
  dynamic count = Get.arguments['count'];

  late final LaterBaseController _baseCtr = Get.put(LaterBaseController());

  @override
  LaterBaseController get baseCtr => _baseCtr;

  @override
  Future<LoadingState<LaterData>> customGetData() => UserHttp.seeYouLater(
    page: page,
    keyword: editController.value.text,
  );

  @override
  List<LaterItemModel>? getDataList(LaterData response) {
    return response.list;
  }

  @override
  Future<void> toViewDel(
    BuildContext context,
    int index,
    int? aid,
  ) async {
    // 搜索页面不需要撤销功能，直接删除
    if (loadingState.value.data == null || index >= loadingState.value.data!.length) {
      return;
    }
    
    final res = await UserHttp.toViewDel(aids: aid.toString());
    if (res.isSuccess) {
      loadingState.value.data!.removeAt(index);
      loadingState.refresh();
      updateCount?.call(1);
    } else {
      await res.toast();
    }
  }
}
