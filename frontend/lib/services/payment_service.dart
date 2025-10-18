import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Add uuid package to your pubspec.yaml

/// A service class to handle payment processing, commission calculation,
/// and transaction recording using PayHero (simulated via Edge Function).
class PaymentService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  static const double _commissionRate = 0.05; // 5% commission

  /// Private constructor for Singleton pattern.
  PaymentService._internal();
  static final PaymentService _instance = PaymentService._internal();

  /// Factory constructor to return the single instance of PaymentService.
  factory PaymentService() => _instance;

  // Helper to get the current authenticated user's ID
  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  /// =========================================================================
  /// 1. TRANSACTION INITIATION
  /// =========================================================================

  /// Initiates a payment for a completed ride.
  ///
  /// This function simulates initiating an M-Pesa STK push via PayHero,
  /// typically proxied through a Supabase Edge Function for security.
  ///
  /// @param rideId The ID of the ride being paid for.
  /// @param amount The total estimated fare for the ride.
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

    final commission = amount * _commissionRate;
    final totalAmount = amount; // Total amount paid by the passenger

    // 1. Create a unique, preliminary transaction ID (optional, but useful)
    final provisionalTxId = const Uuid().v4(); 

    // 2. Record the transaction in the 'transactions' table with 'pending' status.
    // This ensures we have a record even if the external payment fails.
    try {
      await _supabaseClient.from('transactions').insert({
        'ride_id': rideId,
        'payer_id': payerId,
        'amount': totalAmount,
        'commission': commission,
        'status': 'pending',
        // Optional: Store the provisional ID until PayHero returns a final one.
        'payhero_tx_id': provisionalTxId, 
      });

    } on PostgrestException catch (e) {
      throw Exception('Database Error recording initial transaction: ${e.message}');
    }

    // 3. Call the Secure Backend/Edge Function to trigger the M-Pesa STK Push.
    // NOTE: This call must contain sensitive data like phone number, amount, etc.
    // The actual PayHero integration logic resides here.
    try {
      // Assuming you use a Supabase Edge Function named 'payhero-stk-push'
      // You would pass the details required by the payment gateway (phone, amount, etc.)
      // The function should return a status and the final PayHero reference ID.
      final response = await _supabaseClient.functions.invoke(
        'payhero-stk-push', // Name of your Supabase Edge Function
        body: {
          'rideId': rideId,
          'amount': totalAmount,
          'payerId': payerId,
          // 'phone': fetchUserPhone(payerId), // Need to fetch phone from 'users' table
          'callbackUrl': 'YOUR_SUPABASE_WEBHOOK_URL', // URL for PayHero to confirm payment
        },
      );
      
      // In a real scenario, this response would contain the STK Push success status
      // and the unique transaction ID from PayHero/M-Pesa.
      
      // For this example, we assume the STK push was successfully initiated.
      // The actual 'completed' or 'failed' update happens in a backend webhook.

    } catch (e) {
      // If the API call fails, the transaction status remains 'pending'
      throw Exception('Failed to initiate PayHero payment process. Please try again.');
    }
    
    // Success means the STK push has been initiated; user awaits prompt on phone.
  }

  /// =========================================================================
  /// 2. TRANSACTION QUERIES (PASSENGER VIEW)
  /// =========================================================================

  /// Fetches the current user's transaction history.
  Future<List<Map<String, dynamic>>> fetchMyTransactions() async {
    final userId = _currentUserId;
    if (userId == null) {
      return [];
    }

    try {
      // Fetch all transactions where the current user is the payer
      final List<Map<String, dynamic>> transactions = await _supabaseClient
          .from('transactions')
          .select('*, rides(origin, destination)') // Select transaction and join basic ride details
          .eq('payer_id', userId)
          .order('created_at', ascending: false);

      return transactions;
    } on PostgrestException catch (e) {
      throw Exception('Database Error fetching transactions: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching transactions: $e');
    }
  }

  /// =========================================================================
  /// 3. ADMIN/SACCO VIEW (Optional but useful)
  /// =========================================================================

  /// Fetches all completed transactions for a specific Sacco (by provider_id).
  /// This requires the Sacco to be linked to the ride.
  Future<List<Map<String, dynamic>>> fetchSaccoEarnings(String saccoId) async {
    try {
      // Find rides managed by the Sacco
      final List<Map<String, dynamic>> earnings = await _supabaseClient
          .from('transactions')
          .select('*, rides(provider_id, origin, destination)') // Join ride details
          .eq('status', 'completed')
          .eq('rides.provider_id', saccoId); // Filter by the Sacco's ID

      // This query requires RLS to be configured to allow Saccos to read transactions
      // related to their rides.
      return earnings;
    } on PostgrestException catch (e) {
      throw Exception('Database Error fetching Sacco earnings: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching Sacco earnings: $e');
    }
  }
}