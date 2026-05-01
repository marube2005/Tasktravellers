import 'transaction_service.dart';

/// Backward-compatible facade for legacy imports.
///
/// All payment initiation is delegated to [TransactionService], which uses a
/// secure backend/Edge Function path instead of client-side secret credentials.
class PaymentService {
  PaymentService._internal();
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;

  final TransactionService _transactionService = TransactionService();

  Future<void> initiatePayment({
    required String rideId,
    required double amount,
  }) async {
    await _transactionService.initiatePayment(rideId: rideId, amount: amount);
  }

  Future<List<Map<String, dynamic>>> fetchMyTransactions() {
    return _transactionService.fetchMyTransactions();
  }

  Future<List<Map<String, dynamic>>> fetchSaccoEarnings(String saccoId) {
    return _transactionService.fetchSaccoCompletedTransactions(saccoId: saccoId);
  }
}
