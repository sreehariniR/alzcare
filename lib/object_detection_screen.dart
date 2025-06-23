import 'dart:io';                      // For File operations
import 'dart:convert';                // For decoding JSON response
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({Key? key}) : super(key: key); // Proper key constructor

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  File? _image;
  String _result = "";

  /// Pick an image from the gallery
  Future<void> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _result = ""; // Reset result when new image is picked
      });
    }
  }

  /// Send image to backend and get detected objects
  Future<void> detectObjects() async {
    if (_image == null) return;

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("http://192.168.0.102:5000/detect")
      , // Change IP if testing on a real device
    );

    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      setState(() {
        _result = decoded['objects'].join(', ');
      });
    } else {
      setState(() {
        _result = "Detection failed: ${response.statusCode}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Detection'),
        backgroundColor: Colors.deepPurple.shade300,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null)
              Container(
                height: 250,
                child: Stack(
                  children: [
                    Positioned.fill(child: Image.file(_image!, fit: BoxFit.cover)),
                    if (_result.isNotEmpty)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          color: Colors.black.withOpacity(0.6),
                          child: Text(
                            'Detected: $_result',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),


            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: Icon(Icons.photo),
              label: Text("Pick from Gallery"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade100,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => pickImage(ImageSource.gallery),
            ),

            SizedBox(height: 10),

            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text("Take a Photo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade200,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => pickImage(ImageSource.camera),
            ),


            const SizedBox(height: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text("Detect Objects"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade200,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: detectObjects,
            ),

            const SizedBox(height: 30),

            Text(
              _result.isNotEmpty ? 'Detected: $_result' : 'No detection yet',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
