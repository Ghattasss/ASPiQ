import 'package:dartz/dartz.dart'; // لاستخدام Either لمعالجة النجاح أو الفشل
import 'package:equatable/equatable.dart'; // لاستخدام Equatable في NoParams

// --- استيراد Failure ---
// تأكد من أن المسار صحيح بالنسبة لموقع ملف usecase.dart
import '../errors/failures.dart';

//--------------------------------------------------
// الكلاس المجرد الأساسي لجميع حالات الاستخدام (Use Cases)
// يحدد "عقد" موحد لكيفية استدعاء وتنفيذ حالة استخدام.
// Type: نوع البيانات التي يعيدها الـ UseCase عند النجاح.
// Params: نوع الكائن الذي يحتوي على المعاملات (Parameters) اللازمة لتنفيذ الـ UseCase.
//--------------------------------------------------
abstract class UseCase<Type, Params> {
  /// الدالة الرئيسية التي يتم استدعاؤها لتنفيذ حالة الاستخدام.
  /// تأخذ المعاملات (Params) وتعيد Future يحتوي على:
  /// - إما Failure (في حالة الخطأ - Left).
  /// - أو Type (النتيجة الناجحة - Right).
  Future<Either<Failure, Type>> call(Params params);
}

//--------------------------------------------------
// كلاس مساعد يُستخدم كـ Params لحالات الاستخدام
// التي لا تتطلب أي معاملات إدخال.
// يرث من Equatable لتسهيل المقارنة والاختبار.
//--------------------------------------------------
class NoParams extends Equatable {
  // بما أنه لا توجد خصائص، فقائمة props تكون فارغة.
  @override
  List<Object?> get props => [];
}

// يمكنك إضافة أنواع Params أخرى مشتركة هنا إذا أردت،
// على سبيل المثال، كلاس لمعاملات تتطلب فقط ID:
// class IdParams extends Equatable {
//   final int id;
//   const IdParams({required this.id});
//   @override
//   List<Object?> get props => [id];
// }