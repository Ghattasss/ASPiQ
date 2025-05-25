import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;
  const LoadingIndicator({Key? key, this.message = 'جاري التحميل...'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // استخدام Scaffold لملء الشاشة وتوفير خلفية
    return Scaffold(
      backgroundColor: Colors.white, // أو لون مناسب لواجهتك
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
            const SizedBox(height: 20),
            Text(
                message,
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                     fontFamily: 'Cairo'
                 )
             ),
          ],
        ),
      ),
    );
  }
}