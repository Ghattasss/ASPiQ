import 'dart:async'; // لاستخدام TimeoutException
import 'dart:convert';
import 'dart:developer';
import 'dart:io'; // لـ File و SocketException

import 'package:dartz/dartz.dart'; // <--- تأكد من استيراد dartz
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // لـ debugPrint
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // لـ MediaType
// --- !!! تأكد من أن هذا الملف يحتوي تعريف Failure وكلاساتها الفرعية !!! ---
import 'package:myfinalpro/core/errors/failures.dart'; // <--- استيراد كلاسات الأخطاء
import 'package:myfinalpro/core/serveses/shared_preferance_servace.dart'; // <--- تأكد من اسم الملف والمسار
import 'package:myfinalpro/models/test_dto.dart';
import 'package:myfinalpro/session/models/session_model.dart';
import 'package:myfinalpro/test/models/quiz_model.dart';
import 'package:myfinalpro/test3months/test_group_model.dart';

import '../monthly_test/monthly_test_response.dart';
import 'package:myfinalpro/models/answer_model.dart';

class ApiService {
  final Dio _dio;
  static const String baseUrl = 'http://aspiq.runasp.net/api';

  ApiService() : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (object) => log(object.toString()),
    ));
  }

  // --- الدوال الـ static (تستخدم http وتُرجع Map) ---
  // [loginUser, registerUser, addDoctor, sendOtp, verifyOtp, verifyEmailOtp, resetPassword, getUserProfile, updateUserProfile, uploadProfilePicture, classifyAnswerWithModel, submitAssessmentAnswer, getNextPendingSession, completeDetail, fetchNextTestDetail, markTestDetailComplete, updateSessionDone, getTestsByType]
  // ... (الكود الخاص بالدوال الـ static يبقى كما هو في الرد السابق) ...

  // ========================================================================
  // دوال غير static تستخدم _dio ومعالجة الأخطاء الموحدة (باستخدام Either)
  // ========================================================================

  Future<Either<Failure, MonthlyTestResponse>> getMonthlyTestDetails() async {
    String? token;
    try {
      token = await SharedPreferenceServices.getToken("auth_token") as String?;
      if (token == null || token.isEmpty) {
        log("ApiService getMonthlyTestDetails: Token not found.");
        // --- !!! التصحيح هنا: استخدام Left(...) !!! ---
        return Left(ClientFailure("Token not found. Please login again."));
      }
    } catch (e) {
      log("ApiService getMonthlyTestDetails: Error fetching token: $e");
      // --- !!! التصحيح هنا: استخدام Left(...) !!! ---
      return Left(LocalFailure("Error fetching token: ${e.toString()}"));
    }

    const String endpoint = '/TestController/next-test-detail-month';
    log("ApiService (instance): GET $baseUrl$endpoint");

    try {
      final response = await _dio.get(
        endpoint,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      log("ApiService getMonthlyTestDetails response status: ${response.statusCode}");

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data is Map<String, dynamic>) {
        try {
          final testData = MonthlyTestResponse.fromJson(
              response.data as Map<String, dynamic>);
          return Right(testData); // <--- النجاح
        } catch (e, s) {
          log("Error parsing monthly test JSON: $e\n$s");
          // --- !!! التصحيح هنا: استخدام Left(...) !!! ---
          return Left(
              ServerFailure("خطأ في تنسيق بيانات الاختبار الشهري المستلمة."));
        }
      } else if (response.statusCode == 404) {
        log("ApiService getMonthlyTestDetails: No monthly test found (404).");
        // --- !!! التصحيح هنا: استخدام Left(...) !!! ---
        return Left(NotFoundFailure("لا يوجد اختبار شهري متاح حاليًا."));
      } else {
        String errorMessage = _parseDioErrorMessage(response);
        log("ApiService: Failed to fetch monthly test. Status: ${response.statusCode}, Message: $errorMessage");
        // --- !!! التصحيح هنا: استخدام Left(...) !!! ---
        return Left(ServerFailure(errorMessage));
      }
    } on DioException catch (e) {
      log("ApiService DioException for monthly test: ${e.message}");
      // --- !!! التصحيح هنا: استخدام Left(...) !!! ---
      return Left(ServerFailure(_handleDioError(e)));
    } catch (e, s) {
      log("ApiService Unknown Exception for monthly test: $e\n$s");
      // --- !!! التصحيح هنا: استخدام Left(...) !!! ---
      return Left(
          ServerFailure("حدث خطأ غير متوقع أثناء جلب الاختبار الشهري."));
    }
  }

  Future<Either<Failure, bool>> markSessionDone(int sessionId) async {
    String? token;
    try {
      token = await SharedPreferenceServices.getToken("auth_token") as String?;
      if (token == null || token.isEmpty) {
        log("ApiService markSessionDone: Token not found.");
        // --- !!! التصحيح هنا: استخدام Left(...) !!! ---
        return Left(ClientFailure("Token not found. Please login again."));
      }
    } catch (e) {
      log("ApiService markSessionDone: Error fetching token: $e");
      // --- !!! التصحيح هنا: استخدام Left(...) !!! ---
      return Left(LocalFailure("Error fetching token: ${e.toString()}"));
    }

    final String endpoint = '/SessionController/update-session-done/$sessionId';
    log("ApiService (instance): PUT $baseUrl$endpoint");

    try {
      final response = await _dio.put(
        endpoint,
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
      log("ApiService markSessionDone response status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return Right(true); // <--- النجاح
      } else {
        String errorMessage = _parseDioErrorMessage(response);
        log("ApiService: Failed to mark session $sessionId as done. Status: ${response.statusCode}, Message: $errorMessage");
        // --- !!! التصحيح هنا: استخدام Left(...) !!! ---
        return Left(ServerFailure(errorMessage));
      }
    } on DioException catch (e) {
      log("ApiService DioException for markSessionDone $sessionId: ${e.message}");
      // --- !!! التصحيح هنا: استخدام Left(...) !!! ---
      return Left(ServerFailure(_handleDioError(e)));
    } catch (e, s) {
      log("ApiService Unknown Exception for markSessionDone $sessionId: $e\n$s");
      // --- !!! التصحيح هنا: استخدام Left(...) !!! ---
      return Left(ServerFailure("حدث خطأ غير متوقع أثناء تحديث حالة الجلسة."));
    }
  }

  // --- دوال مساعدة لمعالجة أخطاء Dio (تبقى كما هي) ---
  String _parseDioErrorMessage(Response? response) {
    String defaultMessage = 'فشل الطلب (رمز: ${response?.statusCode})';
    if (response?.data == null) return defaultMessage;
    if (response!.data is Map) {
      return (response.data['message'] as String?) ??
          (response.data['title'] as String?) ??
          defaultMessage;
    } else if (response.data is String &&
        (response.data as String).isNotEmpty) {
      return response.data as String;
    }
    return defaultMessage;
  }

  String _handleDioError(DioException e) {
    String errorMessage;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = "انتهت مهلة الاتصال بالخادم، يرجى المحاولة مرة أخرى.";
        break;
      case DioExceptionType.badResponse:
        errorMessage = _parseDioErrorMessage(e.response);
        break;
      case DioExceptionType.cancel:
        errorMessage = "تم إلغاء طلب الاتصال.";
        break;
      case DioExceptionType.connectionError:
        errorMessage = "فشل الاتصال بالخادم، تحقق من اتصالك بالإنترنت.";
        break;
      case DioExceptionType.badCertificate:
        errorMessage = "خطأ في شهادة الأمان للخادم.";
        break;
      case DioExceptionType.unknown:
      default:
        if (e.error is SocketException)
          errorMessage = "خطأ في الشبكة، تحقق من اتصالك بالإنترنت.";
        else
          errorMessage =
              "حدث خطأ غير معروف في الشبكة: ${e.message ?? e.error?.toString() ?? ''}";
        break;
    }
    if (e.response?.statusCode != null)
      errorMessage += " (رمز: ${e.response!.statusCode})";
    return errorMessage;
  }

  // --- باقي الدوال الـ static من الرد السابق ---
  // [loginUser, registerUser, addDoctor, sendOtp, verifyOtp, verifyEmailOtp, resetPassword, getUserProfile, updateUserProfile, uploadProfilePicture, classifyAnswerWithModel, submitAssessmentAnswer, getNextPendingSession, completeDetail, fetchNextTestDetail, markTestDetailComplete, updateSessionDone, getTestsByType]
  static Future<Map<String, dynamic>> getTestsByType(
      String token, int typeId) async {
    final url = Uri.parse('$baseUrl/Test/GetTestByType/$typeId');
    log("ApiService: Fetching tests for typeId: $typeId");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      log("ApiService: GetTestsByType/$typeId Status Code: ${response.statusCode}");
      if (response.statusCode == 200) {
        try {
          final List<TestDto> tests = testDtoListFromJson(response.body);
          log("ApiService: Successfully fetched ${tests.length} tests for typeId: $typeId");
          return {'success': true, 'tests': tests};
        } catch (e) {
          log("ApiService: Error parsing GetTestsByType/$typeId response as List<TestDto>: $e. Trying '\$values'...");
          try {
            final decodedBody = utf8.decode(response.bodyBytes);
            final responseData = jsonDecode(decodedBody);
            if (responseData is Map<String, dynamic> &&
                responseData.containsKey('\$values') &&
                responseData['\$values'] is List) {
              final List<dynamic> rawList = responseData['\$values'];
              final List<TestDto> tests = rawList
                  .map((item) => TestDto.fromJson(item as Map<String, dynamic>))
                  .toList();
              log("ApiService: Successfully parsed ${tests.length} tests from '\$values' for typeId: $typeId");
              return {'success': true, 'tests': tests};
            } else {
              log("ApiService: Response format is neither List<TestDto> nor contains '\$values'. Body: $decodedBody");
              return {
                'success': false,
                'message': 'خطأ في تنسيق بيانات الاختبارات المستلمة.'
              };
            }
          } catch (e2) {
            log("ApiService: Further error parsing GetTestsByType/$typeId response: $e2");
            return {
              'success': false,
              'message': 'خطأ في تحليل بيانات الاختبارات المستلمة.'
            };
          }
        }
      } else if (response.statusCode == 401) {
        log("ApiService: GetTestsByType/$typeId Unauthorized (401).");
        return {
          'success': false,
          'unauthorized': true,
          'message': 'غير مصرح لك بالوصول.'
        };
      } else if (response.statusCode == 404) {
        log("ApiService: GetTestsByType/$typeId Not Found (404).");
        return {'success': true, 'tests': <TestDto>[]};
      } else {
        log("ApiService: GetTestsByType/$typeId failed with status: ${response.statusCode}");
        String errorMessage =
            'فشل تحميل الاختبارات (رمز: ${response.statusCode})';
        try {
          /* Extract error */
        } catch (_) {}
        return {'success': false, 'message': errorMessage};
      }
    } on TimeoutException catch (_) {
      log("ApiService: GetTestsByType/$typeId request timed out.");
      return {'success': false, 'message': 'انتهت مهلة طلب تحميل الاختبارات.'};
    } on SocketException catch (e) {
      log("ApiService: GetTestsByType/$typeId network error: $e");
      return {'success': false, 'message': 'خطأ في الشبكة.'};
    } catch (e, s) {
      log("ApiService: Exception during GetTestsByType/$typeId: $e\n$s");
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع أثناء تحميل الاختبارات.'
      };
    }
  }

  static Future<bool> updateSessionDone(int sessionId, String jwtToken) async {
    final url =
        Uri.parse('$baseUrl/SessionController/update-session-done/$sessionId');
    print("Calling PUT $url");
    try {
      final response =
          await http.put(url, headers: {'Authorization': 'Bearer $jwtToken'});
      print("UpdateSessionDone Status: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error updating session done: $e");
      return false;
    }
  }

  static Future<bool> markTestDetailComplete(
      String token, int testDetailId) async {
    if (testDetailId <= 0) {
      debugPrint(
          "[ApiService.markTestDetailComplete] Error: Invalid testDetailId ($testDetailId). Aborting.");
      return false;
    }
    final url =
        Uri.parse('$baseUrl/TestController/test-detail/$testDetailId/complete');
    debugPrint('[ApiService.markTestDetailComplete] Calling: POST $url');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': '*/*'
            },
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 15));
      debugPrint(
          '[ApiService.markTestDetailComplete] Status for ID $testDetailId: ${response.statusCode}');
      bool success = response.statusCode == 200 || response.statusCode == 204;
      if (!success)
        debugPrint(
            '[ApiService.markTestDetailComplete] Failed. Status: ${response.statusCode}, Body: ${response.body}');
      return success;
    } on TimeoutException catch (e) {
      debugPrint(
          '[ApiService.markTestDetailComplete] Timeout Error for ID $testDetailId: $e');
      return false;
    } on SocketException catch (e) {
      debugPrint(
          '[ApiService.markTestDetailComplete] Network Error for ID $testDetailId: $e');
      return false;
    } catch (e) {
      debugPrint(
          '[ApiService.markTestDetailComplete] Unexpected Error for ID $testDetailId: $e');
      return false;
    }
  }

  static Future<QuizSession?> fetchNextTestDetail(String token) async {
    final url = Uri.parse('$baseUrl/TestController/next-test-detail-Session');
    debugPrint('[ApiService.fetchNextTestDetail] Calling: GET $url');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      ).timeout(const Duration(seconds: 20));
      debugPrint(
          '[ApiService.fetchNextTestDetail] Status: ${response.statusCode}');
      debugPrint(
          '[ApiService.fetchNextTestDetail] Response Body: ${response.body}');
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is Map<String, dynamic>) {
            debugPrint(
                '[ApiService.fetchNextTestDetail] Success. Parsing JSON...');
            return QuizSession.fromJson(data);
          } else if (data == null || (data is List && data.isEmpty)) {
            debugPrint(
                '[ApiService.fetchNextTestDetail] Received null or empty list.');
            return null;
          } else {
            debugPrint(
                '[ApiService.fetchNextTestDetail] Error: Unexpected JSON structure: ${data.runtimeType}');
            return null;
          }
        } catch (e) {
          debugPrint('[ApiService.fetchNextTestDetail] JSON Parsing Error: $e');
          return null;
        }
      } else if (response.statusCode == 404) {
        debugPrint(
            '[ApiService.fetchNextTestDetail] No pending test found (404).');
        return null;
      } else if (response.statusCode == 401) {
        debugPrint('[ApiService.fetchNextTestDetail] Unauthorized (401).');
        throw Exception('Unauthorized');
      } else {
        debugPrint(
            '[ApiService.fetchNextTestDetail] Server Error ${response.statusCode}. Body: ${response.body}');
        throw Exception(
            'Failed to load quiz details (Status: ${response.statusCode})');
      }
    } on TimeoutException catch (e) {
      debugPrint('[ApiService.fetchNextTestDetail] Timeout Error: $e');
      throw Exception('Request timed out while fetching quiz details.');
    } on SocketException catch (e) {
      debugPrint('[ApiService.fetchNextTestDetail] Network Error: $e');
      throw Exception('Network error while fetching quiz details.');
    } catch (e) {
      debugPrint('[ApiService.fetchNextTestDetail] Unexpected Error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  static Future<bool> completeDetail(String token, int detailId) async {
    if (detailId <= 0) {
      print(
          "[ApiService.completeDetail] Error: Invalid detailId ($detailId). Aborting.");
      return false;
    }
    final url =
        Uri.parse('$baseUrl/SessionController/detail/$detailId/complete');
    print('[ApiService.completeDetail] Calling: POST $url');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': '*/*'
            },
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 15));
      print(
          '[ApiService.completeDetail] Status Code for ID $detailId: ${response.statusCode}');
      bool success = response.statusCode == 200 || response.statusCode == 204;
      if (!success)
        print(
            '[ApiService.completeDetail] Failed. Status: ${response.statusCode}, Body: ${response.body}');
      return success;
    } on TimeoutException catch (e) {
      print('[ApiService.completeDetail] Timeout for ID $detailId: $e');
      return false;
    } on SocketException catch (e) {
      print('[ApiService.completeDetail] Network Error for ID $detailId: $e');
      return false;
    } on http.ClientException catch (e) {
      print('[ApiService.completeDetail] Client Error for ID $detailId: $e');
      return false;
    } catch (e) {
      print(
          '[ApiService.completeDetail] Unexpected Error for ID $detailId: $e');
      return false;
    }
  }

