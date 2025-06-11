/*
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class RecordVideoButton extends StatelessWidget {
  const RecordVideoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        // Navigate to the camera screen
        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        }
      },
      icon: const Icon(Icons.videocam, color: Colors.white),
      label: const Text(
        'Record a Video',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key}); // Converted `key` to a super parameter

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
    );

    await _controller?.initialize();
    if (mounted) {
      setState(() {}); // Refresh the UI after camera initialization
    }
  }

  void _startRecording() async {
    if (_controller != null && !_isRecording) {
      await _controller?.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    }
  }

  void _stopRecording() async {
    if (_controller != null && _isRecording) {
      await _controller?.stopVideoRecording();
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
        Navigator.pop(context); // Return to previous screen after stopping
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
      ),
      body: _controller != null && _controller!.value.isInitialized
          ? Column(
              children: [
                Expanded(
                  child: CameraPreview(_controller!),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                    child: Text(_isRecording
                        ? 'Stop Recording'
                        : 'Start Recording'), // `child` moved to the end
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
*/