// lib/screens/report_list_screen.dart (أو مسارك الصحيح)
import "dart:io";
import "package:myfinalpro/Report/pdf_generator_service.dart";
import "package:myfinalpro/Report/pdf_share_service.dart";
import "package:myfinalpro/Report/progress_model.dart";
import "package:myfinalpro/Report/report_detail_screen.dart";
import "package:myfinalpro/Report/report_remote_datasource.dart";
import "package:flutter/material.dart";
import 'package:shared_preferences/shared_preferences.dart'; // لإدارة التوكن
// تأكد أن المسارات التالية صحيحة بالنسبة لمشروعك

import "package:http/http.dart" as http;

import "child_report_model.dart"; // افترض أن هذا النموذج موجود وصحيح

// تعريف استثناء مخصص إذا لم يكن موجودًا بالفعل
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    return "ApiException: $message (StatusCode: $statusCode)";
  }
}


class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  late Future<ChildReportResponse> _reportsFuture;
  ReportRemoteDataSource? _dataSource;
  final PdfGeneratorService _pdfGeneratorService = PdfGeneratorService();
  final PdfShareService _pdfShareService = PdfShareService();
  final Map<int, bool> _isProcessingPdf = {};
  final Map<int, ProgressResponse?> _fetchedProgressData = {};
  String? _authToken;
  bool _isLoadingToken = true;

  // تعريف اللون الأساسي هنا لتسهيل استخدامه
  final Color _primaryAppColor = const Color(0xFF2C73D9);


  @override
  void initState() {
    super.initState();
    _initializeDataSourceAndFetchReports();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
    prefs.getString('auth_token');
    print(
        "ReportListScreen - _getAuthToken: Token read from SharedPreferences ('auth_token'): $token");
    return token;
  }

  Future<void> _initializeDataSourceAndFetchReports() async {
    if (mounted) {
      setState(() {
        _isLoadingToken = true;
      });
    }
    _authToken = await _getAuthToken();
    print(
        "ReportListScreen - _initializeDataSourceAndFetchReports: Retrieved token: $_authToken");

    if (_authToken != null && _authToken!.isNotEmpty) {
      _dataSource = ReportRemoteDataSourceImpl(
          client: http.Client(), authToken: _authToken!);
      _reportsFuture = _dataSource!.getChildReport();
      print(
          "ReportListScreen: DataSource initialized and fetching reports with token.");
    } else {
      _reportsFuture = Future.error(
          "User not authenticated or token not found. Please login.");
      print(
          "ReportListScreen: Auth token not found or empty. Cannot initialize DataSource.");
    }
    if (mounted) {
      setState(() {
        _isLoadingToken = false;
      });
    }
  }

  Future<void> _generateAndSharePdf(ChildReportGroup report) async {
    if (_dataSource == null) {
      print(
          "ReportListScreen - _generateAndSharePdf: DataSource is null. Auth token likely missing.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("خطأ في المصادقة، يرجى إعادة تسجيل الدخول.",
                  textDirection: TextDirection.rtl)),
        );
      }
      return;
    }
    if (_isProcessingPdf[report.groupId] == true) return;

    if (mounted) {
      setState(() {
        _isProcessingPdf[report.groupId] = true;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("جاري تحضير ملف ${report.groupName} للمشاركة...",
                textDirection: TextDirection.rtl)),
      );
    }

    try {
      if (!_fetchedProgressData.containsKey(report.groupId) ||
          _fetchedProgressData[report.groupId] == null) {
        print(
            "ReportListScreen - _generateAndSharePdf: Fetching progress data for group ${report.groupId}");
        _fetchedProgressData[report.groupId] =
        await _dataSource!.getProgress().catchError((e) {
          print(
              "Error fetching progress on demand for PDF (group ${report.groupId}): $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('فشل تحميل بيانات التقدم المطلوبة للملف: $e',
                      textDirection: TextDirection.rtl)),
            );
          }
          return null;
        });
      }

      final File pdfFile = await _pdfGeneratorService.generateReportPdf(
        report,
        _fetchedProgressData[report.groupId],
      );
      await _pdfShareService.sharePdf(pdfFile,
          subject: "تقرير شعور ${report.groupName}");
    } catch (e) {
      print(
          "Error generating/sharing PDF in ReportListScreen (group ${report.groupId}): $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("حدث خطأ أثناء تحضير الملف: $e",
                  textDirection: TextDirection.rtl)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPdf[report.groupId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                'التقارير',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primaryAppColor, // استخدام اللون المعرف
                ),
                textAlign: TextAlign.center,
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_right_outlined,
                    size: 40,
                    color: _primaryAppColor, // استخدام اللون المعرف
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ]),
        ),
      ),
      body: _isLoadingToken
          ? Center(
          child: CircularProgressIndicator(
            semanticsLabel: "جاري تحميل بيانات المصادقة",
            color: _primaryAppColor, // استخدام اللون المعرف
          ))
          : _dataSource == null
          ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "لم يتم العثور على معلومات المصادقة. يرجى تسجيل الدخول مرة أخرى.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryAppColor, // استخدام اللون المعرف
                    foregroundColor: Colors.white, // لون النص على الزر
                  ),
                  onPressed: () {
                    print(
                        "ReportListScreen: 'تسجيل الدخول' button pressed from auth error message.");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                              "يرجى تسجيل الخروج ثم الدخول مجددًا.", textDirection: TextDirection.rtl,)),
                      );
                    }
                  },
                  child: const Text("تسجيل الدخول"),
                )
              ],
            ),
          ))
          : FutureBuilder<ChildReportResponse>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_isLoadingToken) {
            return Center(
                child: CircularProgressIndicator(
                  semanticsLabel: "جاري تحميل التقارير",
                  color: _primaryAppColor, // استخدام اللون المعرف
                ));
          }
          if (snapshot.hasError) {
            String errorMessage = "حدث خطأ: ${snapshot.error}";
            if (snapshot.error is ApiException) {
              final apiError = snapshot.error as ApiException;
              errorMessage =
              "خطأ من الخادم (${apiError.statusCode}): ${apiError.message}";
              if (apiError.statusCode == 401) {
                errorMessage +=
                "\nيرجى التأكد من تسجيل الدخول بشكل صحيح أو أن صلاحية الجلسة لم تنته.";
              }
            }
            print(
                "ReportListScreen - FutureBuilder Error: $errorMessage");
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ));
          }
          if (!snapshot.hasData || snapshot.data!.reports.isEmpty) {
            print(
                "ReportListScreen - FutureBuilder: No reports data or empty reports.");
            return const Center(
                child: Text("لا توجد تقارير لعرضها", textDirection: TextDirection.rtl,));
          }

          final reports = snapshot.data!.reports;
          print(
              "ReportListScreen - FutureBuilder: Displaying ${reports.length} reports.");

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final reportTitle = "تقرير شعور ${report.groupName}";
              final bool isLoading =
                  _isProcessingPdf[report.groupId] ?? false;

              // ---!!! بداية التعديل المطلوب هنا (الألوان) !!!---
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        reportTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _primaryAppColor, // *** تعديل اللون هنا ***
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          isLoading
                              ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: _primaryAppColor, // *** تعديل اللون هنا ***
                              ))
                              : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryAppColor, // *** تعديل لون خلفية الزر ***
                              foregroundColor: Colors.white, // *** تعديل لون نص الزر ***
                            ),
                            onPressed: () =>
                                _generateAndSharePdf(report),
                            child: const Text("تنزيل"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryAppColor, // *** تعديل لون خلفية الزر ***
                              foregroundColor: Colors.white, // *** تعديل لون نص الزر ***
                            ),
                            onPressed: () {
                              if (_authToken != null &&
                                  _authToken!.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ReportDetailScreen(
                                          reportGroup: report,
                                          authToken: _authToken!,
                                        ),
                                  ),
                                );
                              } else {
                                print(
                                    "ReportListScreen - 'عرض' button: Auth token is null or empty, cannot navigate to ReportDetailScreen.");
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "خطأ في المصادقة، لا يمكن عرض التفاصيل.",
                                            textDirection:
                                            TextDirection.rtl)),
                                  );
                                }
                              }
                            },
                            child: const Text("عرض"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
              // ---!!! نهاية التعديل المطلوب هنا !!!---
            },
          );
        },
      ),
    );
  }
}