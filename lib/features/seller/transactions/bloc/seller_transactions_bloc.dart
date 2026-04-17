import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/transaction_repository.dart';
import 'seller_transactions_event.dart';
import 'seller_transactions_state.dart';

class SellerTransactionsBloc extends Bloc<SellerTransactionsEvent, SellerTransactionsState> {
  final TransactionRepository _transactionRepository;

  SellerTransactionsBloc({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository,
        super(SellerTransactionsInitial()) {
    on<SellerTransactionsLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    SellerTransactionsLoadRequested event,
    Emitter<SellerTransactionsState> emit,
  ) async {
    emit(SellerTransactionsLoading());
    try {
      final transactions = await _transactionRepository.getTransactions();
      emit(SellerTransactionsLoaded(transactions: transactions));
    } on Failure catch (e) {
      emit(SellerTransactionsError(e.message));
    } catch (e) {
      emit(SellerTransactionsError(e.toString()));
    }
  }
}
