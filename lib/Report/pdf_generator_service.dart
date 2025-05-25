import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'child_report_model.dart'; // Adjusted path
import 'progress_model.dart'; // Adjusted path

class PdfGeneratorService {
  Future<File> generateReportPdf(
    ChildReportGroup reportGroup,
    ProgressResponse? progressData,
  ) async {
    final pdf = pw.Document();

    final String dynamicPdfTitle = 'تقرير شعور ${reportGroup.groupName}';

    final arabicFontData = await rootBundle.load(
      "assets/fonts/NotoNaskhArabic-Regular.ttf",
    );
    final pw.Font arabicFont = pw.Font.ttf(arabicFontData);

    final PdfColor primaryAppColor = PdfColor.fromHex("#2C73D9");
    final PdfColor greenCheckColor = PdfColors.green;
    final PdfColor cardBackgroundColor = PdfColors.white;
    final PdfColor cardBorderColor = PdfColors.grey300;
    final PdfColor defaultTextColor = primaryAppColor;

    final int goodCount = reportGroup.good.items.length;
    final int notGoodCount = reportGroup.notGood.items.length;
    final int totalAttempts = goodCount + notGoodCount;
    final String testResultString =
        totalAttempts > 0 ? '$goodCount/$totalAttempts' : 'N/A';

    final String overallProgressString =
        progressData != null ? '${progressData.progress}%' : 'غير متوفر';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
        ),
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8.0),
                child: pw.Text(
                  dynamicPdfTitle,
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 24,
                    color: primaryAppColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildPdfInfoCard(
                      'التقدم العام في التدريب',
                      overallProgressString,
                      arabicFont,
                      primaryAppColor,
                      primaryAppColor,
                      cardBackgroundColor,
                      cardBorderColor,
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: _buildPdfInfoCard(
                      'نتيجة الاختبار',
                      testResultString,
                      arabicFont,
                      primaryAppColor,
                      primaryAppColor,
                      cardBackgroundColor,
                      cardBorderColor,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              _buildPdfSectionTitle('المشاعر التي تم التدريب عليها:', arabicFont, primaryAppColor),
              _buildPdfTrainedEmotions(
                reportGroup.good.items,
                reportGroup.notGood.items,
                arabicFont,
                greenCheckColor,
                primaryAppColor,
                defaultTextColor,
                cardBackgroundColor,
                cardBorderColor,
              ),
              pw.SizedBox(height: 24),
              _buildPdfSectionTitle('ملخص أداء الطفل في الاختبار', arabicFont, primaryAppColor),
              _buildPdfPerformanceSummary(
                reportGroup.good.items,
                reportGroup.notGood.items,
                arabicFont,
                primaryAppColor,
                defaultTextColor,
                cardBackgroundColor,
                cardBorderColor,
              ),
              pw.SizedBox(height: 24),
              _buildPdfSectionTitle('التوصيات:', arabicFont, primaryAppColor),
              _buildPdfRecommendations(
                reportGroup.recommendations.items,
                arabicFont,
                primaryAppColor,
                defaultTextColor,
                cardBackgroundColor,
                cardBorderColor,
              ),
            ],
          ),
        ],
      ),
    );

    final outputDir = await getTemporaryDirectory();
    final sanitizedGroupName = reportGroup.groupName.replaceAll(
      RegExp(r'[^a-zA-Z0-9_ء-ي]'),
      '_',
    );
    final file = File("${outputDir.path}/child_report_$sanitizedGroupName.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ... (باقي الدوال المساعدة _buildPdfInfoCard, _buildPdfSectionTitle, إلخ. تبقى كما هي)
  pw.Widget _buildPdfInfoCard(
      String title, String value, pw.Font font,
      PdfColor titleColor, PdfColor valueColor,
      PdfColor backgroundColor, PdfColor borderColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        border: pw.Border.all(color: borderColor, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(title,
              style: pw.TextStyle(font: font, fontSize: 10, color: titleColor)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
                font: font,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: valueColor),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSectionTitle(
      String title, pw.Font font, PdfColor titleColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8.0),
      child: pw.Text(
        title,
        style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: titleColor),
      ),
    );
  }

  pw.Widget _buildPdfTrainedEmotions(
    List<ReportItem> goodItems,
    List<ReportItem> notGoodItems,
    pw.Font font,
    PdfColor goodIconColor,
    PdfColor notGoodIconColor,
    PdfColor textColor,
    PdfColor backgroundColor,
    PdfColor borderColor,
  ) {
    final List<pw.Widget> emotionWidgets = [];

    for (var item in goodItems) {
      emotionWidgets.add(
        _buildPdfEmotionItem(
            '${item.title}: ${item.message}', true, font, goodIconColor, textColor),
      );
    }
    for (var item in notGoodItems) {
      emotionWidgets.add(
        _buildPdfEmotionItem(
            '${item.title}: ${item.message}', false, font, notGoodIconColor, textColor),
      );
    }

    if (emotionWidgets.isEmpty) {
      return pw.Text(
        'لا توجد بيانات لعرضها في هذا القسم.',
        style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey400),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16.0),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        border: pw.Border.all(color: borderColor, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(children: emotionWidgets),
    );
  }

  pw.Widget _buildPdfEmotionItem(String text, bool isGood, pw.Font font,
      PdfColor iconColor, PdfColor textColor) {
    String iconChar = isGood ? "✓ " : "ⓘ ";

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
      child: pw.Row(
        children: [
          pw.Text(
            iconChar,
            style: pw.TextStyle(
              font: font,
              color: iconColor,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(text,
                style: pw.TextStyle(font: font, fontSize: 12, color: textColor)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfPerformanceSummary(
    List<ReportItem> goodItems,
    List<ReportItem> notGoodItems,
    pw.Font font,
    PdfColor bulletColor,
    PdfColor textColor,
    PdfColor backgroundColor,
    PdfColor borderColor,
  ) {
    final List<pw.Widget> summaryWidgets = [];

    for (var item in goodItems) {
      summaryWidgets.add(
        _buildPdfPerformanceItem(
            '${item.title}: ${item.message}', font, bulletColor, textColor),
      );
    }
    for (var item in notGoodItems) {
      summaryWidgets.add(
        _buildPdfPerformanceItem(
            '${item.title}: ${item.message}', font, bulletColor, textColor),
      );
    }

    if (summaryWidgets.isEmpty) {
      return pw.Text(
        'لا توجد بيانات لعرضها في هذا القسم.',
        style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey400),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16.0),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        border: pw.Border.all(color: borderColor, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: summaryWidgets,
      ),
    );
  }

  pw.Widget _buildPdfPerformanceItem(
      String text, pw.Font font, PdfColor bulletColor, PdfColor textColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '• ',
            style: pw.TextStyle(
                font: font,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: bulletColor),
          ),
          pw.Expanded(
            child: pw.Text(text,
                style: pw.TextStyle(font: font, fontSize: 12, color: textColor)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfRecommendations(
    List<RecommendationItem> recommendationItems,
    pw.Font font,
    PdfColor bulletColor,
    PdfColor textColor,
    PdfColor backgroundColor,
    PdfColor borderColor,
  ) {
    if (recommendationItems.isEmpty) {
      return pw.Text(
        'لا توجد توصيات لعرضها.',
        style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey400),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16.0),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        border: pw.Border.all(color: borderColor, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: recommendationItems.map((item) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '• ',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 16,
                    color: bulletColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    item.message,
                    style: pw.TextStyle(
                        font: font, fontSize: 12, color: textColor),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}