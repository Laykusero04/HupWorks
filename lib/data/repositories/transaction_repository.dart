import '../../core/errors/failures.dart';
import '../../services/transaction_service.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  Future<List<AppTransaction>> getTransactions() async {
    try {
      final data = await TransactionService.getTransactions();
      return data.map((m) => AppTransaction.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<AppTransaction> createDeposit({
    required double amount,
    required String gateway,
  }) async {
    try {
      final data = await TransactionService.createDeposit(amount: amount, gateway: gateway);
      return AppTransaction.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<AppTransaction>> getDepositHistory() async {
    try {
      final data = await TransactionService.getDepositHistory();
      return data.map((m) => AppTransaction.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
