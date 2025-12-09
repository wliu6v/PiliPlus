import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/later_view_type.dart';
import 'package:PiliPlus/models/common/video/source_type.dart';
import 'package:PiliPlus/models_new/later/list.dart';
import 'package:PiliPlus/pages/later/base_controller.dart';
import 'package:PiliPlus/pages/later/controller.dart';
import 'package:PiliPlus/pages/later/widgets/video_card_h_later.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LaterViewChildPage extends StatefulWidget {
  const LaterViewChildPage({
    super.key,
    required this.laterViewType,
  });

  final LaterViewType laterViewType;

  @override
  State<LaterViewChildPage> createState() => _LaterViewChildPageState();
}

class _LaterViewChildPageState extends State<LaterViewChildPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  late final LaterController _laterController;
  late final _baseCtr = Get.putOrFind(LaterBaseController.new);

  @override
  void initState() {
    super.initState();
    _laterController = Get.put(
      LaterController(widget.laterViewType),
      tag: widget.laterViewType.type.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        refreshIndicator(
          onRefresh: _laterController.onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _laterController.scrollController,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  top: 7,
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 85,
                ),
                sliver: Obx(
                  () => _buildBody(_laterController.loadingState.value),
                ),
              ),
            ],
          ),
        ),
        // 撤销按钮
        Obx(
          () => _baseCtr.showUndo.value
              ? Positioned(
                  right: 16,
                  bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(24),
                    color: Theme.of(context).colorScheme.surface,
                    child: InkWell(
                      onTap: () async {
                        if (_baseCtr.deletedItem != null &&
                            _baseCtr.deletedIndex != null) {
                          await _laterController.undoDelete(
                            _baseCtr.deletedItem!,
                            _baseCtr.deletedIndex!,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.undo,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '撤销',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBody(LoadingState<List<LaterItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _laterController.onLoadMore();
                  }
                  final videoItem = response[index];
                  return Dismissible(
                    key: ValueKey('${videoItem.aid}_$index'),
                    direction: DismissDirection.startToEnd,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    onDismissed: (direction) {
                      _laterController.toViewDel(
                        context,
                        index,
                        videoItem.aid,
                      );
                    },
                    child: VideoCardHLater(
                      index: index,
                      videoItem: videoItem,
                      ctr: _laterController,
                      onViewLater: (cid) {
                        PageUtils.toVideoPage(
                          bvid: videoItem.bvid,
                          cid: cid,
                          cover: videoItem.pic,
                          title: videoItem.title,
                          dimension: videoItem.dimension,
                          extraArguments: _baseCtr.isPlayAll.value
                              ? {
                                  'oid': videoItem.aid,
                                  'sourceType': SourceType.watchLater,
                                  'count': _laterController.baseCtr
                                      .counts[LaterViewType.all.index],
                                  'favTitle': '稍后再看',
                                  'mediaId': _laterController.mid,
                                  'desc': _laterController.asc.value,
                                  'isContinuePlaying': index != 0,
                                }
                              : null,
                        );
                      },
                    ),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _laterController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _laterController.onReload,
      ),
    };
  }

  @override
  bool get wantKeepAlive => true;
}