static Future<Session?> getNextPendingSession(String token) async {
  final url = Uri.parse('$baseUrl/SessionController/next-pending');
  print('[ApiService.getNextPendingSession] Calling: GET $url');
  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      },
    ).timeout(const Duration(seconds: 20));
    print('[ApiService.getNextPendingSession] Status Code: ${response.statusCode}');
    print('[ApiService.getNextPendingSession] Response Body: ${response.body}'); // مهم جداً

    if (response.statusCode == 200) {
      try {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);

        // --- بداية التحليل المهم ---
        if (data != null && data is Map<String, dynamic>) {
          // تحقق إذا كانت هذه رسالة خاصة بالاختبار بدلاً من جلسة كاملة
          // هذا هو الافتراض بناءً على صور استجابتك
          if (data.containsKey('message') &&
              !data.containsKey('details') && // جلسة كاملة عادة ما تحتوي 'details'
              !data.containsKey('newDetail')) { // جلسة كاملة عادة ما تحتوي 'newDetail'

            String message = data['message'] as String? ?? '';
            print('[ApiService.getNextPendingSession] Detected a special message: $message');

            // --- هنا يجب أن تقرر كيف ستتعامل مع هذه الرسالة ---
            // الخيار 1: إنشاء كائن Session مبسط يحمل هذه الرسالة في attributes
            // هذا يتطلب أن يكون Session.fromJson قادرًا على التعامل مع هذا.
            Map<String, dynamic> sessionLikeMessage = {
              "id": data['sessionId'] as int? ?? 0, // أو قيمة مناسبة إذا لم يكن sessionId موجودًا
              "title": "رسالة نظام", // أو استخرج العنوان إذا كان موجودًا
              "description": message,
              "goal": "",
              "type": "SYSTEM_MESSAGE", // نوع خاص للإشارة إلى أنها رسالة
              "groupId": 0,
              "detailsCount": 0,
              "attributes": { // هنا نضع الرسائل المستخرجة
                if (message.toLowerCase().contains("اختبار الشهر")) "monthly_test_message": message,
                if (message.toLowerCase().contains("اختبار ال 3 شهور")) "three_month_test_message": message,
              },
              "details": {"\$values": []}, // قيم فارغة للحقول المتوقعة
              "newDetail": {"\$values": []} // قيم فارغة للحقول المتوقعة
            };
            return Session.fromJson(sessionLikeMessage);

            // الخيار 2: إرجاع null، وجعل HomeScreen يعالج الرسالة بطريقة أخرى
            // (قد يكون هذا معقدًا لأنك ستفقد الرسالة).
            // return null;

            // الخيار 3 (الأفضل إذا أمكن): تعديل الـ API ليكون له endpoints مختلفة.
          }
          // إذا لم تكن رسالة خاصة، افترض أنها بيانات جلسة كاملة
          else if (data.containsKey('details')) { // تحقق من وجود حقل أساسي للجلسة
            print('[ApiService.getNextPendingSession] Successfully fetched full session data.');
            return Session.fromJson(data);
          }
          // إذا لم تكن أيًا مما سبق، فهي بنية غير متوقعة
          else {
            print('[ApiService.getNextPendingSession] Unknown data structure received, but it is a Map.');
            return null;
          }

        } else if (data == null || (data is List && data.isEmpty)) {
          print('[ApiService.getNextPendingSession] Received null or empty list, considering as no pending session.');
          return null;
        } else {
          print('[ApiService.getNextPendingSession] Unexpected data format received: ${data.runtimeType}');
          return null;
        }
      } catch (e) {
        print('[ApiService.getNextPendingSession] JSON Parsing Error: $e. Body was: ${response.body}');
        return null;
      }
    } else if (response.statusCode == 404) {
      print('[ApiService.getNextPendingSession] No pending sessions found (404).');
      return null;
    } else if (response.statusCode == 401) {
      print('[ApiService.getNextPendingSession] Unauthorized (401).');
      throw Exception('Unauthorized'); // سيتم التقاطها في HomeScreen
    } else {
      print('[ApiService.getNextPendingSession] Failed with status: ${response.statusCode}');
      throw Exception('Failed to load next session (Status: ${response.statusCode})'); // سيتم التقاطها في HomeScreen
    }
  } on TimeoutException catch (e) {
    print('[ApiService.getNextPendingSession] Timeout: $e');
    throw Exception('Request timed out'); // سيتم التقاطها في HomeScreen
  } on SocketException catch (e) {
    print('[ApiService.getNextPendingSession] Network Error: $e');
    throw Exception('Network error'); // سيتم التقاطها في HomeScreen
  } on http.ClientException catch (e) {
    print('[ApiService.getNextPendingSession] Client Error: $e');
    throw Exception('Client error'); // سيتم التقاطها في HomeScreen
  } catch (e) {
    print('[ApiService.getNextPendingSession] Unexpected Error: $e');
    throw Exception('Unexpected error'); // سيتم التقاطها في HomeScreen
  }
}
 // --- classifyAnswerWithModel --- (Keep As Is)
  static Future<String?> classifyAnswerWithModel(String rawText) async {
    // ... (existing code) ...
        const String modelPredictEndpoint =
        "https://arabic-response-api-869138074073.us-central1.run.app/predict";
    final url = Uri.parse(modelPredictEndpoint);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    final body = jsonEncode({'text': rawText});
    try {
      print(
          '[ApiService.classifyAnswer] Calling Model API: $modelPredictEndpoint');
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));
      print(
          '[ApiService.classifyAnswer] Model API Status: ${response.statusCode}');
      print(
          '[ApiService.classifyAnswer] Model API Response Headers: ${response.headers}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        String decodedBody;
        try {
          decodedBody = utf8.decode(response.bodyBytes);
          print(
              '[ApiService.classifyAnswer] Body decoded with UTF-8: $decodedBody');
        } catch (e) {
          print(
              '[ApiService.classifyAnswer] Error decoding body with UTF-8, falling back to response.body: $e');
          decodedBody = response.body;
        }
        try {
          final dynamic responseData = jsonDecode(decodedBody);
          if (responseData is Map<String, dynamic>) {
            print(
                '[ApiService.classifyAnswer] Model Response Body (Map): $responseData');
            final dynamic resultValue =
                responseData['prediction']; // <--- تأكد من المفتاح
            if (resultValue != null) {
              final String classificationResult =
                  resultValue.toString().trim().replaceAll('"', '');
              const validResults = ["نعم", "لا", "بمساعدة"];
              if (validResults.contains(classificationResult)) {
                print(
                    '[ApiService.classifyAnswer] Model Classified As: $classificationResult');
                return classificationResult;
              } else {
                print(
                    '[ApiService.classifyAnswer] Error: Unexpected classification value after UTF-8 decode: "$classificationResult"');
                return null;
              }
            } else {
              print(
                  "[ApiService.classifyAnswer] Error: Key 'prediction' not found in response Map after UTF-8 decode.");
              return null;
            }
          } else {
            print(
                '[ApiService.classifyAnswer] Error: Expected a Map response after UTF-8 decode, but got ${responseData.runtimeType}');
            return null;
          }
        } catch (e) {
          print(
              '[ApiService.classifyAnswer] JSON Decode Error after manual UTF-8 decode: $e');
          print('[ApiService.classifyAnswer] Decoded Body was: $decodedBody');
          return null;
        }
      } else {
        print(
            '[ApiService.classifyAnswer] Error: Failed with status ${response.statusCode}. Body: ${response.body}');
        return null;
      }
    } on TimeoutException catch (e) {
      print('[ApiService.classifyAnswer] Error: Request timed out - $e');
      return null;
    } on SocketException catch (e) {
      print('[ApiService.classifyAnswer] Error: Network error - $e');
      return null;
    } on http.ClientException catch (e) {
      print('[ApiService.classifyAnswer] Error: Client error - $e');
      return null;
    } catch (e) {
      print(
          '[ApiService.classifyAnswer] Error: An unexpected error occurred - $e');
      return null;
    }
  }


  // --- دالة جديدة لإرسال جميع الإجابات المجمعة ---
  static Future<bool> submitAllAssessmentAnswers(
      List<AnswerModel> answersToSubmit, // تم تغيير اسم المتغير ليكون أوضح
      String jwtToken
  ) async {
    if (answersToSubmit.isEmpty) {
      print("[ApiService.submitAllAssessmentAnswers] No answers to submit.");
      // يمكنك أن تقرر ما إذا كان هذا يعتبر نجاحًا أم فشلًا.
      // إذا كان من الطبيعي عدم وجود إجابات في بعض الحالات، أرجع true.
      // إذا كان يجب دائمًا وجود إجابات، أرجع false.
      return true;
    }

    // !!! استبدل بالرابط الفعلي لواجهة برمجة تطبيقات الخادم لاستقبال الإجابات المجمعة !!!
    // يجب أن يكون هذا الرابط مختلفًا عن الرابط الذي استخدمته للإرسال الفردي،
    // أو يجب أن يكون الخادم قادرًا على التعامل مع كلتا الحالتين.
    // المثال يفترض أنك تستخدم نفس الرابط ولكن الخادم يتوقع بنية مختلفة للـ payload.
    const String bulkSubmitApiUrl = 'http://aspiq.runasp.net/api/sessioncontroller/submit-answers'; // <<--- غيّر هذا الرابط ليتناسب مع الـ endpoint الجديد
    // أو إذا كان نفس الرابط: 'http://aspiq.runasp.net/api/sessioncontroller/submit-answers'

    print("[ApiService.submitAllAssessmentAnswers] Attempting to submit ${answersToSubmit.length} answers to URL: $bulkSubmitApiUrl");

    try {
      // بناء الـ Payload بالصيغة المطلوبة: { "answers": [ { "SessionId": ..., "Answer": ... }, ... ] }
      Map<String, dynamic> payload = {
        'answers': answersToSubmit.map((answer) => answer.toJson()).toList(),
      };
      String jsonPayload = jsonEncode(payload);

      print("[ApiService.submitAllAssessmentAnswers] Submitting JSON: $jsonPayload");

      final response = await http.post(
        Uri.parse(bulkSubmitApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken', // عدّل هذا إذا كانت طريقة المصادقة مختلفة
        },
        body: jsonPayload,
      ).timeout(const Duration(seconds: 30)); // إضافة مهلة 30 ثانية لعملية الإرسال المجمع

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 200 OK أو 201 Created عادة ما يشيران إلى النجاح
        print('[ApiService.submitAllAssessmentAnswers] Bulk answers submitted successfully. Status: ${response.statusCode}');
        return true;
      } else {
        print('[ApiService.submitAllAssessmentAnswers] Failed to submit bulk answers. Status: ${response.statusCode}');
        print('[ApiService.submitAllAssessmentAnswers] Response body: ${response.body}');
        return false;
      }
    } on TimeoutException catch (e) {
      print("[ApiService.submitAllAssessmentAnswers] Error: Bulk submission API request timed out - $e");
      return false;
    } catch (e) {
      print('[ApiService.submitAllAssessmentAnswers] Error submitting bulk answers: $e');
      return false;
    }
  }

  // --- (اختياري) يمكنك حذف دالة الإرسال الفردي القديمة إذا لم تعد تستخدمها ---
  /*
  static Future<bool> submitAssessmentAnswer(int questionId, String answer, String jwtToken) async {
    const String singleSubmitApiUrl = 'http://aspiq.runasp.net/api/sessioncontroller/submit-answers'; // رابطك القديم
    print("[ApiService.submitAssessmentAnswer] Calling Backend API: $singleSubmitApiUrl for Q:$questionId Ans:\"$answer\"");

    try {
      final response = await http.post(
        Uri.parse(singleSubmitApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
        // هذا هو الـ payload القديم للإرسال الفردي، تأكد من أن الخادم لا يتوقعه إذا كنت تستخدم نفس الرابط للإرسال المجمع
        body: jsonEncode(<String, dynamic>{
          'SessionId': questionId,
          'Answer': answer,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        print("[ApiService.submitAssessmentAnswer] Backend API Status: ${response.statusCode}");
        print("[ApiService.submitAssessmentAnswer] Success: Answer submitted.");
        return true;
      } else {
        print("[ApiService.submitAssessmentAnswer] Error: Backend API Status: ${response.statusCode}");
        print("[ApiService.submitAssessmentAnswer] Body: ${response.body}");
        return false;
      }
    } on TimeoutException catch (e) {
      print("[ApiService.submitAssessmentAnswer] Error: API request timed out - $e");
      return false;
    } catch (e) {
      print("[ApiService.submitAssessmentAnswer] Error: $e");
      return false;
    }
  }
  */
  static Future<Map<String, dynamic>> uploadProfilePicture(
      String? token, File imageFile) async {
    if (token == null || token.isEmpty)
      return {
        'success': false,
        'message': 'Token is required for uploading picture',
        'statusCode': 401
      };
    final url = Uri.parse('$baseUrl/user/update-profile-picture');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    };
    try {
      print(
          "[ApiService.uploadProfilePicture] Sending POST (multipart) request to $url");
      var request = http.MultipartRequest('POST', url)..headers.addAll(headers);
      String fileExtension = imageFile.path.split('.').last.toLowerCase();
      String contentType = 'image/jpeg';
      if (fileExtension == 'png')
        contentType = 'image/png';
      else if (fileExtension == 'gif') contentType = 'image/gif';
      request.files.add(await http.MultipartFile.fromPath(
          'ImageFile', imageFile.path,
          contentType: MediaType.parse(contentType)));
      print(
          "[ApiService.uploadProfilePicture] Sending file: ${imageFile.path} as $contentType");
      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 45));
      var response = await http.Response.fromStream(streamedResponse);
      print(
          '[ApiService.uploadProfilePicture] API Status Code: ${response.statusCode}');
      print(
          '[ApiService.uploadProfilePicture] API Response Body: ${response.body}');
      dynamic responseData;
      String message = 'Failed to parse response';
      String? newImageUrl;
      bool isJson =
          response.headers['content-type']?.contains('application/json') ??
              false;
      try {
        if (response.body.isNotEmpty) {
          if (isJson) {
            responseData = json.decode(response.body);
            message = "Picture uploaded successfully";
            if (responseData is Map<String, dynamic>) {
              message = responseData['message'] ?? message;
              newImageUrl = responseData['imageUrl']?.toString() ??
                  responseData['image_url']?.toString() ??
                  responseData['url']?.toString();
              if (newImageUrl != null)
                print(
                    "[ApiService.uploadProfilePicture] Received new image URL: $newImageUrl");
              else
                print(
                    "[ApiService.uploadProfilePicture] Warning: Success response but no image URL found.");
            }
          } else {
            responseData = {'rawBody': response.body};
            message = response.body;
          }
        } else {
          responseData = {};
          message = (response.statusCode == 200)
              ? 'Picture uploaded successfully (empty body)'
              : 'Failed (Status: ${response.statusCode}, empty body)';
        }
      } catch (e) {
        message = 'Error parsing server response.';
        responseData = {'rawErrorBody': response.body};
      }
      bool success = response.statusCode == 200 && newImageUrl != null;
      if (!success) {
        /* Improve error messages */ newImageUrl = null;
      }
      return {
        'success': success,
        'data': responseData,
        'newImageUrl': newImageUrl,
        'statusCode': response.statusCode,
        'message': message,
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'انتهت مهلة طلب رفع الصورة.',
        'error': e.toString(),
        'statusCode': 408
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الشبكة.',
        'error': e.toString()
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
        'newImageUrl': null
      };
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile(
      String? token, Map<String, dynamic> profileData) async {
    if (token == null || token.isEmpty)
      return {
        'success': false,
        'message': 'Token is required for updating profile',
        'statusCode': 401
      };
    final url = Uri.parse('$baseUrl/user/update-profile');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      print("[ApiService.updateUserProfile] Sending PUT request to $url");
      print("[ApiService.updateUserProfile] Data: ${json.encode(profileData)}");
      final response = await http
          .put(
            url,
            headers: headers,
            body: json.encode(profileData),
          )
          .timeout(const Duration(seconds: 25));
      print(
          '[ApiService.updateUserProfile] API Status Code: ${response.statusCode}');
      print(
          '[ApiService.updateUserProfile] API Response Body: ${response.body}');
      dynamic responseData;
      String message = 'Failed to parse response';
      bool isJson =
          response.headers['content-type']?.contains('application/json') ??
              false;
      try {
        if (response.body.isNotEmpty) {
          if (isJson) {
            responseData = json.decode(response.body);
            if (responseData is Map<String, dynamic>)
              message = responseData['message'] ??
                  responseData['title'] ??
                  'Profile updated successfully';
            else
              message = responseData.toString();
          } else {
            message = response.body;
            responseData = {'rawBody': message};
          }
        } else {
          responseData = {};
          message = (response.statusCode == 200 || response.statusCode == 204)
              ? "تم تحديث الملف الشخصي بنجاح."
              : "Failed to update profile (Status: ${response.statusCode}, Empty body)";
        }
      } catch (e) {
        message = 'Error parsing server response.';
        responseData = {'rawErrorBody': response.body};
      }
      bool success = response.statusCode == 200 || response.statusCode == 204;
      if (!success) {
        /* Improve error messages */
      }
      return {
        'success': success,
        'data': responseData,
        'statusCode': response.statusCode,
        'message': message,
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'انتهت مهلة طلب تحديث الملف الشخصي.',
        'error': e.toString(),
        'statusCode': 408
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الشبكة.',
        'error': e.toString()
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String? token) async {
    if (token == null || token.isEmpty)
      return {
        'success': false,
        'message': 'Token is required for fetching profile',
        'statusCode': 401
      };
    final url = Uri.parse('$baseUrl/user/get-profile');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
    try {
      print("[ApiService.getUserProfile] Sending GET request to $url");
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 20));
      print(
          '[ApiService.getUserProfile] API Status Code: ${response.statusCode}');
      print('[ApiService.getUserProfile] API Response Body: ${response.body}');
      dynamic responseData;
      String message = 'Failed to parse response';
      bool isJson =
          response.headers['content-type']?.contains('application/json') ??
              false;
      try {
        if (isJson && response.body.isNotEmpty) {
          responseData = json.decode(response.body);
          message = "Profile loaded successfully";
        } else if (response.body.isNotEmpty &&
            response.statusCode >= 200 &&
            response.statusCode < 300) {
          responseData = {'rawBody': response.body};
          message = "Profile loaded but response was not JSON.";
        } else if (response.body.isEmpty &&
            response.statusCode >= 200 &&
            response.statusCode < 300) {
          responseData = {};
          message = "Profile loaded successfully (empty body).";
        } else {
          responseData = {'rawErrorBody': response.body};
          message = response.body.isNotEmpty
              ? response.body
              : 'Failed to load profile (Status: ${response.statusCode})';
        }
      } catch (e) {
        message = 'Error parsing server response.';
        responseData = {'rawErrorBody': response.body};
      }
      bool success = response.statusCode == 200;
      if (!success) {
        /* Improve error messages */
      }
      return {
        'success': success,
        'data': success ? responseData : null,
        'statusCode': response.statusCode,
        'message': message,
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'انتهت مهلة طلب تحميل الملف الشخصي.',
        'error': e.toString(),
        'statusCode': 408
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الشبكة.',
        'error': e.toString()
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    if (token.isEmpty)
      return {
        'success': false,
        'message': 'خطأ: رمز الجلسة المؤقت مفقود.',
        'statusCode': 400
      };
    if (newPassword.isEmpty)
      return {
        'success': false,
        'message': 'خطأ: كلمة المرور الجديدة مطلوبة.',
        'statusCode': 400
      };
    final url = Uri.parse('$baseUrl/auth/reset-password');
    try {
      final payload = {
        'Token': token,
        'NewPassword': newPassword,
      };
      print('[ApiService.resetPassword] Sending password reset request.');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json, text/plain',
            },
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 25));
      print(
          '[ApiService.resetPassword] API Status Code: ${response.statusCode}');
      print(
          '[ApiService.resetPassword] API Raw Response Body: ${response.body}');
      dynamic responseData;
      String message = 'Unknown response';
      bool isJson = false;
      try {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          responseData = json.decode(response.body);
          isJson = true;
          if (responseData is Map<String, dynamic>) {
            message = responseData['message']?.toString() ??
                responseData['title']?.toString() ??
                (responseData['errors'] != null
                    ? json.encode(responseData['errors'])
                    : null) ??
                'Password reset processed';
            if (message
                .toLowerCase()
                .contains("one or more validation errors occurred")) {
              /* Improve error messages */
            }
          } else
            message = responseData.toString();
        } else {
          message = response.body.trim();
          responseData = {'rawBody': message};
          if (message
              .toLowerCase()
              .contains('password has been reset successfully')) {
          } else if (message.toLowerCase().contains('invalid token'))
            message = 'رمز الجلسة المستخدم غير صالح أو انتهت صلاحيته.';
          else if (message.toLowerCase().contains('user not found'))
            message = 'المستخدم المرتبط بهذا الرمز غير موجود.';
        }
      } catch (e) {
        message = response.body.trim();
        responseData = {'rawErrorBody': message};
      }
      bool success = response.statusCode == 200;
      if (success)
        message = "تم إعادة تعيين كلمة المرور بنجاح.";
      else if (!success && (message.isEmpty || message == 'Unknown response')) {
        /* Improve error messages */
      }
      return {
        'success': success,
        'data': responseData,
        'statusCode': response.statusCode,
        'message': message,
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'انتهت مهلة طلب إعادة تعيين كلمة المرور.',
        'error': e.toString(),
        'statusCode': 408
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الشبكة.',
        'error': e.toString()
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error or request setup failed: $e',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> verifyEmailOtp(
      String? tempToken, String otpCode) async {
    if (tempToken == null || tempToken.isEmpty)
      return {
        'success': false,
        'message': 'خطأ: رمز الجلسة المؤقت مفقود.',
        'statusCode': 400
      };
    if (otpCode.isEmpty || otpCode.length != 6)
      return {
        'success': false,
        'message': 'خطأ: يجب إدخال رمز التحقق المكون من 6 أرقام.',
        'statusCode': 400
      };
    final url = Uri.parse('$baseUrl/auth/verify-email-otp');
    try {
      final payload = {
        'Token': tempToken,
        'OtpCode': otpCode,
      };
      print('[ApiService.verifyEmailOtp] Verifying Email OTP');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json, text/plain',
            },
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 20));
      print(
          '[ApiService.verifyEmailOtp] API Status Code: ${response.statusCode}');
      print(
          '[ApiService.verifyEmailOtp] API Raw Response Body: ${response.body}');
      dynamic responseData;
      String message = 'Unknown response';
      bool isJson = false;
      try {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          responseData = json.decode(response.body);
          isJson = true;
          if (responseData is Map<String, dynamic>) {
            message = responseData['message']?.toString() ??
                responseData['title']?.toString() ??
                (responseData['errors'] != null
                    ? json.encode(responseData['errors'])
                    : null) ??
                'Email verification processed';
            if (message
                    .toLowerCase()
                    .contains("one or more validation errors occurred") ||
                (responseData['errors']?.containsKey('OtpCode') ?? false))
              message = 'رمز التحقق غير صحيح أو انتهت صلاحيته.';
            else if (message.toLowerCase().contains("invalid token") ||
                (responseData['errors']?.containsKey('Token') ?? false))
              message = 'رمز الجلسة المؤقت غير صالح أو انتهت صلاحيته.';
          } else
            message = responseData.toString();
        } else {
          message = response.body.trim();
          responseData = {'rawBody': message};
          if (message.toLowerCase().contains('invalid token'))
            message = 'رمز الجلسة المؤقت غير صالح أو انتهت صلاحيته.';
          else if (message.toLowerCase().contains('invalid or expired otp'))
            message = 'رمز التحقق غير صحيح أو انتهت صلاحيته.';
        }
      } catch (e) {
        message = response.body.trim();
        responseData = {'rawErrorBody': message};
      }
      bool success = response.statusCode == 200;
      if (!success && (message.isEmpty || message == 'Unknown response')) {
        /* Improve error messages */
      }
      return {
        'success': success,
        'data': responseData,
        'token': null,
        'statusCode': response.statusCode,
        'message': success
            ? (isJson &&
                    responseData is Map &&
                    responseData.containsKey('message')
                ? responseData['message']?.toString() ??
                    'تم التحقق من البريد الإلكتروني بنجاح.'
                : 'تم التحقق من البريد الإلكتروني بنجاح.')
            : message,
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'انتهت مهلة طلب التحقق من الرمز.',
        'error': e.toString(),
        'statusCode': 408
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الشبكة.',
        'error': e.toString()
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error or request setup failed: $e',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String identifier, String code,
      [String? reference]) async {
    final url = Uri.parse('$baseUrl/auth/verify-otp');
    try {
      final payload = {'identifier': identifier, 'code': code};
      if (reference != null && reference.isNotEmpty)
        payload['reference'] = reference;
      print('[ApiService.verifyOtp] Sending data: ${json.encode(payload)}');
      final response = await http
          .post(url,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
              },
              body: json.encode(payload))
          .timeout(const Duration(seconds: 20));
      print('[ApiService.verifyOtp] API Status Code: ${response.statusCode}');
      print('[ApiService.verifyOtp] API Response Body: ${response.body}');
      dynamic responseData;
      String message = 'Unknown response';
      try {
        responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic>) {
          message = responseData['title']?.toString() ??
              responseData['message']?.toString() ??
              (responseData['errors'] != null
                  ? json.encode(responseData['errors'])
                  : null) ??
              'OTP verification processed';
          if (message
              .toLowerCase()
              .contains("one or more validation errors occurred"))
            message = 'رمز التحقق غير صحيح أو انتهت صلاحيته.';
        } else
          message = responseData.toString();
      } catch (e) {
        message =
            'API returned non-JSON response (Status ${response.statusCode})';
        responseData = {'rawErrorBody': response.body};
      }
      bool success = response.statusCode == 200 || response.statusCode == 201;
      String? loginToken = (success &&
              responseData is Map<String, dynamic> &&
              responseData.containsKey('token'))
          ? responseData['token']
          : null;
      return {
        'success': success,
        'data': responseData,
        'token': loginToken,
        'statusCode': response.statusCode,
        'message': success
            ? (responseData is Map && responseData.containsKey('message')
                ? responseData['message']?.toString() ??
                    'تم التحقق من الرمز بنجاح'
                : 'تم التحقق من الرمز بنجاح')
            : message,
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'انتهت مهلة طلب التحقق من الرمز.',
        'error': e.toString(),
        'statusCode': 408
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الشبكة.',
        'error': e.toString()
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error or request setup failed: $e',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> sendOtp(
      String identifier, String type) async {
    if (type.toLowerCase() != 'email') {
      return {
        'success': false,
        'message': 'نوع التأكيد غير مدعوم حاليًا.',
        'statusCode': 400
      };
    }
    final url = Uri.parse('$baseUrl/auth/Send-OTP');
    try {
      final payload = {'Email': identifier};
      print('[ApiService.sendOtp] Sending OTP request for email: $identifier');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json, text/plain',
            },
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 30));

      print('[ApiService.sendOtp] API Status Code: ${response.statusCode}');
      print('[ApiService.sendOtp] API Raw Response Body: ${response.body}');
      dynamic responseData;
      String message = 'Unknown response';
      String? tempToken;
      try {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            message = responseData['message']?.toString() ??
                responseData['title']?.toString() ??
                'OTP sent processed.';
            if (responseData.containsKey('token'))
              tempToken = responseData['token'];
          } else
            message = responseData.toString();
        } else {
          message = response.body.trim();
          responseData = {'rawBody': message};
          if (message.toLowerCase() == 'user not found.')
            message = 'المستخدم (البريد الإلكتروني) غير موجود.';
        }
      } catch (e) {
        message = response.body.trim();
        responseData = {'rawErrorBody': message};
      }
      bool success = response.statusCode == 200 &&
          tempToken != null &&
          tempToken.isNotEmpty;
      if (!success && (message.isEmpty || message == 'Unknown response')) {
        /* Improve error messages */
      }
      return {
        'success': success,
        'data': responseData,
        'statusCode': response.statusCode,
        'message': message,
        'token': success ? tempToken : null,
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'انتهت مهلة طلب إرسال الرمز.',
        'error': e.toString(),
        'statusCode': 408
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الشبكة.',
        'error': e.toString()
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error or request setup failed: $e',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> addDoctor(String name,
      {String degree = "Therapist",
      String about = "Child's Therapist",
      String? email,
      String? phone}) async {
    try {
      final url = Uri.parse('$baseUrl/doctor/add-doctor');
      final Map<String, dynamic> payload = {
        'doc_Name': name,
        'degree': degree,
        'about': about
      };
      if (email != null && email.trim().isNotEmpty) payload['email'] = email;
      if (phone != null && phone.trim().isNotEmpty) payload['phone'] = phone;
      print('[ApiService.addDoctor] Sending Data: ${json.encode(payload)}');
      final response = await http
          .post(url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(payload))
          .timeout(const Duration(seconds: 20));

      print('[ApiService.addDoctor] API Status Code: ${response.statusCode}');
      print('[ApiService.addDoctor] API Response Body: ${response.body}');
      dynamic responseData;
      String message = 'Unknown response';
      try {
        if (response.body.isNotEmpty &&
            (response.headers['content-type']?.contains('application/json') ??
                false)) {
          responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            message = responseData['message']?.toString() ??
                responseData['title']?.toString() ??
                'Doctor add processed';
          } else {
            message = responseData.toString();
          }
        } else {
          message = response.body.isNotEmpty
              ? response.body
              : 'Empty or non-JSON response (Status ${response.statusCode})';
          responseData = {'rawErrorBody': response.body};
        }
      } catch (e) {
        print('[ApiService.addDoctor] JSON Decode Error: $e');
        message = 'Error parsing server response.';
        responseData = {'rawErrorBody': response.body};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('doctor') &&
            responseData['doctor'] is Map &&
            responseData['doctor'].containsKey('doctor_ID')) {
          return {
            'success': true,
            'doctorId': responseData['doctor']['doctor_ID'],
            'data': responseData,
            'message': responseData['message']?.toString() ??
                'تمت إضافة الأخصائي بنجاح'
          };
        } else {
          print(
              '[ApiService.addDoctor] Success status code, but failed to parse Doctor ID from response.');
          return {
            'success': false,
            'message':
                'نجح الطلب (status ${response.statusCode})، لكن فشل استخراج معرّف الأخصائي.',
            'data': responseData,
            'statusCode': response.statusCode
          };
        }
      } else {
        if (response.statusCode == 400 &&
            responseData is Map<String, dynamic> &&
            responseData['title']
                    ?.toString()
                    .toLowerCase()
                    .contains('validation errors') ==
                true) {
          message = 'خطأ في بيانات الأخصائي المدخلة.';
          print(
              '[ApiService.addDoctor] Validation Errors: ${json.encode(responseData['errors'])}');
        }
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': message,
          'data': responseData
        };
      }
    } on TimeoutException catch (e) {
      print('[ApiService.addDoctor] Network Timeout: $e');
      return {
        'success': false,
        'message': 'انتهت مهلة طلب إضافة الأخصائي.',
        'error': e.toString(),
        'statusCode': 408
      };
    } on SocketException catch (e) {
      print('[ApiService.addDoctor] Network/Socket error: $e');
      return {
        'success': false,
        'message': 'خطأ في الشبكة. تأكد من اتصالك بالإنترنت.',
        'error': e.toString()
      };
    } catch (e) {
      print('[ApiService.addDoctor] Network or other error: $e');
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع أثناء إضافة الأخصائي: $e',
        'error': e.toString()
      };
    }
  }

  static Future<Map<String, dynamic>> registerUser(
      Map<String, dynamic> userData) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      print('[ApiService.registerUser] Sending Data: ${json.encode(userData)}');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(userData),
          )
          .timeout(const Duration(seconds: 25));

      print(
          '[ApiService.registerUser] API Status Code: ${response.statusCode}');
      print('[ApiService.registerUser] API Response Body: ${response.body}');
      dynamic responseData;
      String message = 'Unknown response';
      try {
        if (response.body.isNotEmpty &&
            (response.headers['content-type']?.contains('application/json') ??
                false)) {
          responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            message = responseData['title']?.toString() ??
                responseData['message']?.toString() ??
                (responseData['errors'] != null
                    ? json.encode(responseData['errors'])
                    : null) ??
                'Registration processed';
            if (message
                    .toLowerCase()
                    .contains("one or more validation errors occurred") ||
                responseData['errors'] != null) {
              if (responseData['errors']?['\$.birthDate'] != null) {
                message = 'خطأ في صيغة تاريخ الميلاد.';
              } else {
                message = 'خطأ في بيانات التسجيل المدخلة.';
              }
              print(
                  '[ApiService.registerUser] Validation Errors: ${json.encode(responseData['errors'])}');
            }
          } else {
            message = responseData.toString();
          }
        } else {
          message = response.body.isNotEmpty
              ? response.body
              : 'Empty or non-JSON response (Status ${response.statusCode})';
          responseData = {'rawErrorBody': response.body};
        }
      } catch (e) {
        print('[ApiService.registerUser] JSON Decode Error: $e');
        message = 'Error parsing server response.';
        responseData = {'rawErrorBody': response.body};
      }
      bool success = response.statusCode == 200 || response.statusCode == 201;
      return {
        'success': success,
        'data': responseData,
        'statusCode': response.statusCode,
        'message': success
            ? (responseData is Map && responseData.containsKey('message')
                ? responseData['message']?.toString() ?? 'تم التسجيل بنجاح.'
                : 'تم التسجيل بنجاح.')
            : message,
      };
    } on TimeoutException catch (e) {
      print('[ApiService.registerUser] Network Timeout: $e');
      return {
        'success': false,
        'message': 'انتهت مهلة طلب التسجيل.',
        'error': e.toString(),
        'statusCode': 408
      };
    } on SocketException catch (e) {
      print('[ApiService.registerUser] Network/Socket error: $e');
      return {
        'success': false,
        'message': 'خطأ في الشبكة. تأكد من اتصالك بالإنترنت.',
        'error': e.toString()
      };
    } catch (e) {
      print(
          '[ApiService.registerUser] Network or other error during registration: $e');
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع أثناء التسجيل: $e',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      print('[ApiService.loginUser] Sending login request for email: $email');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'Email': email, 'Password': password}),
          )
          .timeout(const Duration(seconds: 20));

      print('[ApiService.loginUser] API Status Code: ${response.statusCode}');
      print('[ApiService.loginUser] API Response Body: ${response.body}');

      dynamic responseData;
      String message = 'Unknown response';
      bool success = false;
      String? token;
      bool hasCompletedAssessment = false;

      try {
        if (response.body.isNotEmpty &&
            (response.headers['content-type']?.contains('application/json') ??
                false)) {
          responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            success = response.statusCode >= 200 &&
                response.statusCode < 300 &&
                responseData.containsKey('token');
            if (success) {
              token = responseData['token'];
              hasCompletedAssessment = responseData['hasCompletedAssessment'] ??
                  responseData['data']?['hasCompletedAssessment'] ??
                  false;
              print(
                  "[ApiService.loginUser] Extracted hasCompletedAssessment: $hasCompletedAssessment");
              message =
                  responseData['message']?.toString() ?? 'Login successful';
            } else {
              message = responseData['message']?.toString() ??
                  responseData['title']?.toString() ??
                  'Login failed';
            }
          } else {
            message = 'Invalid response format (not a Map)';
          }
        } else if (response.statusCode >= 200 && response.statusCode < 300) {
          message = 'Login successful but response body is empty or not JSON.';
          success = true;
          token = null;
          hasCompletedAssessment = false;
        } else {
          message =
              'Login failed (Status: ${response.statusCode}). Empty or non-JSON response.';
          responseData = {'rawErrorBody': response.body};
        }
      } catch (e) {
        print('[ApiService.loginUser] JSON Decode or Processing Error: $e');
        message = 'Error parsing server response.';
        responseData = {'rawErrorBody': response.body};
        success = false;
      }

      return {
        'success': success,
        'token': token,
        'hasCompletedAssessment': hasCompletedAssessment,
        'data': responseData,
        'statusCode': response.statusCode,
        'message': message,
      };
    } on TimeoutException catch (e) {
      print('[ApiService.loginUser] Network Timeout: $e');
      return {
        'success': false,
        'message': 'انتهت مهلة الاتصال بالخادم، يرجى المحاولة مرة أخرى.',
        'error': e.toString(),
        'statusCode': 408
      };
    } on SocketException catch (e) {
      print('[ApiService.loginUser] Network/Socket error: $e');
      return {
        'success': false,
        'message': 'خطأ في الشبكة. تأكد من اتصالك بالإنترنت.',
        'error': e.toString()
      };
    } catch (e) {
      print('[ApiService.loginUser] Generic error during login: $e');
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع أثناء تسجيل الدخول: $e',
        'error': e.toString()
      };
    }
  }

  static Future<bool> markSessionDetailAsNotComplete(
      String token, int sessionDetailId) async {
    if (sessionDetailId <= 0) {
      debugPrint(
          "[ApiService.markSessionDetailAsNotComplete] Error: Invalid sessionDetailId ($sessionDetailId).");
      return false;
    }
    final Uri uri = Uri.parse(
        '$baseUrl/SessionController/detail/$sessionDetailId/Notcomplete');
    debugPrint(
        '[ApiService.markSessionDetailAsNotComplete] Calling: POST $uri');
    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': '*/*'
            },
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 15));
      debugPrint(
          '[ApiService.markSessionDetailAsNotComplete] Status Code for ID $sessionDetailId: ${response.statusCode}');
      bool success = response.statusCode == 200 || response.statusCode == 204;
      if (!success)
        debugPrint(
            '[ApiService.markSessionDetailAsNotComplete] Failed. Status: ${response.statusCode}, Body: ${response.body}');
      else
        debugPrint(
            '[ApiService.markSessionDetailAsNotComplete] Success for ID $sessionDetailId. Body: ${response.body}');
      return success;
    } catch (e) {
      debugPrint(
          '[ApiService.markSessionDetailAsNotComplete] Error for ID $sessionDetailId: $e');
      return false;
    }
  }

// ---!!! دالة جديدة لتعليم تفصيل الاختبار كـ "غير مكتمل" !!!---
  static Future<bool> markTestDetailAsNotComplete(
      String token, int testDetailId) async {
    if (testDetailId <= 0) {
      debugPrint(
          "[ApiService.markTestDetailAsNotComplete] Error: Invalid testDetailId ($testDetailId).");
      return false;
    }

    // المسار الجديد بناءً على الصورة الأخيرة
    final Uri uri = Uri.parse(
        '$baseUrl/TestController/test-detail/$testDetailId/Notcomplete');

    debugPrint('[ApiService.markTestDetailAsNotComplete] Calling: POST $uri');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          // 'Content-Type': 'application/json', // قد لا تكون ضرورية إذا لم يكن هناك body
          'Accept': '*/*',
        },
        // لا يوجد body بناءً على الصورة
      ).timeout(const Duration(seconds: 15));

      debugPrint(
          '[ApiService.markTestDetailAsNotComplete] Status Code for Test ID $testDetailId: ${response.statusCode}');
      bool success = response.statusCode == 200 || response.statusCode == 204;

      if (!success) {
        debugPrint(
            '[ApiService.markTestDetailAsNotComplete] Failed. Status: ${response.statusCode}, Body: ${response.body}');
      } else {
        debugPrint(
            '[ApiService.markTestDetailAsNotComplete] Success for Test ID $testDetailId. Body: ${response.body}');
      }
      return success;
    } on TimeoutException catch (e) {
      debugPrint(
          '[ApiService.markTestDetailAsNotComplete] Timeout for Test ID $testDetailId: $e');
      return false;
    } on SocketException catch (e) {
      debugPrint(
          '[ApiService.markTestDetailAsNotComplete] Network Error for Test ID $testDetailId: $e');
      return false;
    } on http.ClientException catch (e) {
      debugPrint(
          '[ApiService.markTestDetailAsNotComplete] Client Error for Test ID $testDetailId: $e');
      return false;
    } catch (e) {
      debugPrint(
          '[ApiService.markTestDetailAsNotComplete] Unexpected Error for Test ID $testDetailId: $e');
      return false;
    }
  }

  // --- دالة جديدة لجلب مجموعة اختبار الـ 3 شهور ---
  static Future<TestGroupResponse?> fetchNextTestGroup(String token) async {
    final String apiUrl =
        "$baseUrl/TestController/next-test-group"; // تأكد من صحة المسار
    final Uri uri = Uri.parse(apiUrl);
    debugPrint("ApiService: Calling GET $uri to fetch next test group.");

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint(
          "ApiService.fetchNextTestGroup: Status Code: ${response.statusCode}");
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          debugPrint(
              "ApiService.fetchNextTestGroup: Received empty response body.");
          return null;
        }
        final data = jsonDecode(response.body);
        if (data == null || data is! Map<String, dynamic> || data.isEmpty) {
          debugPrint(
              "ApiService.fetchNextTestGroup: Received empty or invalid data after decode.");
          return null;
        }
        return TestGroupResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        debugPrint("ApiService.fetchNextTestGroup: Unauthorized.");
        throw Exception("Unauthorized");
      } else if (response.statusCode == 404 || response.statusCode == 204) {
        debugPrint(
            "ApiService.fetchNextTestGroup: No next test group available (404 or 204).");
        return null;
      } else {
        debugPrint(
            "ApiService.fetchNextTestGroup: Failed. Status: ${response.statusCode}, Body: ${response.body}");
        throw Exception("Failed to load test group data");
      }
    } catch (e) {
      debugPrint("ApiService.fetchNextTestGroup: Exception: $e");
      rethrow;
    }
  }

  // --- دالة جديدة لتعليم إكمال مجموعة الاختبار ---
  static Future<bool> markTestGroupDone(String token, int groupId) async {
    if (groupId <= 0) {
      debugPrint(
          "ApiService: Invalid groupId ($groupId) for markTestGroupDone.");
      return false;
    }
    final String apiUrl =
        "$baseUrl/TestController/mark-group-done/$groupId"; // تأكد من صحة المسار
    final Uri uri = Uri.parse(apiUrl);
    debugPrint("ApiService: Calling POST $uri to mark group done.");

    try {
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint(
          "ApiService.markTestGroupDone (GroupID: $groupId): Status Code: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
          "ApiService.markTestGroupDone (GroupID: $groupId): Exception: $e");
      return false;
    }
  }
  static Future<bool> addIncorrectAnswerComment(String token, int sessionId) async {
    // تأكدي من أن هذا هو الـ Endpoint والـ baseUrl الصحيحين
    final String endpointUrl = '$baseUrl/Reports/add-comment'; // بناءً على الصورة، المسار هو /api/Reports/add-comment
                                                              // إذا كان baseUrl هو http://aspiq.runasp.net/api
                                                              // فالرابط سيكون صحيحًا
    debugPrint("[ApiService.addIncorrectAnswerComment] Calling: POST $endpointUrl for Detail ID: $sessionId");

    try {
      // تأكدي من أن المفتاح الذي يتوقعه الـ API هو "session_ID" أو "sessionId" أو "detailId"
      final Map<String, dynamic> payload = {
        "session_ID": sessionId // افترضت أن الـ API يتوقع ID التفصيل هنا
      };
      final String jsonPayload = jsonEncode(payload);

      final response = await http.post(
        Uri.parse(endpointUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonPayload,
      ).timeout(const Duration(seconds: 15)); // مهلة معقولة

      debugPrint("[ApiService.addIncorrectAnswerComment] Status: ${response.statusCode}, Body: ${response.body}");

      // عادةً ما يكون 200 OK أو 201 Created أو 204 No Content علامات نجاح
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint("[ApiService.addIncorrectAnswerComment] Comment added successfully for Detail ID: $sessionId");
        return true;
      } else {
        debugPrint("[ApiService.addIncorrectAnswerComment] Failed to add comment for Detail ID: $sessionId. Status: ${response.statusCode}");
        return false;
      }
    } on TimeoutException catch (e) {
      debugPrint("[ApiService.addIncorrectAnswerComment] Timeout error for Detail ID $sessionId: $e");
      return false;
    } catch (e) {
      debugPrint("[ApiService.addIncorrectAnswerComment] General error for Detail ID $sessionId: $e");
      return false;
    }
  }
} // نهاية الكلاس ApiService
