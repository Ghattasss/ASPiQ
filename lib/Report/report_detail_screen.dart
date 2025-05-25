import 'dart:io';
import 'package:flutter/material.dart';
import 'child_report_model.dart'; // تأكد أن المسار صحيح
import 'progress_model.dart'; // تأكد أن المسار صحيح
import 'report_remote_datasource.dart'; // تأكد أن المسار صحيح
import 'pdf_generator_service.dart'; // تأكد أن المسار صحيح
import 'pdf_share_service.dart'; // تأكد أن المسار صحيح
import 'package:http/http.dart' as http;
// import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // إذا كنت تستخدمها

class ReportDetailScreen extends StatefulWidget {
  final ChildReportGroup reportGroup;
  final String authToken;

  const ReportDetailScreen({
    super.key,
    required this.reportGroup,
    required this.authToken,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late Future<ProgressResponse> _progressFuture;
  late ReportRemoteDataSource _dataSource;
  final PdfGeneratorService _pdfGeneratorService = PdfGeneratorService();
  final PdfShareService _pdfShareService = PdfShareService();
  bool _isProcessingPdf = false;
  ProgressResponse? _fetchedProgressData;

  final Color _unifiedColor = const Color(0xFF2C73D9);

  @override
  void initState() {
    super.initState();
    _dataSource = ReportRemoteDataSourceImpl(
        client: http.Client(), authToken: widget.authToken);

    _progressFuture = _dataSource.getProgress().then((progress) {
      if (mounted) {
        _fetchedProgressData = progress;
      }
      return progress;
    }).catchError((error) {
      print("Error fetching progress in ReportDetailScreen: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ في تحميل بيانات التقدم: $error',
                  textDirection: TextDirection.rtl)),
        );
      }
      throw error;
    });
  }

  Future<void> _generateAndSharePdf() async {
    if (_isProcessingPdf) return;
    if (mounted) {
      setState(() {
        _isProcessingPdf = true;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('جاري تحضير الملف للمشاركة...',
              textDirection: TextDirection.rtl)),
    );

    try {
      if (_fetchedProgressData == null) {
        _fetchedProgressData = await _dataSource.getProgress().catchError((e) {
          print("Error fetching progress on demand for PDF: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('فشل تحميل بيانات التقدم المطلوبة للملف: $e',
                    textDirection: TextDirection.rtl)),
          );
          return null;
        });
      }

      final File pdfFile = await _pdfGeneratorService.generateReportPdf(
        widget.reportGroup,
        _fetchedProgressData,
      );
      await _pdfShareService.sharePdf(pdfFile,
          subject: 'تقرير شعور ${widget.reportGroup.groupName}');
    } catch (e) {
      print("Error generating/sharing PDF in DetailScreen: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('حدث خطأ أثناء تحضير الملف: $e',
                textDirection: TextDirection.rtl)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dynamicReportTitle =
        'تقرير شعور ${widget.reportGroup.groupName}';

    final int goodCount = widget.reportGroup.good.items.length;
    final int notGoodCount = widget.reportGroup.notGood.items.length;
    final int totalAttempts = goodCount + notGoodCount;
    final String testResultString =
    totalAttempts > 0 ? '$goodCount/$totalAttempts' : 'N/A';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: AppBar(
              leading: IconButton( // <-- إضافة أيقونة الرجوع المخصصة هنا
                icon: Icon(
                  Icons.keyboard_arrow_right_outlined, // شكل الأيقونة
                  size: 40,                             // حجم الأيقونة
                  color: _unifiedColor,                 // لون الأيقونة
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              iconTheme: IconThemeData(color: _unifiedColor), // لتلوين أيقونة المشاركة
              title: Text(
                dynamicReportTitle,
                style: TextStyle(color: _unifiedColor),
              ),
              centerTitle: true,
              actions: [
                if (_isProcessingPdf)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0), // تعديل الـ padding
                    child: SizedBox(
                        width: 24, // تعديل الحجم ليتناسب
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3, color: _unifiedColor)),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.share), // سيتم تلوينها بواسطة iconTheme
                    onPressed: _generateAndSharePdf,
                    tooltip: "مشاركة التقرير",
                  ),
              ],
            ),
          ),
        ),
        body: FutureBuilder<ProgressResponse>(
          future: _progressFuture,
          builder: (context, progressSnapshot) {
            String overallProgressString = 'جار التحميل...';
            if (progressSnapshot.connectionState == ConnectionState.done) {
              if (progressSnapshot.hasError) {
                overallProgressString = 'خطأ في التحميل';
              } else if (progressSnapshot.hasData) {
                overallProgressString = '${progressSnapshot.data!.progress}%';
              } else {
                overallProgressString = 'غير متوفر';
              }
            } else if (progressSnapshot.connectionState ==
                ConnectionState.waiting) {
              overallProgressString = 'جار التحميل...';
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildProgressAndTestResultSection(
                      context, overallProgressString, testResultString),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'المشاعر التي تم التدريب عليها:'),
                  _buildTrainedEmotionsSection(context,
                      widget.reportGroup.good.items, widget.reportGroup.notGood.items),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'ملخص أداء الطفل في الاختبار'),
                  _buildPerformanceSummarySection(context,
                      widget.reportGroup.good.items, widget.reportGroup.notGood.items),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'التوصيات:'),
                  _buildRecommendationsSection(
                      context, widget.reportGroup.recommendations.items),
                  const SizedBox(height: 32),
                  Center(
                    child: _isProcessingPdf
                        ? CircularProgressIndicator(color: _unifiedColor)
                        : ElevatedButton.icon(
                      icon: Icon(Icons.send, color: _unifiedColor),
                      label: Text(
                        'ارسال الى الاخصائى النفسي',
                        style: TextStyle(color: _unifiedColor),
                      ),
                      onPressed: _generateAndSharePdf,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressAndTestResultSection(
      BuildContext context, String progress, String result) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 1,
          child: _buildInfoCard(
            context,
            'نتيجة الاختبار',
            result,
            Icons.star_border,
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        Expanded(
          flex: 2,
          child: _buildInfoCard(
            context,
            'التقدم العام في التدريب',
            progress,
            Icons.show_chart,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      BuildContext context, String titleText, String valueText, IconData? iconData) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(
            titleText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: _unifiedColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: screenHeight * 0.09,
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (iconData != null)
                Icon(iconData, size: 20, color: _unifiedColor),
              if (iconData != null)
                const SizedBox(width: 8),
              Flexible(
                child: Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 18,
                    color: _unifiedColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold, color: _unifiedColor),
      ),
    );
  }

  Widget _buildTrainedEmotionsSection(BuildContext context,
      List<ReportItem> goodItems, List<ReportItem> notGoodItems) {
    final List<Widget> emotionWidgets = [];

    for (var item in goodItems) {
      emotionWidgets
          .add(_buildEmotionItem(context, '${item.title}: ${item.message}', true));
    }
    for (var item in notGoodItems) {
      emotionWidgets
          .add(_buildEmotionItem(context, '${item.title}: ${item.message}', false));
    }

    if (emotionWidgets.isEmpty) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('لا توجد بيانات لعرضها في هذا القسم.',
              style: TextStyle(color: _unifiedColor),
              textDirection: TextDirection.rtl));
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: emotionWidgets),
      ),
    );
  }

  Widget _buildEmotionItem(BuildContext context, String text, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.info_outline,
            color: isGood ? Colors.green : _unifiedColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
              child:
              Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _unifiedColor))),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummarySection(BuildContext context,
      List<ReportItem> goodItems, List<ReportItem> notGoodItems) {
    final List<Widget> summaryWidgets = [];

    for (var item in goodItems) {
      summaryWidgets
          .add(_buildPerformanceItem(context, '${item.title}: ${item.message}'));
    }
    for (var item in notGoodItems) {
      summaryWidgets
          .add(_buildPerformanceItem(context, '${item.title}: ${item.message}'));
    }

    if (summaryWidgets.isEmpty) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('لا توجد بيانات لعرضها في هذا القسم.',
              style: TextStyle(color: _unifiedColor),
              textDirection: TextDirection.rtl));
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: summaryWidgets),
      ),
    );
  }

  Widget _buildPerformanceItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _unifiedColor)),
          Expanded(
              child:
              Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _unifiedColor))),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(
      BuildContext context, List<RecommendationItem> recommendationItems) {
    if (recommendationItems.isEmpty) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child:
          Text('لا توجد توصيات لعرضها.', style: TextStyle(color: _unifiedColor), textDirection: TextDirection.rtl));
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: recommendationItems.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ',
                      style: TextStyle(fontSize: 16, color: _unifiedColor)),
                  Expanded(
                      child: Text(item.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _unifiedColor))),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}