import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MatatuDetailsScreen(),
    );
  }
}

class MatatuDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {},
        ),
        title: Text('Matatu Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Column(
                children: [
                  Image.network(
                    'https://via.placeholder.com/300x150',
                    fit: BoxFit.cover,
                  ),
                  ListTile(
                    title: Text('Rongai Express'),
                    subtitle: Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.yellow),
                        Icon(Icons.star, size: 16, color: Colors.yellow),
                        Icon(Icons.star, size: 16, color: Colors.yellow),
                        Icon(Icons.star_half, size: 16, color: Colors.yellow),
                        Icon(Icons.star_border, size: 16, color: Colors.yellow),
                        Text(' 4.0 (125 reviews)'),
                      ],
                    ),
                    trailing: Chip(label: Text('14-seater')),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Route Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Nairobi CBD', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('  Start'),
                Text('  Kasarani'),
                Text('  Roysambu'),
                Text('  Thika'),
                Text('• Thika', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('  End'),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Amenities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(Icons.wifi, color: Colors.blue),
                    Text('Free Wi-Fi'),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.power, color: Colors.blue),
                    Text('Charging Ports'),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.ac_unit, color: Colors.blue),
                    Text('Air Conditioning'),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.music_note, color: Colors.blue),
                    Text('Music System'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage('https://via.placeholder.com/40'),
              ),
              title: Text('John Doe'),
              subtitle: Text('Driver'),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text('Book Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}