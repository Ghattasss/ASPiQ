// lib/emotion/training_sessions_screen_v2.dart
// Or any other appropriate path, e.g., lib/features/sessions_v2/screens/training_sessions_screen_v2.dart

import 'package:flutter/material.dart';
import 'dart:convert'; // Required for jsonDecode and utf8
import 'package:http/http.dart' as http; // Import the http package

// Import your NEW model classes
import 'session_list_model_v2.dart'; // <-- ADJUST PATH AS NEEDED
import 'dart:async'; // لاستخدام TimeoutException
import 'dart:io'; // لاستخدام SocketException (ضمن أخطاء الشبكة)
import 'package:flutter/foundation.dart'; // لاستخدام debugPrint


// Import your auth service or method to get the token (مثال)
import 'auth_service.dart'; // <-- تأكد من مسار خدمة التوثيق (adjust path if needed)


/// شاشة عرض قائمة الجلسات التدريبية للطفل (الإصدار 2).
class TrainingSessionsScreenV2 extends StatefulWidget {
  const TrainingSessionsScreenV2({Key? key}) : super(key: key);

  @override
  _TrainingSessionsScreenV2State createState() => _TrainingSessionsScreenV2State();
}

class _TrainingSessionsScreenV2State extends State<TrainingSessionsScreenV2> {
  // حالة الشاشة
  List<SessionV2> _sessions = []; // Use SessionV2
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _expandedIndices = {};

  // --- ألوان الواجهة ---
  static const Color cardBackgroundColor = Color(0x33C3E2FF);
  static const Color titleColor = Color(0xFF2C73D9);
  static const Color detailsBackgroundColor = Color(0xFF2C73D9);
  static const Color detailsTextColor = Colors.white;
  static const Color playIconColor = Colors.green;
  static const Color lockIconColor = Colors.grey;

  // --- عنوان الـ API الأساسي ---
  // static const String baseUrl = 'http://aspiq.runasp.net/api'; // Original base
  static const String specificApiUrl = 'http://aspiq.runasp.net/api/SessionController/get-child-sessions_all2'; // New specific endpoint

  @override
  void initState() {
    super.initState();
    _loadSessionData(); // بدء تحميل البيانات
  }

  /// تحميل بيانات الجلسات من الـ API.
  Future<void> _loadSessionData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String? token = await AuthService.getToken(); // Assuming AuthService is correctly pathed

