import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

void main() {
  // تحميل الصورة الأصلية
  final File originalImageFile = File('/home/ubuntu/ansar_app/design/logo/enhanced_logo.png');
  final List<int> originalImageBytes = originalImageFile.readAsBytesSync();
  final img.Image? originalImage = img.decodeImage(originalImageBytes);
  
  if (originalImage == null) {
    print('فشل في تحميل الصورة الأصلية');
    return;
  }
  
  // إنشاء مجلد للأيقونات
  final Directory iconsDir = Directory('/home/ubuntu/ansar_app/src/flutter_app/android/app/src/main/res');
  if (!iconsDir.existsSync()) {
    iconsDir.createSync(recursive: true);
  }
  
  // إنشاء أيقونات بأحجام مختلفة للأندرويد
  final Map<String, int> androidSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  
  // إنشاء أيقونات التطبيق
  for (final entry in androidSizes.entries) {
    final String folderName = entry.key;
    final int size = entry.value;
    
    // إنشاء مجلد للأيقونة
    final Directory iconDir = Directory('${iconsDir.path}/$folderName');
    if (!iconDir.existsSync()) {
      iconDir.createSync(recursive: true);
    }
    
    // إنشاء أيقونة مربعة
    final img.Image resizedIcon = img.copyResize(
      originalImage,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );
    
    // حفظ الأيقونة
    File('${iconDir.path}/ic_launcher.png').writeAsBytesSync(img.encodePng(resizedIcon));
    
    // إنشاء أيقونة دائرية
    final img.Image roundIcon = img.copyResize(
      originalImage,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );
    
    // حفظ الأيقونة الدائرية
    File('${iconDir.path}/ic_launcher_round.png').writeAsBytesSync(img.encodePng(roundIcon));
    
    print('تم إنشاء أيقونات $folderName بحجم ${size}x${size}');
  }
  
  // إنشاء أيقونة الإشعارات
  final Map<String, int> notificationSizes = {
    'drawable-mdpi': 24,
    'drawable-hdpi': 36,
    'drawable-xhdpi': 48,
    'drawable-xxhdpi': 72,
    'drawable-xxxhdpi': 96,
  };
  
  // إنشاء أيقونات الإشعارات
  for (final entry in notificationSizes.entries) {
    final String folderName = entry.key;
    final int size = entry.value;
    
    // إنشاء مجلد للأيقونة
    final Directory iconDir = Directory('${iconsDir.path}/$folderName');
    if (!iconDir.existsSync()) {
      iconDir.createSync(recursive: true);
    }
    
    // إنشاء أيقونة الإشعارات
    final img.Image notificationIcon = img.copyResize(
      originalImage,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );
    
    // حفظ أيقونة الإشعارات
    File('${iconDir.path}/ic_notification.png').writeAsBytesSync(img.encodePng(notificationIcon));
    
    print('تم إنشاء أيقونة الإشعارات $folderName بحجم ${size}x${size}');
  }
  
  print('تم إنشاء جميع الأيقونات بنجاح');
}
