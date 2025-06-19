import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

class ObjectDetectionScreen extends StatefulWidget {
  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  CameraController? _cameraController;
  List? _recognitions;
  bool _isDetecting = false;
  late List<CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();
    loadModel();
    initCamera();
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/ssd_mobilenet.tflite",
      labels: "assets/labels.txt",
    );
  }

  void initCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.medium);
    await _cameraController!.initialize();

    _cameraController!.startImageStream((CameraImage image) {
      if (_isDetecting) return;
      _isDetecting = true;

      Tflite.runModelOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        threshold: 0.4,
        asynch: true,
      ).then((recognitions) {
        setState(() {
          _recognitions = recognitions;
        });
        _isDetecting = false;
      });
    });

    setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    Tflite.close();
    super.dispose();
  }

  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null) return [];
    return _recognitions!.map((re) {
      return Positioned(
        left: re["rect"]["x"] * screen.width,
        top: re["rect"]["y"] * screen.height,
        width: re["rect"]["w"] * screen.width,
        height: re["rect"]["h"] * screen.height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                backgroundColor: Colors.white54,
                color: Colors.deepPurple,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('AI Object Detection')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(title: Text('AI Object Detection')),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          ...renderBoxes(size),
        ],
      ),
    );
  }
}
