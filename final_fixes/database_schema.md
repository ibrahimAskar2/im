# مخطط قاعدة البيانات لتطبيق فريق الأنصار

## جداول قاعدة البيانات

### 1. جدول المستخدمين (Users)
```
users {
  uid: string (المعرف الفريد للمستخدم)
  name: string (اسم المستخدم)
  email: string (البريد الإلكتروني)
  phone: string (رقم الهاتف)
  role: string (الدور: admin/employee)
  profileImage: string (رابط صورة الملف الشخصي)
  lastActive: timestamp (آخر نشاط)
  fcmToken: string (رمز إشعارات Firebase)
  createdAt: timestamp (تاريخ الإنشاء)
  additionalInfo: map (معلومات إضافية)
}
```

### 2. جدول الحضور (Attendance)
```
attendance {
  id: string (معرف فريد)
  userId: string (معرف المستخدم)
  date: string (التاريخ)
  checkInTime: timestamp (وقت تسجيل الدخول)
  checkOutTime: timestamp (وقت تسجيل الخروج)
  status: string (الحالة: present/absent/late)
  notes: string (ملاحظات)
}
```

### 3. جدول المحادثات (Chats)
```
chats {
  id: string (معرف فريد)
  type: string (نوع المحادثة: individual/group)
  name: string (اسم المجموعة - للمحادثات الجماعية فقط)
  participants: array<string> (معرفات المشاركين)
  createdAt: timestamp (تاريخ الإنشاء)
  createdBy: string (معرف المنشئ)
  lastMessage: string (آخر رسالة)
  lastMessageTime: timestamp (وقت آخر رسالة)
}
```

### 4. جدول الرسائل (Messages)
```
messages {
  id: string (معرف فريد)
  chatId: string (معرف المحادثة)
  senderId: string (معرف المرسل)
  content: string (محتوى الرسالة)
  contentType: string (نوع المحتوى: text/image/voice)
  mediaUrl: string (رابط الوسائط - للصور والصوت)
  timestamp: timestamp (وقت الإرسال)
  readBy: array<string> (معرفات من قرأوا الرسالة)
  deliveredTo: array<string> (معرفات من وصلتهم الرسالة)
}
```

### 5. جدول الإشعارات (Notifications)
```
notifications {
  id: string (معرف فريد)
  type: string (نوع الإشعار)
  title: string (عنوان الإشعار)
  body: string (محتوى الإشعار)
  senderId: string (معرف المرسل)
  receiverId: string (معرف المستلم، "all" للإشعارات العامة)
  timestamp: timestamp (وقت الإرسال)
  isRead: boolean (حالة القراءة)
}
```

### 6. جدول الإعدادات (Settings)
```
settings {
  id: string (معرف فريد)
  userId: string (معرف المستخدم)
  darkMode: boolean (وضع الظلام)
  language: string (اللغة)
  notificationsEnabled: boolean (تفعيل الإشعارات)
  lastUpdated: timestamp (آخر تحديث)
}
```

## العلاقات بين الجداول

1. **المستخدمين والحضور**: علاقة واحد إلى متعدد (one-to-many)
   - كل مستخدم له سجلات حضور متعددة

2. **المستخدمين والمحادثات**: علاقة متعدد إلى متعدد (many-to-many)
   - كل مستخدم يمكن أن يشارك في عدة محادثات
   - كل محادثة يمكن أن تضم عدة مستخدمين

3. **المحادثات والرسائل**: علاقة واحد إلى متعدد (one-to-many)
   - كل محادثة تحتوي على عدة رسائل

4. **المستخدمين والإشعارات**: علاقة واحد إلى متعدد (one-to-many)
   - كل مستخدم يمكن أن يرسل أو يستقبل عدة إشعارات

5. **المستخدمين والإعدادات**: علاقة واحد إلى واحد (one-to-one)
   - كل مستخدم له إعدادات خاصة به

## مخطط تدفق البيانات

1. **تسجيل الدخول والخروج**:
   - المستخدم يسجل الدخول -> تحديث جدول المستخدمين (lastActive) -> إنشاء سجل في جدول الحضور -> إرسال إشعار عام

2. **نظام الدردشة**:
   - إرسال رسالة -> إضافة إلى جدول الرسائل -> تحديث جدول المحادثات (lastMessage, lastMessageTime) -> إرسال إشعار للمستلمين

3. **لوحة المعلومات**:
   - استعلام من جدول الحضور لعرض المتواجدين حالياً وعدد الغياب والموظف المميز

4. **إحصائيات الدوام**:
   - استعلام من جدول الحضور مع تصفية حسب الفترة الزمنية (يوم/أسبوع/شهر/سنة)
