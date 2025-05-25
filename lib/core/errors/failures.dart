// lib/core/errors/failures.dart
import 'package:equatable/equatable.dart'; // لاستخدام Equatable لتبسيط مقارنة الكائنات

//--------------------------------------------------
// الكلاس المجرد الأساسي لجميع أنواع الفشل (Failures)
// الـ UI Layer ستتعامل مع هذا النوع أو الأنواع المشتقة منه.
//--------------------------------------------------
abstract class Failure extends Equatable {
  // رسالة الخطأ التي يمكن عرضها للمستخدم أو تسجيلها
  final String message;

  // Constructor يتطلب رسالة الخطأ
  const Failure(this.message);

  // --- استخدام Equatable ---
  // نضع الخصائص التي نريد المقارنة على أساسها هنا
  // في هذه الحالة، رسالة الخطأ هي الخاصية المميزة
  @override
  List<Object> get props => [message];

// يمكنك إضافة خصائص أخرى مشتركة بين أنواع الفشل هنا إذا أردت
// مثلاً: final int? statusCode;
}

//--------------------------------------------------
// أنواع الفشل المحددة (Specific Failure Types)
// يمكنك إنشاء كلاسات مشتقة لتمييز أنواع الأخطاء المختلفة
// مما يسمح للـ UI بعرض رسائل أو سلوكيات مختلفة لكل نوع.
//--------------------------------------------------

/// يُستخدم عندما يحدث خطأ أثناء التواصل مع الخادم (API).
/// مثل أخطاء 5xx أو أخطاء تحليل رد الخادم.
class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
// يمكنك إضافة تفاصيل أخرى خاصة بأخطاء الخادم هنا إذا أردت، مثل statusCode
// final int? statusCode;
// const ServerFailure(String message, {this.statusCode}) : super(message);
// @override List<Object> get props => [message, statusCode ?? 0];
}

/// يُستخدم عندما يكون هناك خطأ من جانب العميل قبل أو أثناء إرسال الطلب.
/// مثل توكن مفقود، بيانات إدخال غير صالحة للـ API، أو أخطاء 4xx معينة.
class ClientFailure extends Failure {
  const ClientFailure(String message) : super(message);
}

/// يُستخدم عندما يحدث خطأ أثناء التعامل مع التخزين المحلي (مثل SharedPreferences).
class LocalFailure extends Failure {
  const LocalFailure(String message) : super(message);
}

/// يُستخدم عندما لا يتم العثور على المورد المطلوب (مثل خطأ 404 من الـ API).
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message);
}

/// يُستخدم عندما يحدث خطأ أثناء التعامل مع التخزين المؤقت المحلي (Cache).
/// (تم الاحتفاظ به من الكود الأصلي)
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

/// يُستخدم عندما لا يكون هناك اتصال بالشبكة (مثل SocketException).
/// (تم الاحتفاظ به من الكود الأصلي)
class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

/// يُستخدم عندما تكون البيانات المدخلة من المستخدم غير صالحة قبل إرسالها.
/// (تم الاحتفاظ به من الكود الأصلي - قد لا تحتاج إليه إذا كنت تعالج التحقق في مكان آخر)
class InvalidInputFailure extends Failure {
  const InvalidInputFailure(String message) : super(message);
}

// يمكنك إضافة أي أنواع أخرى تحتاجها هنا، مثل:
// class AuthenticationFailure extends Failure { ... }
// class PermissionFailure extends Failure { ... }