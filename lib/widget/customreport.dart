import 'package:flutter/material.dart';

class CustomInfoContainer extends StatelessWidget {
  final String title; // النص العلوي (يمكنك التحكم فيه)
  final String rightButtonText; // نص الزر الموجود على اليمين
  final String leftButtonText; // نص الزر الموجود على اليسار
  final VoidCallback? onRightButtonPressed;
  final VoidCallback? onLeftButtonPressed;

  const CustomInfoContainer({
    Key? key,
    required this.title,
    required this.rightButtonText,
    required this.leftButtonText,
    this.onRightButtonPressed,
    this.onLeftButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // استخدام MediaQuery لحساب عرض الشاشة
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.035),
      // مسافة من جوانب الشاشة
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // حواف دائرية أكبر
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            offset: const Offset(0, 3),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // النص العلوي محاذي لليمين
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C73D9),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 16),
          // صف الزرين
          Row(
            children: [
              // الزر الموجود على اليمين
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: onRightButtonPressed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 30),
                      decoration: BoxDecoration(
                        color: Color(0xFF2C73D9),
                        borderRadius:
                            BorderRadius.circular(30), // شكل بيضاوي أفقي
                      ),
                      child: Text(
                        rightButtonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.29),
              // زيادة المسافة بين الزرين باستخدام نسبة من عرض الشاشة
              // الزر الموجود على اليسار
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: onLeftButtonPressed,
                    child: Container(
                      //padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 30),
                      decoration: BoxDecoration(
                        color: Color(0xFF2C73D9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        leftButtonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
