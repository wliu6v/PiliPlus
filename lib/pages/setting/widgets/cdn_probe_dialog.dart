import 'dart:async';

import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/models/common/video/cdn_type.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/utils/video_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

/// 用户在测速对话框中选中的 CDN 及其对应可用的链接
typedef CdnProbePick = ({CDNService cdn, String url});

/// 单个 CDN 的探测结果
class CdnProbeResult {
  /// null 表示测试中，true/false 表示是否可解析
  bool? success;
  int? latencyMs;
  int? statusCode;
  String? message;
  String? url;
}

/// 通用 CDN 解析测试对话框：
/// 给定一个音频/视频流（[itemLoader]），逐一探测各 CDN 能否解析，
/// 并记录解析延迟，方便用户挑选可用且较快的 CDN。
class CdnProbeDialog extends StatefulWidget {
  /// 待测试的流加载器（可能涉及网络请求，如根据 BV 号解析）
  final FutureOr<BaseItem> Function() itemLoader;

  /// 当前测试的是否为音频流（仅用于文案展示）
  final bool isAudio;

  /// 当前选中的 CDN，用于高亮
  final CDNService? current;

  final String title;

  const CdnProbeDialog({
    super.key,
    required this.itemLoader,
    this.isAudio = false,
    this.current,
    this.title = 'CDN 解析测试',
  });

  @override
  State<CdnProbeDialog> createState() => _CdnProbeDialogState();
}

class _CdnProbeDialogState extends State<CdnProbeDialog> {
  static const _services = CDNService.values;

  late final Dio _dio;
  late final List<ValueNotifier<CdnProbeResult>> _results;
  late final List<CancelToken?> _tokens;

  BaseItem? _item;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _dio =
        Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          )
          ..options.headers = {
            'user-agent': BrowserUa.pc,
            'referer': HttpString.baseUrl,
          };
    final length = _services.length;
    _results = List.generate(length, (_) => ValueNotifier(CdnProbeResult()));
    _tokens = List.generate(length, (_) => CancelToken());
    _start();
  }

  @override
  void dispose() {
    for (final e in _tokens) {
      e?.cancel();
    }
    for (final e in _results) {
      e.dispose();
    }
    _dio.close(force: true);
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final item = await widget.itemLoader();
      if (!mounted) return;
      setState(() {
        _item = item;
        _loading = false;
      });
      await _probeAll(item);
    } catch (e) {
      if (kDebugMode) debugPrint('CDN probe load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  void _retry() {
    for (int i = 0; i < _tokens.length; i++) {
      _tokens[i]?.cancel();
      _tokens[i] = CancelToken();
      _results[i].value = CdnProbeResult();
    }
    final item = _item;
    if (item != null) {
      _probeAll(item);
    } else {
      setState(() {
        _loading = true;
        _loadError = null;
      });
      _start();
    }
  }

  Future<void> _probeAll(BaseItem item) async {
    await Future.wait([
      for (final cdn in _services) _probe(cdn, item),
    ]);
  }

  Future<void> _probe(CDNService cdn, BaseItem item) async {
    final notifier = _results[cdn.index];
    final result = CdnProbeResult();

    String url;
    try {
      // isAudio 传 false：强制按所选 CDN 替换 host，避免「音频不跟随 CDN」开关干扰探测
      url = VideoUtils.getCdnUrl(
        item.playUrls,
        defaultCDNService: cdn,
        isAudio: false,
      );
    } catch (e) {
      result
        ..success = false
        ..message = '构建链接失败';
      notifier.value = result;
      return;
    }
    result.url = url;

    final token = _tokens[cdn.index];
    final sw = Stopwatch()..start();
    try {
      final resp = await _dio.get<List<int>>(
        url,
        cancelToken: token,
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {'range': 'bytes=0-1'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      sw.stop();
      final code = resp.statusCode ?? 0;
      result
        ..statusCode = code
        ..latencyMs = sw.elapsedMilliseconds;
      // 200/206 正常，416 表示 host 已响应（仅 Range 越界），同样视为可解析
      if (code == 200 || code == 206 || code == 416) {
        result.success = true;
      } else {
        result
          ..success = false
          ..message = '解析失败（$code）';
      }
    } catch (e) {
      sw.stop();
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      result
        ..success = false
        ..latencyMs = sw.elapsedMilliseconds
        ..message = _errorMessage(e);
      if (kDebugMode) debugPrint('CDN probe error [${cdn.name}]: $e');
    }
    if (mounted) {
      notifier.value = result;
    }
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code != null && code >= 400 && code < 500) {
        return '该视频可能无法替换为此 CDN（$code）';
      }
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => '超时',
        DioExceptionType.connectionError => '连接失败',
        _ => error.message ?? '解析失败',
      };
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      clipBehavior: Clip.hardEdge,
      title: Text(widget.title),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: SizedBox(
        width: 360,
        child: _buildContent(theme),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(
            '关闭',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ),
        if (!_loading && _loadError == null)
          TextButton(
            onPressed: _retry,
            child: const Text('重新测试'),
          ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          '加载失败：$_loadError',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              widget.isAudio
                  ? '正在测试各 CDN 能否解析「音频」流，点击可用项即可应用'
                  : '正在测试各 CDN 能否解析「视频」流，点击可用项即可应用',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          ..._services.map((cdn) => _buildRow(theme, cdn)),
        ],
      ),
    );
  }

  Widget _buildRow(ThemeData theme, CDNService cdn) {
    final notifier = _results[cdn.index];
    final isCurrent = widget.current == cdn;
    return ValueListenableBuilder<CdnProbeResult>(
      valueListenable: notifier,
      builder: (context, result, _) {
        final success = result.success;
        Widget leading;
        if (success == null) {
          leading = const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (success) {
          leading = Icon(
            Icons.check_circle,
            size: 20,
            color: theme.colorScheme.primary,
          );
        } else {
          leading = Icon(
            Icons.cancel_outlined,
            size: 20,
            color: theme.colorScheme.error,
          );
        }

        String subtitle;
        if (success == null) {
          subtitle = '测试中…';
        } else if (success) {
          subtitle = '可解析 · ${result.latencyMs}ms'
              '${result.statusCode != null ? ' · ${result.statusCode}' : ''}';
        } else {
          subtitle = result.message ?? '解析失败';
        }

        return ListTile(
          dense: true,
          enabled: success == true,
          leading: leading,
          title: Text(
            cdn.desc,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCurrent ? FontWeight.bold : null,
              color: isCurrent ? theme.colorScheme.primary : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: success == false
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isCurrent
              ? Text(
                  '当前',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                )
              : null,
          onTap: success == true && result.url != null
              ? () => Navigator.of(context).pop(
                  (cdn: cdn, url: result.url!),
                )
              : null,
        );
      },
    );
  }
}
