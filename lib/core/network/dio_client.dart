import 'package:dio/dio.dart'; // لاستخدام Dio ومكوناته
import 'package:flutter/foundation.dart'; // لاستخدام kDebugMode للتحقق من وضع التشغيل
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // <-- استيراد التخزين الآمن

//--------------------------------------------------
// كلاس لإعداد وإدارة نسخة Dio واحدة للتطبيق
// يوفر إعدادات أساسية مثل الرابط الأساسي ومهلة الاتصال
// ويمكن إضافة Interceptors هنا للمصادقة أو التسجيل
//--------------------------------------------------
class DioClient {
  // جعل الـ Constructor خاصًا لمنع إنشاء نسخ متعددة من الخارج
  DioClient._();

  // إنشاء نسخة واحدة ثابتة (Singleton) من Dio
  static final Dio _dio = _createDioInstance();

  // دالة لإنشاء وتهيئة نسخة Dio
  static Dio _createDioInstance() {
    final dio = Dio(
      BaseOptions(
        // --- الرابط الأساسي للـ API ---
        baseUrl: 'http://aspiq.runasp.net/api', // <--- تأكدي أن هذا هو الرابط الصحيح

        // --- مهلة الاتصال والاستقبال ---
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),

        // --- Headers افتراضية ---
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
      ),
    );

    // --- إضافة Interceptors ---

    // 1. LogInterceptor (للتشخيص في وضع الـ Debug)
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (object) { debugPrint(object.toString()); },
      ));
      print("DioClient: LogInterceptor added."); // طباعة للتأكيد
    }

    // 2. Auth Interceptor (لإضافة التوكن تلقائيًا)
    //    (تم إلغاء التعليق لتفعيله)
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print("--- Auth Interceptor: Intercepting request for ${options.path} ---");
          // استثناء مسارات المصادقة
          if (!options.path.contains('/auth/')) {
             // جلب التوكن المخزن
             String? token = await getTokenFromStorage(); // استدعاء الدالة المساعدة
             print("--- Auth Interceptor: Token read from storage: ${token != null ? 'Found' : 'Not Found'} ---");

             if (token != null && token.isNotEmpty) {
               print("--- Auth Interceptor: Adding Auth Token ---");
               options.headers['Authorization'] = 'Bearer $token'; // إضافة الهيدر
             } else {
                print("--- Auth Interceptor: No Auth Token Found ---");
             }
          } else {
              print("--- Auth Interceptor: Skipping token for Auth path ---");
          }
          // المتابعة في إرسال الطلب
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // لا يوجد إجراء محدد على الاستجابة حاليًا
           print("--- Auth Interceptor: Received response for ${response.requestOptions.path} ---");
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // التعامل مع الأخطاء (مثال: تجديد التوكن - معلق حاليًا)
           print("--- Auth Interceptor: Error Occurred for ${e.requestOptions.path}: ${e.message} ---");
          // if (e.response?.statusCode == 401) {
          //   // ... (منطق تجديد التوكن) ...
          // }
          return handler.next(e); // تمرير الخطأ
        },
      ),
    );
    print("DioClient: Auth Interceptor added."); // طباعة للتأكيد

    return dio;
  }

  // --- Getter عام للوصول إلى نسخة Dio الوحيدة ---
  static Dio get instance => _dio;

  // --- دالة مساعدة لجلب التوكن من التخزين الآمن ---
  static Future<String?> getTokenFromStorage() async {
    // --- استخدام final بدلاً من const ---
    final storage = FlutterSecureStorage();
    // ----------------------------------
    try {
      // القراءة باستخدام المفتاح الصحيح
      final token = await storage.read(key: 'user_token'); // <-- تأكدي أن هذا هو نفس المفتاح المستخدم للحفظ
      print("--- getTokenFromStorage: Read token: ${token != null ? 'Found' : 'Not Found'} ---");
      return token;
    } catch (e) {
      // التعامل مع أي خطأ قد يحدث أثناء القراءة
      print("--- getTokenFromStorage: Error reading token: $e ---");
      return null; // إرجاع null في حالة الخطأ
    }
 }

  // --- دوال تجديد التوكن وإعادة المحاولة (تبقى معلقة كأمثلة) ---
  // static Future<bool> refreshToken() async { ... }
  // static Future<Response<dynamic>> _retry(RequestOptions requestOptions) async { ... }

}