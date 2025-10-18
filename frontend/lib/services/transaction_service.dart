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

/// A service class to handle payment processing, commission calculation,
/// and transaction recording using PayHero (simulated via Edge Function).
class TransactionService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  static const double _commissionRate = 0.05; // 5% commission

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

    // Commission is calculated on the total amount
    final commission = amount * _commissionRate; 
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
  
  /// =========================================================================
  /// 2. TRANSACTION STATUS UPDATE (Called by Webhook/Admin)
  /// =========================================================================
  
  /// Updates the status of an existing transaction based on PayHero's confirmation.
  /// In a real application, this is usually called by a **Supabase Webhook/Edge Function**
  /// after receiving a success/failure notification from PayHero.
  Future<void> updateTransactionStatus({
    required String provisionalTxId,
    required TransactionStatus newStatus,
    String? finalPayheroTxId, // The official transaction ID if successful
  }) async {
    try {
      final updateData = {
        'status': newStatus.toShortString(),
        // Only update the final PayHero ID if provided (i.e., on success)
        if (finalPayheroTxId != null) 'payhero_tx_id': finalPayheroTxId, 
      };
      
      await _supabaseClient
          .from('transactions')
          .update(updateData)
          .eq('payhero_tx_id', provisionalTxId); // Update using the unique ID
          
    } on PostgrestException catch (e) {
      throw Exception('Database Error updating transaction status: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while updating status: $e');
    }
  }

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