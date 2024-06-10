import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;
  late List<CameraDescription> cameras;
  bool isRecording = false;
  String? selectedDirectory;
  late String startDateTime;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras.isNotEmpty) {
        controller = CameraController(cameras[0], ResolutionPreset.high);
        controller?.initialize().then((_) {
          if (!mounted) return;
          setState(() {});
        });
      }
    }).catchError((e) {
      print('Error: $e.code\nError Message: $e.message');
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> startVideoRecording() async {
  if (!controller!.value.isInitialized) return;
  if (selectedDirectory == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please select a directory to save the recording.')),
    );
    return;
  }

  // Request storage permission if needed (Android 10+)
  if (await Permission.storage.request().isGranted) {
    final dir = Directory(selectedDirectory!);
    try {
      await dir.create(recursive: true); // Use async create method
      startDateTime = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filePath = path.join(dir.path, '$startDateTime.mp4');
      await controller?.startVideoRecording();
      setState(() {
        isRecording = true;
      });
      Provider.of<PathProvider>(context, listen: false).setVideoPath(filePath);
    } catch (e) {
      print('Error creating directory or recording: $e');
    }
  } else {
    print('Storage permission denied');
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

  Future<void> videoRecording(XFile? video) async {
    final pathProvider = Provider.of<PathProvider>(context, listen: false);
    final filePath = pathProvider.videoPath;
    try {
      if (video != null) {
        await video.saveTo(filePath);
      }
    } catch (e) {
      print('Error saving video: $e');
    }
  }

  void selectDirectory() async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath != null) {
      setState(() {
        selectedDirectory = directoryPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
          bottom: 100.0,
          left: 16.0,
          right: 16.0,
          child: ElevatedButton(
            onPressed: selectDirectory,
            child: Text('Select Directory'),
          ),
        ),
        if (selectedDirectory != null)
          Positioned(
            bottom: 70.0,
            left: 16.0,
            right: 16.0,
            child: Text(
              'Selected Directory: $selectedDirectory',
              style: TextStyle(color: Colors.white),
            ),
          ),
        Positioned(
          bottom: 30.0,
          left: 16.0,
          right: 16.0,
          child: ElevatedButton(
            onPressed: isRecording ? stopVideoRecording : startVideoRecording,
            child: Text(isRecording ? 'Recording' : 'Start Recording'),
          ),
        ),
        Positioned(
          bottom: 10.0,
          left: 16.0,
          right: 16.0,
          child: Consumer<PathProvider>(
            builder: (context, pathProvider, child) {
              return Text(
                'Recording Path: ${pathProvider.videoPath}',
                style: TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ],
    );
  }
}
