import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'media_helper.dart';

// إضافة معلومات الصخور
class RockInfo {
  final String name;
  final String color;
  final String chemicalComposition;
  final String hardness;
  final String density;

  RockInfo({
    required this.name,
    required this.color,
    required this.chemicalComposition,
    required this.hardness,
    required this.density,
  });
}

// قاموس يحتوي على معلومات الصخور
final Map<String, RockInfo> rockInfoDatabase = {
  'Baryte': RockInfo(
    name: 'Baryte',
    color: 'White, Yellow, Brown, Gray, or Colorless',
    chemicalComposition: 'BaSO₄ (Barium Sulfate)',
    hardness: '3-3.5 on Mohs scale',
    density: '4.3-5.0 g/cm³',
  ),
  'Calcite': RockInfo(
    name: 'Calcite',
    color: 'Colorless, White, or Various Colors',
    chemicalComposition: 'CaCO₃ (Calcium Carbonate)',
    hardness: '3 on Mohs scale',
    density: '2.71 g/cm³',
  ),
  'Fluorite': RockInfo(
    name: 'Fluorite',
    color: 'Purple, Blue, Green, Yellow, Colorless, Pink, or Red',
    chemicalComposition: 'CaF₂ (Calcium Fluoride)',
    hardness: '4 on Mohs scale',
    density: '3.18 g/cm³',
  ),
  'Pyrite': RockInfo(
    name: 'Pyrite',
    color: 'Pale Brass-Yellow',
    chemicalComposition: 'FeS₂ (Iron Disulfide)',
    hardness: '6-6.5 on Mohs scale',
    density: '5.01 g/cm³',
  ),
  // النسخة العربية
  'باريت': RockInfo(
    name: 'باريت',
    color: 'أبيض، أصفر، بني، رمادي، أو عديم اللون',
    chemicalComposition: 'BaSO₄ (كبريتات الباريوم)',
    hardness: '3-3.5 على مقياس موس',
    density: '4.3-5.0 جم/سم³',
  ),
  'كالسيت': RockInfo(
    name: 'كالسيت',
    color: 'عديم اللون، أبيض، أو ألوان متنوعة',
    chemicalComposition: 'CaCO₃ (كربونات الكالسيوم)',
    hardness: '3 على مقياس موس',
    density: '2.71 جم/سم³',
  ),
  'فلوريت': RockInfo(
    name: 'فلوريت',
    color: 'بنفسجي، أزرق، أخضر، أصفر، عديم اللون، وردي، أو أحمر',
    chemicalComposition: 'CaF₂ (فلوريد الكالسيوم)',
    hardness: '4 على مقياس موس',
    density: '3.18 جم/سم³',
  ),
  'بايرايت': RockInfo(
    name: 'بايرايت',
    color: 'أصفر نحاسي شاحب',
    chemicalComposition: 'FeS₂ (ثاني كبريتيد الحديد)',
    hardness: '6-6.5 على مقياس موس',
    density: '5.01 جم/سم³',
  ),
};

class TakePhotoOrVideoButton extends StatefulWidget {
  const TakePhotoOrVideoButton({super.key});

  @override
  TakePhotoOrVideoButtonState createState() => TakePhotoOrVideoButtonState();
}

class TakePhotoOrVideoButtonState extends State<TakePhotoOrVideoButton> {
  String? prediction;
  String? confidence;
  String? englishResult;
  String? arabicResult;
  String language = 'en'; // Default language
  String? lastImagePath; // Store the last image path
  bool isLoading = false;

