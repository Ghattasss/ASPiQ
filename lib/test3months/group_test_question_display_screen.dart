import 'package:flutter/material.dart';
import 'group_test_manager_screen.dart'; // لاستيراد GeneratedQuestion

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
    // ... (هذه الدالة تبقى كما هي من الرد السابق)
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
              errorBuilder: (ctx, err, st) => Container(
                  height: height,
                  width: elementWidth,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.grey.shade400, size: 50)))));
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
    // --- تعديل: جعل عرض زر الصورة أكبر ---
    final double buttonWidth = screenWidth * 0.75; // يمكنك تعديل هذه النسبة
    final double buttonHeight =
        buttonWidth * 0.8; // للحفاظ على نسبة معقولة، أو اجعلها ثابتة

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 8.0), // مسافة رأسية بين أزرار الصور
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
                debugPrint(
                    "Image option selected. ImagePath: $imagePath, Textual value: $textualValueForComparison, Correct answer for Q: ${question.correctAnswer}");
                onAnswerSelected(
                    textualValueForComparison == question.correctAnswer);
              },
        borderRadius: BorderRadius.circular(16), // زيادة دائرية الحواف
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // زيادة دائرية الحواف
              side: BorderSide(
                  color: Colors.white.withOpacity(0.7),
                  width: 2) // إطار أسمك قليلاً
              ),
          color: Colors.white.withOpacity(0.95),
          child: Container(
            // استخدام Container لتحديد الحجم
            width: buttonWidth,
            height: buttonHeight,
            padding: const EdgeInsets.all(6.0),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain, // contain للحفاظ على الصورة كاملة
              errorBuilder: (ctx, err, st) {
                debugPrint(
                    "Error loading asset in _buildImageOptionButton: $imagePath - $err");
                return Container(
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.grey.shade500)),
                );
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
    const Color questionCardBgColor = Colors.white;
    const Color questionCardTextColor = primaryBlue;

    // Check if this is a session with ID > 28
    final bool isSpecialSession =
        question.sectionTitle.contains("تحية الاخرين") ||
            question.sectionTitle.contains("التواصل اللفظي");

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
              if (!isSpecialSession)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                      color: questionCardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2))
                      ]),
                  child: Text(
                    question.questionText,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: questionCardTextColor,
                        height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Display the image (only the first image for special session)
              if (question.imagePath1 != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
                  child: _buildSingleDisplayElement(
                      context, question.imagePath1, question.textContent1),
                ),

              const SizedBox(height: 24),

              // Display options
              if (isSpecialSession)
                // Special session options (صح - خطأ)
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
              else
                // Regular session options
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
