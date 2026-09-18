import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient);
});

class UnreadCountNotifier extends StateNotifier<int> {
  final NotificationRepository _repository;
  Timer? _timer;

  UnreadCountNotifier(this._repository) : super(0) {
    fetchUnreadCount();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchUnreadCount();
    });
  }

  Future<void> fetchUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      if (mounted) {
        state = count;
      }
    } catch (_) {}
  }

  void decrement() {
    if (state > 0) {
      state = state - 1;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final unreadCountNotifierProvider =
    StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return UnreadCountNotifier(repository);
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(unreadCountNotifierProvider);
});

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationsNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getNotifications();
      if (mounted) {
        state = AsyncValue.data(list);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> markAsRead(String id) async {
    final currentList = state.valueOrNull ?? [];
    final index = currentList.indexWhere((n) => n.id == id);
    if (index == -1) return;
    
    final currentItem = currentList[index];
    if (currentItem.read) return;

    try {
      final updatedItem = await _repository.markAsRead(id);
      final newList = List<NotificationModel>.from(currentList);
      newList[index] = updatedItem;
      state = AsyncValue.data(newList);
      _ref.read(unreadCountNotifierProvider.notifier).fetchUnreadCount();
    } catch (e) {
      // If server error occurs, fallback local update or keep original
    }
  }
}

final notificationsNotifierProvider = StateNotifierProvider<
    NotificationsNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationsNotifier(repository, ref);
});

final notificationsProvider = Provider<AsyncValue<List<NotificationModel>>>((ref) {
  return ref.watch(notificationsNotifierProvider);
});
