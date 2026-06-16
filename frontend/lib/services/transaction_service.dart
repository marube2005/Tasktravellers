import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Maps directly to the 'transaction_status' ENUM in the Supabase database.
enum TransactionStatus {
  pending,
  completed,
  failed,
}

// Extension to convert the enum to a database string
extension TransactionStatusExtension on TransactionStatus {
  String toShortString() {
    return toString().split('.').last;
  }
}

/// A service class to handle payment processing and transaction recording
/// using PayHero (simulated via Edge Function).
///
/// Commission calculation is enforced server-side by the database trigger
/// `trg_transactions_commission`. The constant below is kept only for
/// display purposes in the UI so the user can see the expected breakdown
/// before confirming payment.
class TransactionService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Display-only commission rate. The authoritative calculation happens in the
  /// DB trigger and cannot be overridden by client code.
  static const double commissionRate = 0.05;

  /// Private constructor for Singleton pattern.
  TransactionService._internal();
  static final TransactionService _instance = TransactionService._internal();

  /// Factory constructor to return the single instance of TransactionService.
  factory TransactionService() => _instance;

  // Helper to get the current authenticated user's ID
  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  /// =========================================================================
  /// 1. TRANSACTION INITIATION (POST-RIDE PAYMENT)
  /// =========================================================================

  /// Initiates a payment for a completed ride.
  ///
  /// This function simulates initiating an M-Pesa STK push via PayHero,
  /// typically proxied through a Supabase Edge Function for security.
  ///
  /// @param rideId The ID of the ride being paid for.
  /// @param amount The total estimated fare for the ride (paid by passenger).
  Future<void> initiatePayment({
    required String rideId,
    required double amount,
  }) async {
    final payerId = _currentUserId;
    if (payerId == null) {
      throw Exception('Authentication required. User not logged in.');
    }

    if (amount <= 0) {
      throw Exception('Payment amount must be greater than zero.');
    }

    // Commission shown to the user for display; the DB trigger recalculates it.
    final commission = amount * commissionRate;
    final totalAmount = amount; 

    // 1. Create a unique, preliminary transaction ID
    final provisionalTxId = const Uuid().v4(); 

    // 2. Record the transaction in the 'transactions' table with 'pending' status.
    try {
      await _supabaseClient.from('transactions').insert({
        'ride_id': rideId,
        'payer_id': payerId,
        'amount': totalAmount,
        'commission': commission,
        'status': TransactionStatus.pending.toShortString(),
        'payhero_tx_id': provisionalTxId, 
      });

    } on PostgrestException catch (e) {
      throw Exception('Database Error recording initial transaction: ${e.message}');
    }

    // 3. Call the Secure Backend/Edge Function to trigger the M-Pesa STK Push.
    try {
      // NOTE: Replace 'payhero-stk-push' with your actual Edge Function name.
      await _supabaseClient.functions.invoke(
        'payhero-stk-push', 
        body: {
          'rideId': rideId,
          'amount': totalAmount,
          'payerId': payerId,
          // The Edge Function handles fetching the user's phone number securely
        },
      );
      
      // Success means the STK push has been initiated; the user awaits the prompt on their phone.
      // The final status update (completed/failed) is handled by a backend webhook.

    } catch (e) {
      // If the API call fails, the transaction status remains 'pending'
      throw Exception('Failed to initiate PayHero payment process. Please try again.');
    }
  }
  
  // =========================================================================
  // NOTE: updateTransactionStatus has been intentionally removed from the
  // client-side API.
  //
  // Transaction status (pending → completed / failed) must ONLY be updated by
  // the PayHero webhook via a Supabase Edge Function running with the service
  // role key.  The database RLS policy "Transactions: admin update only" blocks
  // all direct status updates by regular authenticated users.
  // =========================================================================

  /// =========================================================================
  /// 3. TRANSACTION QUERIES (PASSENGER & SACCO VIEWS)
  /// =========================================================================

  /// Fetches the current user's transaction history (as the payer).
  Future<List<Map<String, dynamic>>> fetchMyTransactions() async {
    final userId = _currentUserId;
    if (userId == null) {
      return [];
    }

    try {
      final List<Map<String, dynamic>> transactions = await _supabaseClient
          .from('transactions')
          .select('*, rides(origin, destination)') // Join basic ride details
          .eq('payer_id', userId)
          .order('created_at', ascending: false);

      return transactions;
    } on PostgrestException catch (e) {
      throw Exception('Database Error fetching passenger transactions: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching passenger transactions: $e');
    }
  }

  /// Fetches all completed transactions for a specific Sacco.
  /// Useful for calculating Sacco earnings.
  Future<List<Map<String, dynamic>>> fetchSaccoCompletedTransactions({required String saccoId}) async {
    try {
      // Fetch transactions where the related ride's provider_id matches the saccoId
      final List<Map<String, dynamic>> earnings = await _supabaseClient
          .from('transactions')
          .select('*, rides(provider_id, origin, destination)')
          .eq('status', TransactionStatus.completed.toShortString())
          .eq('rides.provider_id', saccoId); 

      // NOTE: Ensure your RLS policies allow a Sacco to read transactions linked to their rides.
      return earnings;
    } on PostgrestException catch (e) {
      throw Exception('Database Error fetching Sacco earnings: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching Sacco earnings: $e');
    }
  }
}