    if (token == null || token.isEmpty) {
      debugPrint("[_TrainingSessionsScreenV2State._loadSessionData] Error: Token is null or empty.");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'خطأ: لم يتم العثور على رمز المصادقة. يرجى تسجيل الدخول.';
        });
      }
      return;
    }

    final Uri apiUrl = Uri.parse(specificApiUrl); // Use the new specific URL
    final Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    debugPrint('[_TrainingSessionsScreenV2State._loadSessionData] Calling: GET $apiUrl');

    try {
      final response = await http.get(
        apiUrl,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      debugPrint('[_TrainingSessionsScreenV2State._loadSessionData] Status Code: ${response.statusCode}');
      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final decodedBody = utf8.decode(response.bodyBytes);
          debugPrint('[_TrainingSessionsScreenV2State._loadSessionData] Response Body (Decoded Sample): ${decodedBody.substring(0, (decodedBody.length > 500 ? 500 : decodedBody.length))}...');
          // *** استخدام دالة التحليل من المودل المستورد (V2) ***
          final List<SessionV2> fetchedSessions = sessionsV2FromJson(decodedBody); // Use sessionsV2FromJson

          setState(() {
            _sessions = fetchedSessions;
            _isLoading = false;
          });
          debugPrint('[_TrainingSessionsScreenV2State._loadSessionData] Successfully parsed ${fetchedSessions.length} sessions.');

        } catch (e) {
          debugPrint('[_TrainingSessionsScreenV2State._loadSessionData] JSON Parsing Error: $e');
          debugPrint('[_TrainingSessionsScreenV2State._loadSessionData] Raw Body causing error: ${response.body}');
          setState(() {
            _errorMessage = 'حدث خطأ أثناء معالجة بيانات الجلسات.';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        debugPrint('[_TrainingSessionsScreenV2State._loadSessionData] Unauthorized (401).');
        setState(() {
          _errorMessage = 'الجلسة غير صالحة أو منتهية. يرجى إعادة تسجيل الدخول.';
          _isLoading = false;
        });
      } else {
        debugPrint('[_TrainingSessionsScreenV2State._loadSessionData] Server Error ${response.statusCode}. Body: ${response.body}');
        setState(() {
          _errorMessage = 'فشل تحميل الجلسات (رمز الخطأ: ${response.statusCode}).';
          _isLoading = false;
        });
      }
    } on TimeoutException catch (e) {
      debugPrint('[_TrainingSessionsScreenV2State._loadSessionData] Timeout Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'استغرق الطلب وقتاً طويلاً. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
          _isLoading = false;
        });
      }
    } on SocketException catch (e) {
      debugPrint('[_TrainingSessionsScreenV2State._loadSessionData] Network Error (Socket): $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.';
          _isLoading = false;
        });
      }
    } on http.ClientException catch (e) {
       debugPrint('[_TrainingSessionsScreenV2State._loadSessionData] HTTP Client Error: $e');
       if (mounted) {
         setState(() {
           _errorMessage = 'حدث خطأ في الاتصال أثناء تحميل البيانات.';
           _isLoading = false;
         });
       }
    } catch (e) {
      debugPrint('[_TrainingSessionsScreenV2State._loadSessionData] Unexpected Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// تبديل حالة عرض تفاصيل الكارت.
  void _toggleExpand(int index) {
    if (mounted) {
      setState(() {
        if (_expandedIndices.contains(index)) {
          _expandedIndices.remove(index);
        } else {
          _expandedIndices.add(index);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // بناء الواجهة الرئيسية للشاشة
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('الجلسات التدريبية '), // Updated title
          backgroundColor: titleColor,
          foregroundColor: Colors.white,
          actions: [
             IconButton(
               icon: const Icon(Icons.refresh),
               onPressed: _isLoading ? null : _loadSessionData,
               tooltip: 'تحديث الجلسات',
             ),
          ],
        ),
        body: _buildBody(), // بناء الجسم الرئيسي
      ),
    );
  }

  /// بناء المحتوى الرئيسي للشاشة بناءً على حالة التحميل أو الخطأ أو النجاح.
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.center,
             children: [
               const Icon(Icons.error_outline, color: Colors.red, size: 50),
               const SizedBox(height: 15),
               Text(
                 _errorMessage!,
                 textAlign: TextAlign.center,
                 style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500),
               ),
               const SizedBox(height: 20),
               ElevatedButton.icon(
                 icon: const Icon(Icons.refresh),
                 label: const Text('إعادة المحاولة'),
                 onPressed: _loadSessionData,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: titleColor,
                   foregroundColor: Colors.white
                 ),
               ),
             ],
          ),
        ),
      );
    }
    if (_sessions.isEmpty) {
       return Center(
         child: Padding(
           padding: const EdgeInsets.all(20.0),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.center,
             children: [
               const Icon(Icons.list_alt_outlined, color: Colors.grey, size: 50),
                const SizedBox(height: 15),
               const Text(
                 'لا توجد جلسات متاحة حالياً.',
                 textAlign: TextAlign.center,
                 style: TextStyle(fontSize: 17, color: Colors.grey),
               ),
                const SizedBox(height: 20),
               ElevatedButton.icon(
                 icon: const Icon(Icons.refresh),
                 label: const Text('تحديث'),
                 onPressed: _loadSessionData,
                 style: ElevatedButton.styleFrom(
                    backgroundColor: titleColor,
                    foregroundColor: Colors.white
                  ),
               ),
             ],
           ),
         ),
       );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 80.0),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index]; // Uses SessionV2
        final bool isExpanded = _expandedIndices.contains(index);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          color: cardBackgroundColor,
          elevation: 3.0,
          shadowColor: titleColor.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: titleColor.withOpacity(0.15))
          ),
          child: InkWell(
            onTap: session.isOpen ? () => _toggleExpand(index) : null,
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        session.isOpen ? Icons.play_circle_fill : Icons.lock_outline,
                        color: session.isOpen ? playIconColor : lockIconColor,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          session.title,
                          style: const TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (session.isOpen)
                        Icon(
                           isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                           color: titleColor.withOpacity(0.7),
                           size: 28,
                         ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.fastOutSlowIn,
                    alignment: Alignment.topCenter,
                    child: Visibility(
                      visible: isExpanded && session.isOpen,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: detailsBackgroundColor,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _buildDetailItems(session.details.values), // Uses DetailItemV2 list
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

 /// بناء قائمة الويدجتس لعناصر التفاصيل (الصور والنصوص) داخل الكارت المفتوح.
 List<Widget> _buildDetailItems(List<DetailItemV2> details) { // Use DetailItemV2
    if (details.isEmpty) {
      return [
         Padding(
           padding: const EdgeInsets.symmetric(vertical: 15.0),
           child: const Center(child: Text(
             'لا توجد تفاصيل لهذه الجلسة.',
             style: TextStyle(color: detailsTextColor, fontStyle: FontStyle.italic)
            )),
         )
       ];
    }

    List<Widget> detailWidgets = [];
    for (int i = 0; i < details.length; i++) {
      final detail = details[i]; // detail is DetailItemV2

      if (detail.dataTypeOfContent == 'Img' && detail.fullAssetPath != null) {
        detailWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(8.0),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.15),
                         blurRadius: 5,
                         offset: const Offset(0, 2),
                       )
                     ]
                  ),
                  child: ClipRRect(
                     borderRadius: BorderRadius.circular(8.0),
                     child: Image.asset(
                      detail.fullAssetPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                         debugPrint("❌ Error loading asset: ${detail.fullAssetPath} (Original API path: ${detail.imagePath})");
                         debugPrint(error.toString());
                        return Container(
                           height: 150,
                           width: double.infinity,
                           padding: const EdgeInsets.all(15),
                           decoration: BoxDecoration(
                             color: Colors.red.shade50,
                             borderRadius: BorderRadius.circular(8.0),
                             border: Border.all(color: Colors.red.shade200)
                           ),
                           child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Icon(Icons.broken_image, color: Colors.red.shade400, size: 30),
                               const SizedBox(height: 8),
                               Text(
                                 'خطأ تحميل!\n${detail.imagePath?.split('/').last ?? 'ملف غير معروف'}',
                                 textAlign: TextAlign.center,
                                 style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                               ),
                             ],
                           ),
                        );
                      },
                    ),
                  ),
                ),
                if (detail.description != null && detail.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      detail.description!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: detailsTextColor,
                        fontSize: 14,
                        height: 1.5
                       ),
                    ),
                  ),
              ],
            ),
          )
        );
      }
      else if (detail.dataTypeOfContent == 'Text' && detail.text != null) {
         detailWidgets.add(
           Padding(
             padding: const EdgeInsets.symmetric(vertical: 10.0),
             child: Text(
               detail.text!,
               textAlign: TextAlign.center,
               style: const TextStyle(color: detailsTextColor, fontSize: 15, height: 1.5),
             ),
           )
         );
      }

       if (i < details.length - 1) {
          detailWidgets.add(
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 8.0),
               child: Divider(color: detailsTextColor.withOpacity(0.25), thickness: 0.8),
             )
          );
       }
    }
    return detailWidgets;
 }

} // --- نهاية _TrainingSessionsScreenV2State ---