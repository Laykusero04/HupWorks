import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationBloc({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository,
        super(NotificationsInitial()) {
    on<NotificationsLoadRequested>(_onLoadRequested);
    on<NotificationMarkReadRequested>(_onMarkReadRequested);
    on<NotificationsMarkAllReadRequested>(_onMarkAllReadRequested);
  }

  Future<void> _onLoadRequested(NotificationsLoadRequested event, Emitter<NotificationState> emit) async {
    emit(NotificationsLoading());
    try {
      final notifications = await _notificationRepository.getNotifications();
      emit(NotificationsLoaded(notifications: notifications));
    } on Failure catch (e) {
      emit(NotificationsError(e.message));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> _onMarkReadRequested(NotificationMarkReadRequested event, Emitter<NotificationState> emit) async {
    try {
      await _notificationRepository.markAsRead(event.notificationId);
      add(NotificationsLoadRequested());
    } on Failure catch (e) {
      emit(NotificationsError(e.message));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> _onMarkAllReadRequested(NotificationsMarkAllReadRequested event, Emitter<NotificationState> emit) async {
    try {
      await _notificationRepository.markAllAsRead();
      add(NotificationsLoadRequested());
    } on Failure catch (e) {
      emit(NotificationsError(e.message));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }
}
