
import 'package:flutter/material.dart';
import 'Take_Photo_Video.dart'; // تحديث اسم الملف

//import 'scan.dart';
import 'upload_image_video.dart';

void main() {
  runApp(const RockDetectedApp());
}

class RockDetectedApp extends StatelessWidget {
  const RockDetectedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RockDetectedHomePage(),
    );
  }
}

class RockDetectedHomePage extends StatelessWidget {
  const RockDetectedHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Untitled-1.png',
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              'Rock Detected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            const TakePhotoOrVideoButton(), // استخدام الـ Widget الجديد
            const SizedBox(height: 10),

            const SizedBox(height: 10),
            const UploadImageVideoButton(),
            const SizedBox(height: 10),
           // const ScanButton(),
          ],
        ),
      ),
    );
  }
}
