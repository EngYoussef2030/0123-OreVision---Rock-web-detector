import 'package:image_picker/image_picker.dart';

// دالة لاختيار الصورة
Future<XFile?> pickImageFromCamera() async {
  final picker = ImagePicker();
  return await picker.pickImage(source: ImageSource.camera);
}

// دالة لاختيار صورة من الجاليري
Future<XFile?> pickImageFromGallery() async {
  final picker = ImagePicker();
  return await picker.pickImage(source: ImageSource.gallery);
}

// دالة لاختيار الفيديو
Future<XFile?> pickVideoFromCamera() async {
  final picker = ImagePicker();
  return await picker.pickVideo(source: ImageSource.camera);
}
