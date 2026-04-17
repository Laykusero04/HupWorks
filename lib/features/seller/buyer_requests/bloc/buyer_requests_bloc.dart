import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/job_post_repository.dart';
import 'buyer_requests_event.dart';
import 'buyer_requests_state.dart';

class BuyerRequestsBloc extends Bloc<BuyerRequestsEvent, BuyerRequestsState> {
  final JobPostRepository _jobPostRepository;

  BuyerRequestsBloc({required JobPostRepository jobPostRepository})
      : _jobPostRepository = jobPostRepository,
        super(BuyerRequestsInitial()) {
    on<BuyerRequestsLoadRequested>(_onLoadRequested);
    on<BuyerRequestOfferCreated>(_onOfferCreated);
  }

  Future<void> _onLoadRequested(
    BuyerRequestsLoadRequested event,
    Emitter<BuyerRequestsState> emit,
  ) async {
    emit(BuyerRequestsLoading());
    try {
      final requests = await _jobPostRepository.getBuyerRequests();
      emit(BuyerRequestsLoaded(requests: requests));
    } on Failure catch (e) {
      emit(BuyerRequestsError(e.message));
    } catch (e) {
      emit(BuyerRequestsError(e.toString()));
    }
  }

  Future<void> _onOfferCreated(
    BuyerRequestOfferCreated event,
    Emitter<BuyerRequestsState> emit,
  ) async {
    emit(BuyerRequestsLoading());
    try {
      await _jobPostRepository.createOffer(
        jobPostId: event.jobPostId,
        price: event.price,
        deliveryTime: event.deliveryTime,
        coverLetter: event.coverLetter,
      );
      emit(BuyerRequestOfferSuccess());
    } on Failure catch (e) {
      emit(BuyerRequestsError(e.message));
    } catch (e) {
      emit(BuyerRequestsError(e.toString()));
    }
  }
}
