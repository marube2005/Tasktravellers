import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';

class PassengerDashboardScreen extends StatelessWidget {
	const PassengerDashboardScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Passenger Dashboard'),
				centerTitle: true,
				actions: [
					IconButton(
						icon: const Icon(Icons.search),
						onPressed: () => Navigator.pushNamed(context, '/matatu-list'),
					),
				],
			),
			body: ListView(
				padding: const EdgeInsets.all(16.0),
				children: [
					ElevatedButton(
						onPressed: () => Navigator.pushNamed(context, '/live-tracking'),
						child: const Text('Live Tracking'),
					),
					const SizedBox(height: 12),
					ElevatedButton(
						onPressed: () => Navigator.pushNamed(context, '/payment'),
						child: const Text('Checkout / Pay'),
					),
					const SizedBox(height: 12),
					OutlinedButton(
						onPressed: () => Navigator.pushNamed(context, '/ride-complete'),
						style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
						child: const Text('Complete Ride (Demo)'),
					),
				],
			),
		);
	}
}

