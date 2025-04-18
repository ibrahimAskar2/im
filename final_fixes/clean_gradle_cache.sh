#!/bin/bash

echo "===== تنظيف ذاكرة التخزين المؤقت لـ Gradle ====="
echo ""

cd ~/.gradle
echo "حذف ملفات الذاكرة المؤقتة لـ Gradle..."
rm -rf caches
mkdir -p caches
echo "تم حذف ملفات الذاكرة المؤقتة بنجاح."
echo ""

echo "العودة إلى مجلد المشروع..."
cd - > /dev/null
echo ""

echo "تنظيف المشروع..."
flutter clean
cd android
./gradlew clean
cd ..
echo ""

echo "تم الانتهاء من تنظيف ذاكرة التخزين المؤقت لـ Gradle."
echo "يمكنك الآن تشغيل المشروع باستخدام أمر flutter run"
echo ""
read -p "اضغط Enter للخروج..."
