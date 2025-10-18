import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
	const WelcomeScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Welcome')),
			body: Center(
				child: ElevatedButton(
					onPressed: () => Navigator.pushNamed(context, '/login'),
					child: const Text('Go to Dashboard'),
				),
			),
		);
	}
}

