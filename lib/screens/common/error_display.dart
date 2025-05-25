// lib/screens/common/error_display.dart
import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback onRetry; // دالة لإعادة المحاولة

  const ErrorDisplay({Key? key, required this.message, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Colors.white, // أو لون مناسب
       body: Center(
         child: Padding(
           padding: const EdgeInsets.all(20.0),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.error_outline, color: Colors.redAccent.shade200, size: 60),
               const SizedBox(height: 20),
               Text(
                 message,
                 textAlign: TextAlign.center,
                 style: TextStyle(color: Colors.red.shade700, fontSize: 18, fontFamily: 'Cairo'),
                ),
               const SizedBox(height: 30),
               ElevatedButton.icon(
                 icon: const Icon(Icons.refresh), // أيقونة إعادة المحاولة
                 label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor, // لون الزر
                    foregroundColor: Colors.white, // لون النص والأيقونة
                     padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                     textStyle: const TextStyle(fontSize: 16, fontFamily: 'Cairo')
                  ),
                 onPressed: onRetry, // استدعاء الدالة عند الضغط
               ),
             ],
           ),
         ),
       ),
     );
  }
}