import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/transaction_repository.dart';
import 'seller_withdraw_event.dart';
import 'seller_withdraw_state.dart';

class SellerWithdrawBloc extends Bloc<SellerWithdrawEvent, SellerWithdrawState> {
  final TransactionRepository _transactionRepository;

  SellerWithdrawBloc({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository,
        super(WithdrawInitial()) {
    on<WithdrawHistoryLoadRequested>(_onHistoryLoadRequested);
    on<WithdrawRequested>(_onWithdrawRequested);
  }

  Future<void> _onHistoryLoadRequested(
    WithdrawHistoryLoadRequested event,
    Emitter<SellerWithdrawState> emit,
  ) async {
    emit(WithdrawLoading());
    try {
      final deposits = await _transactionRepository.getDepositHistory();
      emit(WithdrawLoaded(deposits: deposits));
    } on Failure catch (e) {
      emit(WithdrawError(e.message));
    } catch (e) {
      emit(WithdrawError(e.toString()));
    }
  }

  Future<void> _onWithdrawRequested(
    WithdrawRequested event,
    Emitter<SellerWithdrawState> emit,
  ) async {
    emit(WithdrawLoading());
    try {
      await _transactionRepository.createDeposit(
        amount: event.amount,
        gateway: event.gateway,
      );
      emit(WithdrawSuccess());
    } on Failure catch (e) {
      emit(WithdrawError(e.message));
    } catch (e) {
      emit(WithdrawError(e.toString()));
    }
  }
}
