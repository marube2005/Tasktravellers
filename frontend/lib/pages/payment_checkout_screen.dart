// lib/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:travelers_app/main.dart'; // Adjust import path

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {}),
        title: const Text('Checkout'),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Summary Section
          const _SummarySection(),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const _MpesaCard(),
                  const SizedBox(height: 24),
                  const _PhoneNumberField(),
                  const SizedBox(height: 24),
                  const _PoweredByFooter(),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      "You'll receive an M-Pesa prompt on your phone",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Sticky Bottom Button
      bottomNavigationBar: const _PayButton(),
    );
  }
}

// --- Reusable Component Widgets ---

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.cardLight,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Column(
          children: [
            _SummaryRow(label: 'Nairobi to Mombasa', value: 'Ksh 1,500'),
            _SummaryRow(label: 'Commission', value: 'Ksh 150'),
            Divider(height: 24),
            _SummaryRow(label: 'Total', value: 'Ksh 1,650', isTotal: true),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    final textStyle = isTotal
        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500);
    
    final valueStyle = isTotal 
        ? textStyle 
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class _MpesaCard extends StatelessWidget {
  const _MpesaCard();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Use a local asset or a placeholder if network image fails
              Image.network('https://picsum.photos/seed/mpesa/40', height: 32, errorBuilder: (c, o, s) => const Icon(Icons.payment)),
              const SizedBox(width: 16),
              const Text('M-Pesa', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Row(
            children: [
              Icon(Icons.lock, size: 14, color: Colors.green),
              SizedBox(width: 4),
              Text('Secure', style: TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhoneNumberField extends StatelessWidget {
  const _PhoneNumberField();
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phone number', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: '0712345678',
          enabled: false,
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkMode ? AppColors.cardDark : AppColors.cardLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _PoweredByFooter extends StatelessWidget {
  const _PoweredByFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.network('https://picsum.photos/seed/payhero/40', height: 32, errorBuilder: (c, o, s) => const Icon(Icons.shield)),
        const SizedBox(width: 16),
        const Text('Powered by PayHero', style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          ),
          child: const Text('Pay Ksh 1,650', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}