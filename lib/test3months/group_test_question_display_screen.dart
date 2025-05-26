import 'package:flutter/material.dart';
import 'dart:math'; // لاستخدام min
import 'group_test_manager_screen.dart'; // لاستيراد GeneratedQuestion

// --- الودجت المضافة هنا كدالة على مستوى الملف ---
Widget _buildImageErrorWidget(BuildContext context, Object error,
    StackTrace? stackTrace, String? attemptedPath) {
  debugPrint("Error loading asset image: $attemptedPath\n$error");
  return Container(
    padding: const EdgeInsets.all(10),
    alignment: Alignment.center,
    decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200)),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined,
            color: Colors.red.shade400, size: 40),
        const SizedBox(height: 8),
        Text('خطأ تحميل الصورة',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        if (attemptedPath != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '(المسار: $attemptedPath)',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ),
      ],
    ),
  );
}
// --- نهاية الودجت المضافة ---

class GroupTestQuestionDisplayScreen extends StatelessWidget {
  final String appBarTitle;
  final GeneratedQuestion question;
  final bool isLoading;
  final Function(bool isCorrect) onAnswerSelected;

  const GroupTestQuestionDisplayScreen({
    super.key,
    required this.appBarTitle,
    required this.question,
    required this.isLoading,
    required this.onAnswerSelected,
  });

  Widget _buildSingleDisplayElement(
      BuildContext context, String? imagePath, String? textContent,
      {double height = 230}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final elementWidth = screenWidth * 0.85;
    BoxFit imageFit = BoxFit.contain;
    Widget content;
    if (imagePath != null) {
      content = ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Image.asset(imagePath,
              key: ValueKey(
                  imagePath + DateTime.now().millisecondsSinceEpoch.toString()),
              height: height,
              width: elementWidth,
              fit: imageFit,
              errorBuilder: (ctx, err, st) =>
                  _buildImageErrorWidget(ctx, err, st, imagePath)));
    } else if (textContent != null) {
      content = Container(
          padding: const EdgeInsets.all(12.0),
          width: elementWidth,
          constraints: BoxConstraints(minHeight: height * 0.5),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: Offset(0, 1))
              ]),
          child: Center(
              child: Text(textContent,
                  style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Cairo',
                      color: Color(0xFF333333),
                      height: 1.5),
                  textAlign: TextAlign.center)));
    } else {
      content = Container(
          height: height,
          width: elementWidth,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Center(
              child: Icon(Icons.help_outline,
                  color: Colors.grey.shade400, size: 60)));
    }
    return Center(child: content);
  }

  Widget _buildImageOptionButton(BuildContext context, String? imagePath,
      String textualValueForComparison) {
    if (imagePath == null) {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final double buttonWidth = screenWidth * 0.75;
    final double buttonHeight = buttonWidth * 0.8;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
                debugPrint(
                    "Image option selected. ImagePath: $imagePath, Textual value: $textualValueForComparison, Correct answer for Q: ${question.correctAnswer}");
                onAnswerSelected(
                    textualValueForComparison == question.correctAnswer);
              },
        borderRadius: BorderRadius.circular(16),
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: Colors.white.withOpacity(0.7), width: 2)),
          color: Colors.white.withOpacity(0.95),
          child: Container(
            width: buttonWidth,
            height: buttonHeight,
            padding: const EdgeInsets.all(6.0),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, st) {
                return _buildImageErrorWidget(ctx, err, st, imagePath);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2C73D9);
    // const Color questionCardBgColor = Colors.white; // لم نعد بحاجة إليها هنا لهذا العنصر تحديدًا
    // const Color questionCardTextColor = primaryBlue; // سنستخدم الأبيض بدلاً منه

    final bool isSpecialSession =
        question.parentSessionId > 28;

    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        title: isSpecialSession
            ? const SizedBox.shrink()
            : Text(appBarTitle,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: AbsorbPointer(
        absorbing: isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (question.questionText.isNotEmpty)
                // *** بداية التعديل لحذف الخلفية ***
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0), // يمكن تعديل الـ padding حسب الرغبة
                  margin: const EdgeInsets.only(bottom: 24), // يمكن تعديل الـ margin حسب الرغبة
                  // تم حذف الـ decoration
                  child: Text(
                    question.questionText,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Colors.white, // تغيير لون النص إلى الأبيض
                        height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ),
              // *** نهاية التعديل ***

              if (question.imagePath1 != null || question.textContent1 != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
                  child: _buildSingleDisplayElement(
                      context, question.imagePath1, question.textContent1,
                      height: isSpecialSession ? 300 : 230),
                ),

              const SizedBox(height: 24),

              if (isSpecialSession)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () =>
                              onAnswerSelected("صح" == question.correctAnswer),
                      child: const Text("صح",
                          style: TextStyle(
                              fontSize: 17,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryBlue,
                        minimumSize: const Size(double.infinity, 55),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.8),
                                width: 1.5)),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () =>
                              onAnswerSelected("خطأ" == question.correctAnswer),
                      child: const Text("خطأ",
                          style: TextStyle(
                              fontSize: 17,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryBlue,
                        minimumSize: const Size(double.infinity, 55),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.8),
                                width: 1.5)),
                        elevation: 2,
                      ),
                    ),
                  ],
                )
              else if (question.isImageOptions && question.optionImagePaths.isNotEmpty)
                Column(
                  children: List.generate(
                    min(question.options.length, question.optionImagePaths.length), 
                    (index) {
                      final imagePath = question.optionImagePaths[index];
                      final textualValue = question.options[index];
                      return _buildImageOptionButton(context, imagePath, textualValue);
                    }
                  ).toList(),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: question.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = question.options[index];
                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => onAnswerSelected(
                              option == question.correctAnswer),
                      child: Text(option,
                          style: const TextStyle(
                              fontSize: 17,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryBlue,
                        minimumSize: const Size(double.infinity, 55),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.8),
                                width: 1.5)),
                        elevation: 2,
                      ),
                    );
                  },
                ),

              if (isLoading && ModalRoute.of(context)!.isCurrent)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.8)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}