import 'dart:convert';
import 'dart:io'; 
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://aspiq.runasp.net/api';
  static const String _imgbbApiKey = 'b67e6e2b5249b9e81f9965a369d4a728';

  // Save token to local storage
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get token from local storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Clear token (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Register a new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String surname,
    required String email,
    required String phone,
    String? doctorId,
    String? image,
    String? birthDate,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Name_': name,
        'Surname': surname,
        'Email': email,
        'Phone': phone,
        'Doctor_ID': doctorId,
        'Image_': image,
        'BirthDate': birthDate,
        'Password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  // Send OTP code
  static Future<Map<String, dynamic>> sendOTP(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/Send-OTP'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Email': email,
      }),
    );

    return jsonDecode(response.body);
  }

  // Verify email with OTP
  static Future<Map<String, dynamic>> verifyEmailOTP(
      String token, String otpCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email-otp'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Token': token,
        'OtpCode': otpCode,
      }),
    );

    return jsonDecode(response.body);
  }

  // Login
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Email': email,
        'Password': password,
      }),
    );

    final data = jsonDecode(response.body);

    // Save token if login successful
    if (response.statusCode == 200 && data.containsKey('token')) {
      await saveToken(data['token']);
    }

    return data;
  }

  // Verify OTP for password reset
  static Future<Map<String, dynamic>> verifyOTP(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Email': email,
      }),
    );

    return jsonDecode(response.body);
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Token': token,
        'NewPassword': newPassword,
      }),
    );

    return jsonDecode(response.body);
  }
static Future<Map<String, dynamic>> getUserProfile(String token) async {
    final url = Uri.parse('$baseUrl/user/get-profile');
    final headers = <String, String>{ 'Accept': 'application/json', 'Authorization': 'Bearer $token', };
    if (kDebugMode) { print("[AuthService.getUserProfile] GET $url"); }
    try {
      final response = await http.get(url, headers: headers);
      if (kDebugMode) { print('[AuthService.getUserProfile] Status: ${response.statusCode}, Body: ${response.body}'); }
      return _handleResponse(response, successStatusCode: 200);
    } catch (e) { if (kDebugMode) { print('[AuthService.getUserProfile] Error: $e'); } return {'success': false, 'message': 'Network error: $e'}; }
  }

  // --- دالة تحديث الملف الشخصي ---
  static Future<Map<String, dynamic>> updateUserProfile(String token, {required String name, required String surname, int? doctorId, String? imageUrl}) async {
    final url = Uri.parse('$baseUrl/user/update-profile');
    final headers = <String, String>{ 'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token', };
    final Map<String, dynamic> bodyMap = { 'name_': name, 'surname': surname, }; // <-- استخدام name_
    if (imageUrl != null) { bodyMap['image_'] = imageUrl; } // <-- استخدام image_
    if (doctorId != null) { bodyMap['doctor_ID'] = doctorId; } // <-- استخدام doctor_ID
    final body = json.encode(bodyMap);
    if (kDebugMode) { print("[AuthService.updateUserProfile] PUT $url | Body: $body"); }
    try {
      final response = await http.put(url, headers: headers, body: body);
      if (kDebugMode) { print('[AuthService.updateUserProfile] Status: ${response.statusCode}, Body: ${response.body}'); }
      return _handleResponse(response, successStatusCode: 200, successStatusCode2: 204);
    } catch (e) { if (kDebugMode) { print('[AuthService.updateUserProfile] Error: $e'); } return {'success': false, 'message': 'Network error: $e'}; }
  }

  // --- دالة رفع الصورة إلى ImgBB ---
  static Future<String?> uploadImageToImgBB(File imageFile) async {
    if (_imgbbApiKey.isEmpty) { throw Exception("ImgBB API Key is missing."); }
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey');
    if (kDebugMode) { print("[AuthService.uploadImageToImgBB] Uploading to ImgBB: $url"); }
    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add( await http.MultipartFile.fromPath('image', imageFile.path, contentType: MediaType('image', imageFile.path.split('.').last)) ); // اسم الحقل 'image'
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (kDebugMode) { print('[AuthService.uploadImageToImgBB] Status: ${response.statusCode}, Body: ${response.body}'); }
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['data']?['url'] != null) {
          if (kDebugMode) { print("[AuthService.uploadImageToImgBB] Success! URL: ${responseData['data']['url']}"); }
          return responseData['data']['url'];
        } else { throw Exception('ImgBB response missing image URL.'); }
      } else { /* ... (معالجة خطأ ImgBB كما في الرد السابق) ... */ throw Exception('ImgBB upload failed (${response.statusCode})'); }
    } catch (e) { if (kDebugMode) { print('[AuthService.uploadImageToImgBB] Error: $e'); } throw Exception("Failed to upload image: ${e.toString().replaceFirst('Exception: ', '')}"); }
  }

  // --- دالة مساعدة لمعالجة الاستجابة ---
  static Map<String, dynamic> _handleResponse(http.Response response, {int successStatusCode = 200, int? successStatusCode2, String successMessage = 'Success'}) {
    // ... (نفس كود الدالة المساعدة من الرد السابق) ...
     dynamic responseData; String message = 'Unknown response'; bool isJson = response.headers['content-type']?.contains('application/json') ?? false; try { if (response.body.isNotEmpty){ if (isJson) { responseData = json.decode(response.body); if (responseData is Map<String, dynamic>) { message = responseData['message']?.toString() ?? responseData['title']?.toString() ?? responseData['error']?.toString() ?? successMessage; if (responseData['errors'] != null) { try { var errors = responseData['errors']; var firstErrorKey = errors.keys.firstWhere((k) => k != '\$id', orElse: () => null); if (firstErrorKey != null && errors[firstErrorKey] is List && errors[firstErrorKey].isNotEmpty){ message = errors[firstErrorKey][0];} else {message += " Details: ${json.encode(errors)}";} } catch(_){} } } else { message = responseData.toString(); } } else { message = response.body.trim(); responseData = {'rawBody': message}; } } else { responseData = {}; message = (response.statusCode == successStatusCode || (successStatusCode2 != null && response.statusCode == successStatusCode2)) ? successMessage : "Empty response with status ${response.statusCode}"; } } catch (e) { if (kDebugMode) { print('[_handleResponse] JSON Decode Error: $e');} message = 'Error parsing server response.'; responseData = {'rawErrorBody': response.body}; } bool success = response.statusCode == successStatusCode || (successStatusCode2 != null && response.statusCode == successStatusCode2); if (!success && (message == 'Unknown response' || message.trim().isEmpty || message == successMessage)) { if (responseData is Map && responseData.containsKey('rawBody') && responseData['rawBody'].isNotEmpty) { message = responseData['rawBody']; } else if (isJson && responseData is Map && responseData.isNotEmpty){ try { message = json.encode(responseData); } catch (_){ message = responseData.toString();} } else { message = "Request failed with status code: ${response.statusCode}"; } } if (!success) { if (response.statusCode == 401) message = "غير مصرح به أو التوكن غير صالح."; else if (response.statusCode == 403) message = "ممنوع الوصول."; else if (response.statusCode == 404) message = "المورد غير موجود (404)."; else if (response.statusCode >= 500) message = "خطأ في الخادم (${response.statusCode})."; }
       return { 'success': success, 'data': responseData, 'statusCode': response.statusCode, 'message': message, };
  }
}