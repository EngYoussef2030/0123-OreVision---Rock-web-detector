import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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

class UploadImageVideoButton extends StatefulWidget {
  const UploadImageVideoButton({super.key});

  @override
  UploadImageVideoButtonState createState() => UploadImageVideoButtonState();
}

class UploadImageVideoButtonState extends State<UploadImageVideoButton> {
  String? prediction;
  String? confidence;
  String language = 'en'; // Default language

  // Pick image from the gallery
  Future<XFile?> pickImageFromGallery() async {
    final picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.gallery);
  }

  Future<void> _pickImageFromGallery() async {
    final image = await pickImageFromGallery();

    if (mounted && image != null) {
      // Don't send to API immediately, just show the image
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaDetailsPage(
              imagePath: image.path,
              onUploadNewImage: _pickImageFromGallery,
              detectClass: _sendImageToAPI, // Pass function reference
              initialLanguage: language, // Pass current language
            ),
          ),
        );
      }
    }
  }

  Future<Map<String, String>?> _sendImageToAPI(String imagePath, [String? lang]) async {
    try {
      final uri = Uri.parse('http://192.168.1.4:5000/predict');
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final imageBase64 = base64Encode(imageBytes);

      // Send as JSON with language parameter
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': imageBase64,
          'language': lang ?? language
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'result': responseData['result'],
          'confidence': responseData['confidence'] ?? '',
          'english_result': responseData['english_result'] ?? '',
          'arabic_result': responseData['arabic_result'] ?? '',
          'result_image': responseData['result_image'],
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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _pickImageFromGallery,
      icon: const Icon(Icons.photo_library, color: Colors.white),
      label: const Text(
        'Upload Media',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}

class MediaDetailsPage extends StatefulWidget {
  final String imagePath;
  final String? initialPrediction;
  final String? initialConfidence;
  final String? initialEnglishResult;
  final String? initialArabicResult;
  final String? initialResultImage;
  final VoidCallback onUploadNewImage;
  final Future<Map<String, String>?> Function(String imagePath, [String? language]) detectClass;
  final String initialLanguage;

  const MediaDetailsPage({
    super.key,
    required this.imagePath,
    required this.onUploadNewImage,
    required this.detectClass,
    this.initialPrediction,
    this.initialConfidence,
    this.initialEnglishResult,
    this.initialArabicResult,
    this.initialResultImage,
    this.initialLanguage = 'en',
  });

  @override
  _MediaDetailsPageState createState() => _MediaDetailsPageState();
}

class _MediaDetailsPageState extends State<MediaDetailsPage> {
  String? prediction;
  String? confidence;
  String? englishResult;
  String? arabicResult;
  String? resultImage;
  String language = 'en'; // Default language
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    prediction = widget.initialPrediction;
    confidence = widget.initialConfidence;
    englishResult = widget.initialEnglishResult;
    arabicResult = widget.initialArabicResult;
    resultImage = widget.initialResultImage;
    language = widget.initialLanguage; // Initialize with passed language
  }

  Future<void> _detectClass() async {
    setState(() {
      isLoading = true;
    });
    
    // Pass language parameter to the API call
    final result = await widget.detectClass(widget.imagePath, language);

    setState(() {
      isLoading = false;
      if (result != null) {
        prediction = result['result'];
        confidence = result['confidence'];
        englishResult = result['english_result'];
        arabicResult = result['arabic_result'];
        resultImage = result['result_image'];
      } else {
        prediction = language == 'en' ? 'No class detected' : 'لم يتم التعرف على الصنف';
        confidence = null;
        englishResult = 'No class detected';
        arabicResult = 'لم يتم التعرف على الصنف';
        resultImage = null;
      }
    });
  }

  void _toggleLanguage() {
    setState(() {
      language = language == 'en' ? 'ar' : 'en';
      // Update prediction based on language
      prediction = language == 'en' ? englishResult : arabicResult;
    });
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

  @override
  Widget build(BuildContext context) {
    final isRTL = language == 'ar';
    
    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isRTL ? 'تفاصيل الصورة' : 'Media Details'),
          actions: [
            // Add language toggle button to app bar
            IconButton(
              icon: Icon(isRTL ? Icons.language : Icons.translate),
              onPressed: _toggleLanguage,
              tooltip: isRTL ? 'تغيير إلى الإنجليزية' : 'Switch to Arabic',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Show annotated image if available, otherwise show original image
              resultImage != null
                  ? Image.memory(
                      base64Decode(resultImage!),
                      height: 300,
                      fit: BoxFit.contain,
                    )
                  : Image.file(
                      File(widget.imagePath),
                      height: 300,
                      fit: BoxFit.cover,
                    ),
              const SizedBox(height: 20),
              
              // Results container
              if (prediction != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Prediction row
                      Row(
                        mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          Text(
                            isRTL ? 'التنبؤ: ' : 'Prediction: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              prediction ?? '',
                              style: const TextStyle(fontSize: 16),
                              textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // Confidence row
                      if (confidence != null)
                        Row(
                          mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Text(
                              isRTL ? 'الثقة: ' : 'Confidence: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              confidence ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      
                      // إضافة زر معلومات الصخر
                      const SizedBox(height: 15),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: englishResult != null && 
                                     englishResult != 'No class detected' && 
                                     englishResult != 'Image not recognized' 
                              ? _showRockInfo 
                              : null,
                          icon: const Icon(Icons.info_outline),
                          label: Text(
                            isRTL ? 'معلومات الصخر' : 'Rock Information',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: widget.onUploadNewImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(
                      isRTL ? 'تحميل صورة أخرى' : 'Upload Another',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _detectClass,
                    icon: isLoading 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Icon(Icons.search),
                    label: Text(
                      isRTL ? 'كشف الفئة' : 'Detect Class',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
