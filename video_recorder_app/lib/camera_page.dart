import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_saver/gallery_saver.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;
  late List<CameraDescription> cameras;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        controller = CameraController(cameras[0], ResolutionPreset.high);
        await controller?.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.storage,
      Permission.photos, // For iOS
    ].request();
  }

  Future<void> videoRecording(XFile? video) async {
    if (video != null) {
      final filePath = video.path;
      try {
        await GallerySaver.saveVideo(filePath);
        print('Video saved to gallery!');
      } catch (e) {
        print('Error saving video to gallery: $e');
      }
    }
  }

  Future<void> stopVideoRecording() async {
    if (!controller!.value.isRecordingVideo) return;
    try {
      final video = await controller?.stopVideoRecording();
      await videoRecording(video);
      setState(() {
        isRecording = false;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> startVideoRecording() async {
    if (!controller!.value.isInitialized || isRecording) return;

    await _requestPermissions();
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;

    if (cameraStatus.isGranted && storageStatus.isGranted) {
      try {
        await controller?.startVideoRecording();
        setState(() {
          isRecording = true;
        });
      } catch (e) {
        print('Error starting video recording: $e');
      }
    } else {
      print('Camera or storage permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          if (controller != null && controller!.value.isInitialized)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: CameraPreview(controller!),
              ),
            )
          else
            Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 30.0,
            left: 16.0,
            right: 16.0,
            child: ElevatedButton(
              onPressed: isRecording ? stopVideoRecording : startVideoRecording,
              child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
          ),
        ],
      ),
    );
  }
}
