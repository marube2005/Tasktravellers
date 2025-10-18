import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http; // Added for API calls
import 'dart:convert'; // Added for jsonEncode/Decode
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added to load credentials

/// A service class to handle payment processing, commission calculation,
/// and transaction recording using PayHero.
///
/// WARNING: This implementation calls PayHero directly from the client,
/// which is insecure for production. Use a Supabase Edge Function instead.
class PaymentService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  static const double _commissionRate = 0.05; // 5% commission

  // --- PayHero Credentials (INSECURE: For testing only) ---
  // Load these from your .env file
  final String _apiUsername = dotenv.env['PAYHERO_API_USERNAME'] ?? '';
  final String _apiPassword = dotenv.env['PAYHERO_API_PASSWORD'] ?? '';
  final int _channelId = int.tryParse(dotenv.env['PAYHERO_CHANNEL_ID'] ?? '0') ?? 0;
  final String _callbackUrl = dotenv.env['PAYHERO_CALLBACK_URL'] ?? '';
  // ---------------------------------------------------------

  /// Private constructor for Singleton pattern.
  PaymentService._internal();
  static final PaymentService _instance = PaymentService._internal();

  /// Factory constructor to return the single instance of PaymentService.
  factory PaymentService() => _instance;

  // Helper to get the current authenticated user's ID
  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  /// Helper to generate the Basic Auth token for PayHero
  String _getBasicAuthToken() {
    if (_apiUsername.isEmpty || _apiPassword.isEmpty) {
      throw Exception('PayHero API credentials are not set in .env file');
    }
    final String credentials = '$_apiUsername:$_apiPassword';
    final String encodedCredentials = base64Encode(utf8.encode(credentials));
    return 'Basic $encodedCredentials';
  }

  /// =========================================================================
  /// 1. TRANSACTION INITIATION
  /// =========================================================================

  /// Initiates a payment for a completed ride by triggering an M-Pesa STK Push
  /// directly via the PayHero API.
  ///
  /// @param rideId The ID of the ride being paid for.
  /// @param amount The total estimated fare for the ride.
  /// @param phoneNumber The customer's phone number (e.g., 0712345678).
  /// @param customerName The customer's name (e.g., John Doe).
  Future<void> initiatePayment({
    required String rideId,
    required double amount,
    required String phoneNumber,
    required String customerName,
  }) async {
    final payerId = _currentUserId;
    if (payerId == null) {
      throw Exception('Authentication required. User not logged in.');
    }

    if (amount <= 0) {
      throw Exception('Payment amount must be greater than zero.');
    }

    if (_channelId == 0 || _callbackUrl.isEmpty) {
      throw Exception('PayHero Channel ID or Callback URL is not set in .env file');
    }

    final commission = amount * _commissionRate;
    final totalAmount = amount; // Total amount paid by the passenger
    final int amountInt = totalAmount.toInt(); // PayHero requires an Integer

    // 1. Create a unique external reference
    final externalReference = const Uuid().v4();

    // 2. Record the transaction in the 'transactions' table with 'pending' status.
    try {
      await _supabaseClient.from('transactions').insert({
        'ride_id': rideId,
        'payer_id': payerId,
        'amount': totalAmount,
        'commission': commission,
        'status': 'pending',
        'external_reference': externalReference, // Use this to track
      });
    } on PostgrestException catch (e) {
      throw Exception(
          'Database Error recording initial transaction: ${e.message}');
    }

    // 3. Call the PayHero API to trigger the STK Push.
    // (This replaces the secure Edge Function call)
    try {
      final String authorizationHeader = _getBasicAuthToken();
      
      final Map<String, dynamic> body = {
        'amount': amountInt,
        'phone_number': phoneNumber,
        'channel_id': _channelId,
        'provider': 'm-pesa', // As per PayHero docs
        'external_reference': externalReference, // Our unique UUID
        'customer_name': customerName,
        'callback_url': _callbackUrl,
      };

      final response = await http.post(
        Uri.parse('https://backend.payhero.co.ke/api/v2/payments'),
        headers: {
          'Authorization': authorizationHeader,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // STK Push was successfully initiated by PayHero
        final responseData = jsonDecode(response.body);
        final String? payheroReference = responseData['reference'];
        final String? checkoutRequestId = responseData['CheckoutRequestID'];

        // 4. Update our transaction record with the PayHero references
        await _supabaseClient
            .from('transactions')
            .update({
              'payhero_reference': payheroReference,
              'checkout_request_id': checkoutRequestId,
              'status': 'queued', // Update status to show STK is active
            })
            .eq('external_reference', externalReference);
        
        // Success: STK push is on its way to the user's phone.
        // The final 'completed' or 'failed' status will be sent
        // by PayHero to your _callbackUrl (which should be a webhook/Edge Function).

      } else {
        // The API call to PayHero failed
        throw Exception(
            'Failed to initiate PayHero payment (Code ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      // If the API call fails, the transaction status remains 'pending'
      // You may want to add logic to update it to 'failed_initiation'
      throw Exception('Failed to initiate PayHero payment process: $e');
    }
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
          .select(
              '*, rides(origin, destination)') // Select transaction and join basic ride details
          .eq('payer_id', userId)
          .order('created_at', ascending: false);

      return transactions;
    } on PostgrestException catch (e) {
      throw Exception('Database Error fetching transactions: ${e.message}');
    } catch (e) {
      throw Exception(
          'An unexpected error occurred while fetching transactions: $e');
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
          .select(
              '*, rides(provider_id, origin, destination)') // Join ride details
          .eq('status', 'completed')
          .eq('rides.provider_id', saccoId); // Filter by the Sacco's ID

      // This query requires RLS to be configured to allow Saccos to read transactions
      // related to their rides.
      return earnings;
    } on PostgrestException catch (e) {
      throw Exception('Database Error fetching Sacco earnings: ${e.message}');
    } catch (e) {
      throw Exception(
          'An unexpected error occurred while fetching Sacco earnings: $e');
    }
  }
}