  Future<void> _handleAction(String action) async {
    // Request permission to use the camera
    var status = await Permission.camera.status;
    if (status.isDenied || status.isRestricted || status.isLimited) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      setState(() {
        isLoading = true;
      });
      
      // Only handle photo capture
      final image = await pickImageFromCamera();
      
      setState(() {
        isLoading = false;
      });
      
      if (image != null) {
        lastImagePath = image.path; // Store the path
        await _detectImageClass(image.path);
      }
    } else if (status.isPermanentlyDenied) {
      // Open app settings if permission is permanently denied
      openAppSettings();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language == 'en' 
                ? 'Camera permission is required to take pictures' 
                : 'إذن الكاميرا مطلوب لالتقاط الصور'
          ),
        ),
      );
    }
  }

  Future<void> _detectImageClass(String imagePath) async {
    setState(() {
      isLoading = true;
    });
    
    final result = await _sendImageToAPI(imagePath);
    
    setState(() {
      isLoading = false;
      if (result != null) {
        prediction = result['result'];
        confidence = result['confidence'];
        englishResult = result['english_result'] ?? prediction;
        arabicResult = result['arabic_result'] ?? prediction;
      } else {
        prediction = language == 'en' ? 'No class detected' : 'لم يتم التعرف على الصنف';
        confidence = null;
        englishResult = 'No class detected';
        arabicResult = 'لم يتم التعرف على الصنف';
      }
    });
    
    _showResultDialog();
  }

  Future<Map<String, String>?> _sendImageToAPI(String imagePath) async {
    try {
      final uri = Uri.parse('http://192.168.1.4:5000/predict'); // Update with your Flask server IP
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final imageBase64 = base64Encode(imageBytes);

      // Send as JSON with language parameter
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': imageBase64,
          'language': language
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'result': responseData['result'],
          'confidence': responseData['confidence'] ?? '',
          'english_result': responseData['english_result'] ?? '',
          'arabic_result': responseData['arabic_result'] ?? '',
        };
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error sending image: $e');
      return null;
    }
  }

  void _showOptionsDialog() {
    // Take photo directly without showing options dialog
    _handleAction('Photo');
  }

  // إضافة دالة لعرض معلومات الصخر
  void _showRockInfo() {
    // الحصول على اسم الصخر بالإنجليزية للبحث في قاعدة البيانات
    final rockName = englishResult;
    
    // التحقق من وجود معلومات للصخر
    if (rockName == null || rockName == 'No class detected' || !rockInfoDatabase.containsKey(rockName)) {
      // عرض رسالة إذا لم يتم العثور على معلومات
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language == 'en' 
                ? 'No information available for this rock' 
                : 'لا توجد معلومات متاحة لهذا الصخر'
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // الحصول على معلومات الصخر
    final rockInfo = rockInfoDatabase[rockName]!;
    
    // عرض المعلومات في نافذة منبثقة
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              language == 'en' ? 'Rock Information' : 'معلومات الصخر',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    language == 'en' ? 'Name' : 'الاسم',
                    prediction ?? '',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    language == 'en' ? 'Color' : 'اللون',
                    language == 'en' ? rockInfo.color : rockInfoDatabase[prediction]?.color ?? rockInfo.color,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    language == 'en' ? 'Chemical Composition' : 'التركيب الكيميائي',
                    language == 'en' ? rockInfo.chemicalComposition : rockInfoDatabase[prediction]?.chemicalComposition ?? rockInfo.chemicalComposition,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    language == 'en' ? 'Hardness' : 'الصلابة',
                    language == 'en' ? rockInfo.hardness : rockInfoDatabase[prediction]?.hardness ?? rockInfo.hardness,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    language == 'en' ? 'Density' : 'الكثافة',
                    language == 'en' ? rockInfo.density : rockInfoDatabase[prediction]?.density ?? rockInfo.density,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(language == 'en' ? 'Close' : 'إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // دالة مساعدة لبناء صف معلومات
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDialog() {
    // Display the prediction result in a dialog with improved UI
    showDialog(
      context: context,
      builder: (context) {
        final isRTL = language == 'ar';
        
        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              isRTL ? 'نتيجة التحليل' : 'Prediction Result',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lastImagePath != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(lastImagePath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Prediction result
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isRTL ? 'النتيجة: ' : 'Result: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                prediction ?? (isRTL ? 'لم يتم التعرف' : 'No class detected'),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        if (confidence != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                isRTL ? 'الثقة: ' : 'Confidence: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                confidence!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Rock info button
                  if (englishResult != null && 
                      englishResult != 'No class detected' && 
                      rockInfoDatabase.containsKey(englishResult))
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _showRockInfo,
                        icon: const Icon(Icons.info_outline),
                        label: Text(
                          isRTL ? 'معلومات الصخر' : 'Rock Information',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Language toggle
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          language = language == 'en' ? 'ar' : 'en';
                          // Update prediction based on language
                          prediction = language == 'en' ? englishResult : arabicResult;
                        });
                        Navigator.of(context).pop();
                        _showResultDialog(); // Reopen dialog with new language
                      },
                      icon: Icon(isRTL ? Icons.language : Icons.translate),
                      label: Text(
                        isRTL ? 'تغيير إلى الإنجليزية' : 'Switch to Arabic',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(isRTL ? 'إغلاق' : 'Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showOptionsDialog(); // Take another photo
                },
                child: Text(isRTL ? 'التقاط صورة أخرى' : 'Take Another Photo'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : _showOptionsDialog,
      icon: isLoading 
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            )
          : const Icon(Icons.camera_alt, color: Colors.white),
      label: Text(
        language == 'en' ? 'Take a Photo' : 'التقاط صورة',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}  
