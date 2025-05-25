// الملف: lib/core/errors/exceptions.dart

/// Exception عام يُستخدم للإشارة إلى وجود خطأ من جانب الخادم (Server-Side).
/// يُلقى عادةً من الـ RemoteDataSource عندما يرد الـ API بحالة خطأ (4xx, 5xx)
/// أو عند حدوث مشكلة في تحليل الاستجابة.
class ServerException implements Exception {
  /// رسالة تصف الخطأ، قد تأتي من الـ API أو تكون رسالة افتراضية.
  final String message;

  /// Constructor لإنشاء ServerException مع رسالة.
  const ServerException(this.message);

  @override
  String toString() {
    return 'ServerException: $message';
  }
}

/// Exception يُستخدم للإشارة إلى وجود خطأ أثناء التعامل مع التخزين المؤقت المحلي (Local Cache).
/// يُلقى عادةً من الـ LocalDataSource عند فشل قراءة أو كتابة البيانات من/إلى التخزين المحلي.
class CacheException implements Exception {
   /// رسالة اختيارية لوصف سبب فشل الـ Cache.
  final String? message;

  const CacheException([this.message]); // جعل الرسالة اختيارية

   @override
  String toString() {
    return message != null ? 'CacheException: $message' : 'CacheException';
  }
}


/// Exception يُستخدم للإشارة إلى عدم وجود اتصال بالشبكة عند محاولة إجراء طلب.
/// يمكن للـ NetworkInfo أو الـ Repository إلقاء هذا قبل محاولة استدعاء الـ DataSource.
class OfflineException implements Exception {
   final String message = "لا يوجد اتصال بالانترنت"; // رسالة ثابتة أو مخصصة

   @override
  String toString() {
    return message;
  }
}


// يمكنك إضافة أنواع Exceptions مخصصة أخرى هنا حسب الحاجة، مثل:
// class AuthenticationException implements Exception { ... } // لخطأ المصادقة 401/403
// class TimeoutException implements Exception { ... } // لانتهاء مهلة الطلب
// class InvalidCredentialsException extends ServerException { ... } // نوع خاص من خطأ الخادم