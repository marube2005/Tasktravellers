// lib/ride_complete_screen.dart
import 'package:flutter/material.dart';

class RideCompleteScreen extends StatefulWidget {
  const RideCompleteScreen({super.key});

  @override
  State<RideCompleteScreen> createState() => _RideCompleteScreenState();
}

class _RideCompleteScreenState extends State<RideCompleteScreen> {
  // State variables
  int _rating = 0;
  final _feedbackController = TextEditingController();

  void _setRating(int rating) {
    setState(() {
      _rating = rating;
      // HELLO
    });
  }

  void _submitRating() {
    if (_rating > 0) {
      // Handle the submission logic here
      print('Rating: $_rating stars');
      print('Feedback: ${_feedbackController.text}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubmitEnabled = _rating > 0;

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.check_circle, size: 30),
        title: const Text('Ride Complete!'),
        // A simple SizedBox to balance the title in the center
        actions: const [SizedBox(width: 56)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            Text(
              'How was your ride with Matatu Sacco?',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Nairobi to Mombasa',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),
            // Star Rating Widget
            _buildStarRating(),
            const SizedBox(height: 32),
            // Feedback Text Field
            TextFormField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                hintText: 'Tell us more about your experience (optional)',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            // Submit Button
            ElevatedButton(
              onPressed: isSubmitEnabled ? _submitRating : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56), // h-14
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 24),
            // Footer Links
            _buildFooterLinks(context),
          ],
        ),
      ),
    );
  }

  // Helper method to build the interactive star rating row
  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return IconButton(
          onPressed: () => _setRating(starNumber),
          icon: Icon(
            starNumber <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
        );
      }),
    );
  }

  // Helper method to build the footer links
  Widget _buildFooterLinks(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {},
          child: Text('View Ride Summary', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500)),
        ),
        Text(
          '|',
          style: TextStyle(color: Colors.grey.shade300, fontSize: 16),
        ),
        TextButton(
          onPressed: () {},
          child: Text('Get Receipt', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}