@echo off
echo ===== تنظيف ذاكرة التخزين المؤقت لـ Gradle =====
echo.

cd %USERPROFILE%\.gradle
echo حذف ملفات الذاكرة المؤقتة لـ Gradle...
rmdir /S /Q caches
mkdir caches
echo تم حذف ملفات الذاكرة المؤقتة بنجاح.
echo.

echo العودة إلى مجلد المشروع...
cd /d %~dp0
echo.

echo تنظيف المشروع...
call flutter clean
cd android
call gradlew clean
cd ..
echo.

echo تم الانتهاء من تنظيف ذاكرة التخزين المؤقت لـ Gradle.
echo يمكنك الآن تشغيل المشروع باستخدام أمر flutter run
echo.
pause
