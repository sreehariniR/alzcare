import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'object_detection_screen.dart';
class PatientHomePage extends StatelessWidget {
  Future<void> fetchData(BuildContext context, String endpoint) async {
    final url = Uri.parse('http://127.0.0.1:5000/$endpoint'); // Use IP if real device

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Response'),
            content: Text(data.values.first.toString()),
          ),
        );
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text(e.toString()),
        ),
      );
    }
  }

  final List<String> memoryPhotos = [
    'https://via.placeholder.com/150',
    'https://via.placeholder.com/160',
    'https://via.placeholder.com/170',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AIzCare Patient'),
        backgroundColor: Colors.deepPurple.shade300,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Memory Lane", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: memoryPhotos.length,
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(memoryPhotos[index], width: 140, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text("AI Object Recognition"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 60),
                backgroundColor: Colors.deepPurple.shade100,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ObjectDetectionScreen()),
                );
              },
            ),

            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.mic),
              label: Text("Voice Assistant"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 60),
                backgroundColor: Colors.deepPurple.shade50,
              ),
              onPressed: () {
                fetchData(context, 'voice'); // Use different endpoint per button
              },

            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.warning_amber),
              label: Text("Emergency Call"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 60),
                backgroundColor: Colors.redAccent.shade100,
              ),
              onPressed: () => print('Emergency Alert!'),
            ),
          ],
        ),
      ),
    );
  }
}
