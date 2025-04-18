from PIL import Image, ImageDraw, ImageFont
import os

# مسار الشعار الأصلي
original_logo_path = '/home/ubuntu/ansar_app/design/logo/original_logo.jpg'
# مسار حفظ الشعار المحسن
enhanced_logo_path = '/home/ubuntu/ansar_app/design/logo/enhanced_logo.png'
# مسار حفظ أيقونة التطبيق
app_icon_path = '/home/ubuntu/ansar_app/design/logo/app_icon.png'

# فتح الصورة الأصلية
original_logo = Image.open(original_logo_path)

# إنشاء صورة جديدة بخلفية شفافة للشعار المحسن
enhanced_logo = Image.new('RGBA', original_logo.size, (0, 0, 0, 0))

# نسخ الشعار الأصلي إلى الصورة الجديدة
enhanced_logo.paste(original_logo, (0, 0))

# حفظ الشعار المحسن
enhanced_logo.save(enhanced_logo_path)

# إنشاء أيقونة التطبيق (مربعة)
icon_size = 512
app_icon = Image.new('RGBA', (icon_size, icon_size), (255, 255, 255, 0))

# تحجيم الشعار ليناسب الأيقونة
logo_resized = original_logo.resize((int(icon_size * 0.8), int(icon_size * 0.8)))

# حساب موضع الشعار في وسط الأيقونة
x_offset = (icon_size - logo_resized.width) // 2
y_offset = (icon_size - logo_resized.height) // 2

# وضع الشعار في وسط الأيقونة
app_icon.paste(logo_resized, (x_offset, y_offset))

# حفظ أيقونة التطبيق
app_icon.save(app_icon_path)

print(f"تم حفظ الشعار المحسن في: {enhanced_logo_path}")
print(f"تم حفظ أيقونة التطبيق في: {app_icon_path}")
