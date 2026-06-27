import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Số dòng mỗi lần tải — đồng bộ với web.
const kDefaultPageSize = 20;

const kScrollLoadThreshold = 160.0;

/// Cuộn đã gần cuối danh sách (hoặc danh sách ngắn hơn viewport).
bool scrollNearBottom(ScrollMetrics metrics,
    [double threshold = kScrollLoadThreshold]) {
  if (metrics.maxScrollExtent <= threshold) return true;
  return metrics.pixels >= metrics.maxScrollExtent - threshold;
}

/// Chặn gọi [loadMore] trùng lặp khi cuộn.
class LoadMoreGate {
  bool _busy = false;

  Future<void> run(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }
}

/// Footer: spinner khi đang tải, hint cuộn, hoặc "đã hiển thị hết".
class LoadMoreFooter extends StatelessWidget {
  final bool hasMore;
  final bool loading;
  final int visible;
  final int total;

  const LoadMoreFooter({
    super.key,
    required this.hasMore,
    required this.loading,
    required this.visible,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Cuộn để xem thêm ($visible/$total)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
      );
    }
    if (total > kDefaultPageSize) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Đã hiển thị tất cả $total mục',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}

/// Danh sách đã có sẵn trong RAM — tăng dần số dòng render khi cuộn.
class ClientVisibleList {
  int visibleCount = kDefaultPageSize;

  void reset() => visibleCount = kDefaultPageSize;

  List<E> slice<E>(List<E> items) {
    if (items.length <= visibleCount) return items;
    return items.sublist(0, visibleCount);
  }

  bool hasMore<E>(List<E> items) => visibleCount < items.length;

  void loadMore<E>(List<E> items) {
    visibleCount =
        (visibleCount + kDefaultPageSize).clamp(0, items.length);
  }
}

/// Nếu nội dung chưa đủ cao để cuộn mà vẫn còn dữ liệu — tự tải thêm.
void ensureScrollFill({
  required ScrollController controller,
  required bool hasMore,
  required VoidCallback onLoadMore,
}) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (!controller.hasClients || !hasMore) return;
    if (controller.position.maxScrollExtent <= kScrollLoadThreshold) {
      onLoadMore();
    }
  });
}

/// Gắn listener cuộn → [onLoadMore] khi gần cuối.
void bindScrollLoadMore(
  ScrollController controller, {
  required bool Function() hasMore,
  required VoidCallback onLoadMore,
  LoadMoreGate? gate,
}) {
  controller.addListener(() {
    if (!controller.hasClients || !hasMore()) return;
    if (!scrollNearBottom(controller.position)) return;
    if (gate != null) {
      gate.run(() async => onLoadMore());
    } else {
      onLoadMore();
    }
  });
}
