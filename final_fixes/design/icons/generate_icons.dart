import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

void main() async {
  // تأكد من تهيئة Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // الحصول على مسار المجلد المؤقت
  final directory = await getTemporaryDirectory();
  final outputPath = '${directory.path}/icons';
  
  // إنشاء مجلد للأيقونات إذا لم يكن موجوداً
  final outputDir = Directory(outputPath);
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }
  
  // تحميل الصورة الأصلية
  final originalImage = File('/home/ubuntu/ansar_app/design/logo/enhanced_logo.png');
  final image = img.decodeImage(originalImage.readAsBytesSync())!;
  
  // إنشاء أيقونات بأحجام مختلفة للأندرويد
  final androidSizes = [
    {'size': 48, 'name': 'mdpi'},
    {'size': 72, 'name': 'hdpi'},
    {'size': 96, 'name': 'xhdpi'},
    {'size': 144, 'name': 'xxhdpi'},
    {'size': 192, 'name': 'xxxhdpi'},
  ];
  
  for (var size in androidSizes) {
    final resizedImage = img.copyResize(
      image,
      width: size['size'] as int,
      height: size['size'] as int,
      interpolation: img.Interpolation.average,
    );
    
    final iconFile = File('$outputPath/ic_launcher_${size['name']}.png');
    iconFile.writeAsBytesSync(img.encodePng(resizedImage));
    print('تم إنشاء أيقونة ${size['name']} بحجم ${size['size']}x${size['size']}');
  }
  
  // إنشاء أيقونة التطبيق الرئيسية
  final launcherIcon = img.copyResize(
    image,
    width: 512,
    height: 512,
    interpolation: img.Interpolation.average,
  );
  
  final launcherIconFile = File('$outputPath/ic_launcher.png');
  launcherIconFile.writeAsBytesSync(img.encodePng(launcherIcon));
  print('تم إنشاء أيقونة التطبيق الرئيسية بحجم 512x512');
  
  // إنشاء أيقونة الإشعارات
  final notificationIcon = img.copyResize(
    image,
    width: 24,
    height: 24,
    interpolation: img.Interpolation.average,
  );
  
  final notificationIconFile = File('$outputPath/ic_notification.png');
  notificationIconFile.writeAsBytesSync(img.encodePng(notificationIcon));
  print('تم إنشاء أيقونة الإشعارات بحجم 24x24');
  
  print('تم إنشاء جميع الأيقونات بنجاح في المجلد: $outputPath');
}
