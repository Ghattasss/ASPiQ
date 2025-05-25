import 'package:flutter/material.dart';
import 'package:myfinalpro/test/models/quiz_model.dart'; // تأكد من المسار الصحيح
import 'package:myfinalpro/test/sucess_popup.dart';     // تأكد من المسار الصحيح

class QuizType1Screen extends StatelessWidget {
  final QuizDetail detail;
  final Function(bool isCorrect) onAnswerSelected;
  final bool isCompleting;

  const QuizType1Screen({
    super.key,
    required this.detail,
    required this.onAnswerSelected,
    this.isCompleting = false,
  });

  Future<void> _checkAnswer(BuildContext context, String selectedAnswer) async {
    if (isCompleting) return;

    bool isCorrect = selectedAnswer == detail.rightAnswer;
    debugPrint("QuizType1: Selected: $selectedAnswer, Correct: ${detail.rightAnswer}, IsCorrect: $isCorrect");

    if (isCorrect) {
      try {
        await showSuccessPopup(context, () {
          debugPrint("QuizType1: Success popup closed.");
        });
        if (context.mounted) {
          onAnswerSelected(true);
        }
      } catch (e) {
        debugPrint("QuizType1: Error in success popup: $e");
        if (context.mounted) {
          onAnswerSelected(true);
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('إجابة خاطئة!'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        );
        onAnswerSelected(false);
      }
    }
  }

  Widget _buildImageErrorWidget(BuildContext context, Object error, StackTrace? stackTrace, String? attemptedPath) {
     debugPrint("Error loading asset: $attemptedPath\n$error");
     return Container(
       padding: const EdgeInsets.all(10), alignment: Alignment.center,
       decoration: BoxDecoration( color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
       child: Column( mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
           Icon(Icons.broken_image_outlined, color: Colors.red.shade400, size: 40),
           const SizedBox(height: 8),
           Text('خطأ تحميل الصورة', textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
           if (attemptedPath != null) Padding( padding: const EdgeInsets.only(top: 4.0), child: Text( '(المسار: $attemptedPath)', textDirection: TextDirection.ltr, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 10),),),
         ],),);
   }

  @override
  Widget build(BuildContext context) {
    final assetPath = detail.localAssetPath;
    final currentQuestion = detail.questions ?? "ما هو المطلوب؟";
    final options = detail.answerOptions;

    return Scaffold(
      backgroundColor: const Color(0xff2C73D9),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false,
        actions: [ Padding( padding: const EdgeInsets.only(top: 8.0, right: 8.0), child: IconButton( icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 32), onPressed: () => Navigator.pop(context), tooltip: 'العودة',),),],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
                Text( currentQuestion, textAlign: TextAlign.center, style: const TextStyle( fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),),
                const SizedBox(height: 32),
                if (detail.hasImage && assetPath != null)
                  Container( width: 310, height: 350,
                    decoration: BoxDecoration( borderRadius: BorderRadius.circular(10), color: Colors.white, boxShadow: [ BoxShadow( color: Colors.black.withAlpha((255 * 0.1).round()), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3),)],),
                    child: ClipRRect( borderRadius: BorderRadius.circular(10), child: Image.asset( assetPath, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildImageErrorWidget(context, error, stackTrace, assetPath),
                      ),),),
                if (detail.hasText && !detail.hasImage)
                    Padding( padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text( detail.text!, 
                       style: const TextStyle(fontSize: 18, color: Colors.white, height: 1.5), textAlign: TextAlign.center,),),
                const SizedBox(height: 32),
                if (options.isNotEmpty)
                  ...options.map((option) => Padding( padding: const EdgeInsets.only(bottom: 16.0),
                        child: SizedBox( width: 300, height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom( backgroundColor: Colors.white, foregroundColor: const Color(0xff2C73D9), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(10),), elevation: 3, disabledBackgroundColor: Colors.grey.shade300, disabledForegroundColor: Colors.grey.shade500,),
                            onPressed: isCompleting ? null : () => _checkAnswer(context, option),
                            child: isCompleting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xff2C73D9),)) : Text( option, style: const TextStyle( fontSize: 18, fontWeight: FontWeight.bold,),),
                          ),),),)
                 ,
                 if (isCompleting && options.isEmpty) // مؤشر تحميل إذا كان isCompleting ولا توجد خيارات (حالة نادرة)
                    const Padding( padding: EdgeInsets.only(top: 20.0), child: CircularProgressIndicator(color: Colors.white)),
              ],),),),),);
  }
}