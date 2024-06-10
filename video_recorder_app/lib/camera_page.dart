import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late List<CameraDescription> cameras;
  late CameraController controller;
  late Future<void> _initializeControllerFuture;
  bool isRecording = false;
  String currentDateTime = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _updateDateTime();
  }

  void _initializeCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.high);
    _initializeControllerFuture = controller.initialize();
    setState(() {});
  }

  void _updateDateTime() {
    setState(() {
      currentDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    });
    Future.delayed(Duration(seconds: 1), _updateDateTime);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<String?> _startVideoRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    final String filePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

    if (controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.startVideoRecording();
      setState(() {
        isRecording = true;
      });
      return filePath;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return;
    }

    try {
      XFile videoFile = await controller.stopVideoRecording();
      await _saveVideoLocally(videoFile);
      setState(() {
        isRecording = false;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _saveVideoLocally(XFile videoFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final String filePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
    final File localFile = File(filePath);
    await localFile.writeAsBytes(await videoFile.readAsBytes());
    print('Video saved locally at: $filePath');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(controller),
                Positioned(
                  top: 50,
                  left: 20,
                  child: Text(
                    currentDateTime,
                    style: TextStyle(
                      color: Color.fromARGB(255, 4, 202, 252),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      backgroundColor: Color.fromARGB(0, 0, 0, 0),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        onPressed: () async {
                          await _startVideoRecording();
                        },
                        child: Icon(Icons.videocam),
                        backgroundColor: isRecording ? Colors.grey : Color.fromARGB(255, 16, 191, 244),
                      ),
                      SizedBox(width: 20),
                      FloatingActionButton(
                        onPressed: () async {
                          await _stopVideoRecording();
                        },
                        child: Icon(Icons.stop),
                        backgroundColor: isRecording ? Colors.grey : Color.fromARGB(255, 10, 236, 244),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
