import 'dart:io';
import 'package:flutter/material.dart';

class ImageDetailsPage extends StatelessWidget {
  final String imagePath;
  final String rockName;
  final String rockDescription;

  const ImageDetailsPage({
    super.key,
    required this.imagePath,
    required this.rockName,
    required this.rockDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rock Details'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Image.file(
            File(imagePath),
            height: 300,
          ),
          const SizedBox(height: 20),
          Text(
            rockName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              rockDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
