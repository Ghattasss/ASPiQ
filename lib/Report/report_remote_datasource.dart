import 'dart:convert';
import 'dart:io'; // Required for HttpHeaders
import 'package:http/http.dart' as http;
// لا تحتاج لاستيراد SharedPreferences هنا مباشرة، سيتم تمرير التوكن
import './child_report_model.dart'; // تأكد أن المسار صحيح
import './progress_model.dart'; // تأكد أن المسار صحيح

// Define a custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    return "ApiException: $message (Status Code: ${statusCode ?? 'N/A'})";
  }
}

abstract class ReportRemoteDataSource {
  Future<ChildReportResponse> getChildReport();
  Future<ProgressResponse> getProgress();
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final http.Client client;
  final String authToken; // تمت إضافة هذا السطر لاستقبال التوكن
  final String _baseUrl = "http://aspiq.runasp.net/api/Reports";

  // تم تعديل الكونستركتور ليقبل authToken
  ReportRemoteDataSourceImpl({required this.client, required this.authToken});

  @override
  Future<ChildReportResponse> getChildReport() async {
    final response = await _getJsonData("$_baseUrl/child-report");
    return ChildReportResponse.fromJson(response);
  }

  @override
  Future<ProgressResponse> getProgress() async {
    final response = await _getJsonData("$_baseUrl/progress");
    return ProgressResponse.fromJson(response);
  }

  Future<Map<String, dynamic>> _getJsonData(String url) async {
    if (authToken.isEmpty) {
      print("Auth token is empty. Cannot make API call to $url");
      throw ApiException("Authentication token is missing.", statusCode: 401);
    }
    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $authToken', // استخدام التوكن المستلم
          HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        },
      );
      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          print("API Error: Empty response body from $url");
          throw ApiException(
            "Empty response body from $url",
            statusCode: response.statusCode,
          );
        }
        try {
          // محاولة فك تشفير الاستجابة كـ UTF-8
          final decodedBody = utf8.decode(response.bodyBytes);
          // طباعة الجسم للتحقق من محتواه
          // print("Raw JSON response from $url: $decodedBody");
          return json.decode(decodedBody) as Map<String, dynamic>;
        } catch (e) {
          print(
              "JSON Decode Error for $url: $e, Body: ${utf8.decode(response.bodyBytes)}");
          throw ApiException(
            "Failed to parse JSON response from $url. Error: $e",
            statusCode: response.statusCode,
          );
        }
      } else {
        print(
          "API Error: Status Code ${response.statusCode}, Body: ${response.body}",
        );
        String errorMessage = "Failed to load data from $url.";
        try {
          // محاولة فك تشفير رسالة الخطأ من السيرفر إذا كانت JSON
          final errorJson = json.decode(response.body);
          if (errorJson is Map && errorJson.containsKey('message')) {
            errorMessage += " Server response: ${errorJson['message']}";
          } else {
            errorMessage += " Server response: ${response.body}";
          }
        } catch (_) {
          errorMessage += " Server response: ${response.body}";
        }
        throw ApiException(
          errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print("Exception during API call to $url: $e");
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException("An error occurred: ${e.toString()}");
    }
  }
}