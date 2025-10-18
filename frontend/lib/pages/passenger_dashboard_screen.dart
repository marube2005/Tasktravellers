import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';

class PassengerDashboardScreen extends StatefulWidget {
	const PassengerDashboardScreen({super.key});

	@override
	State<PassengerDashboardScreen> createState() => _PassengerDashboardScreenState();
}

class _PassengerDashboardScreenState extends State<PassengerDashboardScreen> {
	int _selectedIndex = 0;

	void _onItemTapped(int index) {
		setState(() => _selectedIndex = index);
	}

	@override
	Widget build(BuildContext context) {
		final pages = <Widget>[
			const _HomeTab(),
			const _RidesTab(),
			const _PaymentsTab(),
			const _ProfileTab(),
		];

		return Scaffold(
			appBar: AppBar(
				title: Text(['Home', 'Rides', 'Payments', 'Profile'][_selectedIndex]),
				centerTitle: true,
			),
			body: IndexedStack(index: _selectedIndex, children: pages),
			bottomNavigationBar: BottomNavigationBar(
				currentIndex: _selectedIndex,
				onTap: _onItemTapped,
				type: BottomNavigationBarType.fixed,
				selectedItemColor: Colors.green, // Match the provided design
				unselectedItemColor: Colors.grey,
				items: const [
					BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
					BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Rides'),
					BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Payments'),
					BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
				],
			),
		);
	}
}

class _HomeTab extends StatelessWidget {
	const _HomeTab();

	@override
	Widget build(BuildContext context) {
		return ListView(
			padding: const EdgeInsets.all(16.0),
			children: [
				ElevatedButton(
					onPressed: () => Navigator.pushNamed(context, '/matatu-list'),
					child: const Text('Find Matatus'),
				),
				const SizedBox(height: 12),
				ElevatedButton(
					onPressed: () => Navigator.pushNamed(context, '/live-tracking'),
					child: const Text('Live Tracking'),
				),
				const SizedBox(height: 12),
				OutlinedButton(
					onPressed: () => Navigator.pushNamed(context, '/ride-complete'),
					style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
					child: const Text('Complete Ride (Demo)'),
				),
			],
		);
	}
}

class _RidesTab extends StatelessWidget {
	const _RidesTab();

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					const Text('Browse and join rides'),
					const SizedBox(height: 12),
					ElevatedButton(
						onPressed: () => Navigator.pushNamed(context, '/matatu-list'),
						child: const Text('Open Rides List'),
					),
				],
			),
		);
	}
}

class _PaymentsTab extends StatelessWidget {
	const _PaymentsTab();

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					const Text('Manage your payments'),
					const SizedBox(height: 12),
					ElevatedButton(
						onPressed: () => Navigator.pushNamed(context, '/payment'),
						child: const Text('Go to Checkout'),
					),
				],
			),
		);
	}
}

class _ProfileTab extends StatelessWidget {
	const _ProfileTab();

	@override
	Widget build(BuildContext context) {
		return ListView(
			padding: const EdgeInsets.all(16.0),
			children: const [
				CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
				SizedBox(height: 12),
				Center(child: Text('John Doe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
				SizedBox(height: 24),
				ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
				ListTile(leading: Icon(Icons.logout), title: Text('Log out')),
			],
		);
	}
}


