/*import 'dart:convert';
import 'dart:io';
import 'dart:math'; // Add this import for min function
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

/// This widget represents a scan button that allows the user to scan images
/// and get results in real-time.
class ScanButton extends StatelessWidget {
  const ScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _startLiveScan(context),
      icon: const Icon(Icons.camera, color: Colors.white),
      label: const Text(
        'Live Scan',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  void _startLiveScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LiveScanScreen()),
    );
  }
}

/// Screen for live scanning of rocks
class LiveScanScreen extends StatefulWidget {
  const LiveScanScreen({super.key});

  @override
  LiveScanScreenState createState() => LiveScanScreenState();
}

class LiveScanScreenState extends State<LiveScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  late List<CameraDescription> cameras;
  String language = 'en'; // Default language
  
  // Store multiple detection results
  List<DetectionResult> detectionResults = [];
  
  // For continuous processing
  bool _isProcessingFrame = false;
  bool _isCameraInitialized = false;
  
  // For smooth frame capture
  int _frameCount = 0;
  final int _processEveryNFrames = 1; // Process every frame instead of every 3rd
  
  // For API request management
  final List<Future> _pendingRequests = [];
  final int _maxConcurrentRequests = 4; // Increase concurrent requests limit

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to properly manage camera resources
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Initialize camera
      cameras = await availableCameras();
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      
      if (_controller!.value.isInitialized) {
        // Set flash mode to off
        await _controller!.setFlashMode(FlashMode.off);
        
        // Start image stream for continuous frame processing
        await _controller!.startImageStream(_processImageStream);
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _processImageStream(CameraImage image) async {
    _frameCount++;
    
    // Only process every Nth frame to reduce load
    if (_frameCount % _processEveryNFrames != 0) return;
    
    // Skip if already processing or too many pending requests
    if (_isProcessingFrame || _pendingRequests.length >= _maxConcurrentRequests) return;
    
    _isProcessingFrame = true;
    
    try {
      // Pause the image stream while taking a picture
      await _controller?.stopImageStream();
      
      // Take a picture instead of using the image stream directly
      final XFile picture = await _controller!.takePicture();
      
      // Process the image in a separate isolate or thread if possible
      final request = _processImageFile(picture.path);
      _pendingRequests.add(request);
      
      print('Sending image to API: ${picture.path}');
      
      // Restart the image stream before processing to avoid long camera pauses
      try {
        await _controller?.startImageStream(_processImageStream);
      } catch (e) {
        print('Error restarting image stream: $e');
        // Try to reinitialize camera if stream fails
        _initializeCamera();
      }
      
      request.then((_) {
        _pendingRequests.remove(request);
        print('API request completed successfully');
      }).catchError((e) {
        print('Error processing image: $e');
        _pendingRequests.remove(request);
      });
      
    } catch (e) {
      print('Error capturing image: $e');
      // Make sure to restart the stream if there was an error
      try {
        await _controller?.startImageStream(_processImageStream);
      } catch (e) {
        print('Error restarting image stream after error: $e');
        _initializeCamera();
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _processImageFile(String imagePath) async {
    try {
      final result = await _sendImageToAPI(imagePath);
      
      // Delete the temporary file to free up space immediately
      try {
        await File(imagePath).delete();
      } catch (e) {
        print('Error deleting temporary file: $e');
      }
      
      if (result != null && mounted) {
        print('Received API response: ${result.toString().substring(0, min(100, result.toString().length))}...');
        
        // Use a try-catch block when parsing the response
        try {
          final parsedResults = _parseDetections(result);
          
          if (mounted) {
            setState(() {
              detectionResults = parsedResults;
              print('Parsed ${detectionResults.length} detection results');
            });
          }
        } catch (e) {
          print('Error parsing detection results: $e');
          // Don't update state if parsing fails
        }
      } else {
        print('API returned null result');
      }
    } catch (e) {
      print('Error processing image file: $e');
    }
  }

  List<DetectionResult> _parseDetections(Map<String, dynamic> apiResponse) {
    List<DetectionResult> results = [];
    
    try {
      // Check if the API returned multiple detections
      if (apiResponse.containsKey('detections') && apiResponse['detections'] is List) {
        List<dynamic> detections = apiResponse['detections'];
        
        for (var detection in detections) {
          try {
            results.add(DetectionResult(
              label: language == 'en' 
                  ? detection['english_label'] ?? detection['label'] 
                  : detection['arabic_label'] ?? detection['label'],
              englishLabel: detection['english_label'] ?? detection['label'],
              arabicLabel: detection['arabic_label'] ?? detection['label'],
              confidence: detection['confidence'] ?? '',
              boundingBox: detection['bounding_box'] != null 
                  ? BoundingBox.fromJson(detection['bounding_box']) 
                  : null,
            ));
          } catch (e) {
            print('Error parsing individual detection: $e');
            // Continue to next detection
          }
        }
      } 
      // Fallback for single detection (for backward compatibility)
      else if (apiResponse.containsKey('result')) {
        results.add(DetectionResult(
          label: language == 'en' 
              ? apiResponse['english_result'] ?? apiResponse['result'] 
              : apiResponse['arabic_result'] ?? apiResponse['result'],
          englishLabel: apiResponse['english_result'] ?? apiResponse['result'],
          arabicLabel: apiResponse['arabic_result'] ?? apiResponse['result'],
          confidence: apiResponse['confidence'] ?? '',
          boundingBox: null, // No bounding box for single detection
        ));
      }
    } catch (e) {
      print('Error in _parseDetections: $e');
    }
    
    return results;
  }

  // Update this to your current API server IP address
  final String apiUrl = 'http://192.168.1.4:5000/predict';
  
  Future<Map<String, dynamic>?> _sendImageToAPI(String imagePath) async {
    try {
      final uri = Uri.parse(apiUrl);
      final imageFile = File(imagePath);
      
      // Check if file exists before reading
      if (!await imageFile.exists()) {
        print('Error: Image file does not exist: $imagePath');
        return null;
      }
      
      final imageBytes = await imageFile.readAsBytes();
      
      // Check if image is too large (over 10MB)
      if (imageBytes.length > 10 * 1024 * 1024) {
        print('Warning: Image is very large (${imageBytes.length} bytes), may cause memory issues');
        // Consider resizing the image here
      }
      
      final imageBase64 = base64Encode(imageBytes);

      print('Sending image of size: ${imageBytes.length} bytes to API');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': imageBase64,
          'language': language
        }),
      ).timeout(const Duration(seconds: 15)); // Increase timeout

      if (response.statusCode == 200) {
        print('API response received successfully');
        try {
          return jsonDecode(response.body);
        } catch (e) {
          print('Error decoding JSON response: $e');
          return null;
        }
      } else {
        print('API Error: ${response.statusCode}, Body: ${response.body.substring(0, min(100, response.body.length))}...');
        return null;
      }
    } catch (e) {
      print('Error sending image to API: $e');
      return null;
    }
  }

  void _toggleLanguage() {
    setState(() {
      language = language == 'en' ? 'ar' : 'en';
      // Update labels based on new language
      for (var result in detectionResults) {
        result.label = language == 'en' ? result.englishLabel : result.arabicLabel;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(language == 'en' ? 'Live Scan' : 'المسح المباشر'),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(language == 'en' ? 'Live Scan' : 'المسح المباشر'),
        actions: [
          // Add language toggle button in app bar
          IconButton(
            icon: Icon(language == 'en' ? Icons.language : Icons.translate),
            onPressed: _toggleLanguage,
            tooltip: language == 'en' ? 'Switch to Arabic' : 'تغيير إلى الإنجليزية',
          ),
          // Add a counter for active requests (for debugging)
          if (_pendingRequests.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isProcessingFrame ? Colors.orange : Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${_pendingRequests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isProcessingFrame)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview with detection boxes (takes most of the screen)
          Expanded(
            flex: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview
                CameraPreview(_controller!),
                
                // Overlay for detection boxes
                CustomPaint(
                  painter: DetectionBoxPainter(
                    detectionResults: detectionResults,
                    language: language,
                  ),
                  size: Size.infinite,
                ),
              ],
            ),
          ),
          
          // Results panel at the bottom
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.black.withOpacity(0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    language == 'en' ? 'Detection Results:' : 'نتائج الكشف:',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: detectionResults.isEmpty
                    ? Center(
                        child: Text(
                          language == 'en' ? 'No rocks detected yet' : 'لم يتم اكتشاف أحجار بعد',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: detectionResults.length,
                        itemBuilder: (context, index) {
                          final result = detectionResults[index];
                          return Card(
                            color: Colors.green.withOpacity(0.8),
                            margin: const EdgeInsets.all(4),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    result.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    result.confidence,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Class to represent a detection result
class DetectionResult {
  String label;
  final String englishLabel;
  final String arabicLabel;
  final String confidence;
  final BoundingBox? boundingBox;
  
  DetectionResult({
    required this.label,
    required this.englishLabel,
    required this.arabicLabel,
    required this.confidence,
    this.boundingBox,
  });
}

/// Class to represent a bounding box
class BoundingBox {
  final double x;      // x coordinate of top-left corner (normalized 0-1)
  final double y;      // y coordinate of top-left corner (normalized 0-1)
  final double width;  // width of box (normalized 0-1)
  final double height; // height of box (normalized 0-1)
  
  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
  
  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }
  
  // Convert normalized coordinates to actual pixel coordinates
  Rect toPixelRect(Size size) {
    return Rect.fromLTWH(
      x * size.width,
      y * size.height,
      width * size.width,
      height * size.height,
    );
  }
}

/// Custom painter to draw detection boxes and labels
class DetectionBoxPainter extends CustomPainter {
  final List<DetectionResult> detectionResults;
  final String language;
  
  DetectionBoxPainter({
    required this.detectionResults,
    required this.language,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
      
    final Paint bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    for (var result in detectionResults) {
      if (result.boundingBox != null) {
        // Convert normalized coordinates to pixel coordinates
        final Rect rect = result.boundingBox!.toPixelRect(size);
        
        // Draw bounding box
        canvas.drawRect(rect, boxPaint);
        
        // Prepare text
        final textSpan = TextSpan(
          text: '${result.label} (${result.confidence})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        );
        
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        
        textPainter.layout(minWidth: 0, maxWidth: rect.width);
        
        // Draw text background
        final textRect = Rect.fromLTWH(
          rect.left,
          rect.top - textPainter.height - 4,
          textPainter.width + 8,
          textPainter.height + 4,
        );
        
        canvas.drawRect(textRect, bgPaint);
        
        // Draw text
        textPainter.paint(
          canvas,
          Offset(rect.left + 4, rect.top - textPainter.height - 2),
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint on frame update
  }
}

/// Main application entry point.
void main() {
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Rock Detection'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: ScanButton(),
        ),
      ),
    );
  }
}

class QuickScanButton extends StatelessWidget {
  const QuickScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _startQuickScan(context),
      icon: const Icon(Icons.document_scanner, color: Colors.white),
      label: const Text(
        'Quick Scan',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Future<void> _startQuickScan(BuildContext context) async {
    // Request camera permission
    var status = await Permission.camera.status;
    if (status.isDenied || status.isRestricted || status.isLimited) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuickScanScreen()),
        );
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
    }
  }
}

class QuickScanScreen extends StatefulWidget {
  const QuickScanScreen({super.key});

  @override
  QuickScanScreenState createState() => QuickScanScreenState();
}

class QuickScanScreenState extends State<QuickScanScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  String? _imagePath;
  String? _resultImagePath;
  String? _prediction;
  String? _englishResult;
  String? _confidence;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {});
        // Take picture immediately after camera is initialized
        _takePictureAndProcess();
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _takePictureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile picture = await _controller!.takePicture();
      _imagePath = picture.path;
      
      // Send to API immediately
      await _sendImageToAPI(picture.path);
    } catch (e) {
      print('Error taking picture: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _sendImageToAPI(String imagePath) async {
    try {
      final uri = Uri.parse('http://192.168.1.4:5000/predict');
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final imageBase64 = base64Encode(imageBytes);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': imageBase64,
          'language': _language
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        setState(() {
          _prediction = responseData['result'];
          _englishResult = responseData['english_result'] ?? _prediction;
          _confidence = responseData['confidence'] ?? '';
          
          // Handle result_image if it exists
          if (responseData.containsKey('result_image') && 
              responseData['result_image'] != null) {
            try {
              // Decode base64 image and save to temporary file
              final bytes = base64Decode(responseData['result_image']);
              final tempDir = Directory.systemTemp.createTempSync();
              final resultImageFile = File('${tempDir.path}/result_image.jpg');
              resultImageFile.writeAsBytesSync(bytes);
              _resultImagePath = resultImageFile.path;
            } catch (e) {
              print('Error saving result image: $e');
            }
          }
        });
      } else {
        print('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending image to API: $e');
    }
  }

  void _toggleLanguage() {
    setState(() {
      _language = _language == 'en' ? 'ar' : 'en';
    });
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
        title: Text(_language == 'en' ? 'Quick Scan' : 'مسح سريع'),
        actions: [
          IconButton(
            icon: Icon(_language == 'en' ? Icons.language : Icons.language),
            onPressed: _toggleLanguage,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing image...'),
          ],
        ),
      );
    }

    // Show results if available
    if (_resultImagePath != null || _prediction != null) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Show processed image if available
            if (_resultImagePath != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.file(File(_resultImagePath!)),
              )
            // Otherwise show original image
            else if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.file(File(_imagePath!)),
              ),
              
            // Show prediction results
            if (_prediction != null)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _language == 'en' ? 'Prediction:' : 'التنبؤ:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _language == 'en' ? _englishResult! : _prediction!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _language == 'en' ? 'Confidence:' : 'الثقة:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _confidence ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              
            // Scan again button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _takePictureAndProcess,
                icon: const Icon(Icons.refresh),
                label: Text(_language == 'en' ? 'Scan Again' : 'مسح مرة أخرى'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show camera preview if no results yet
    return Column(
      children: [
        Expanded(
          child: CameraPreview(_controller!),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Taking picture automatically...',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}*/




















