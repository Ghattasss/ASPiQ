import 'package:flutter/material.dart';

class CustomEmotionCard extends StatelessWidget {
  final String title1;
  final String description1;
  final Color circleColor1; // لون الدائرة الأولى

  final String title2;
  final String description2;
  final Color circleColor2; // لون الدائرة الثانية

  const CustomEmotionCard({
    Key? key,
    required this.title1,
    required this.description1,
    required this.circleColor1,
    required this.title2,
    required this.description2,
    required this.circleColor2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02,
        ),
        width: screenWidth * 0.99,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ الصف الأول (دائرة 1 + نص)
            Row(
              children: [
                Container(
                  width: screenWidth * 0.04,
                  height: screenHeight * 0.02,
                  decoration: BoxDecoration(
                    color: circleColor1, // ✅ اللون متغير حسب ما تختاري
                    shape: BoxShape.circle,
                  ),
                  child: circleColor1 == Color(0xFF14AE5C)
                      ? Icon(Icons.check,
                          color: Colors.black, size: screenWidth * 0.05)
                      : null, // ✅ علامة ✔ فقط لو الدائرة خضراء
                ),
                SizedBox(width: screenWidth * 0.02),
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      text: "$title1: ",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF2C73D9),
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: description1,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2C73D9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.015),

            // ✅ الصف الثاني (دائرة 2 بداخلها دائرة أصغر + نص)
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: screenWidth * 0.04,
                      height: screenHeight * 0.02,
                      decoration: BoxDecoration(
                        color: circleColor2, // ✅ اللون متغير حسب ما تختاري
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: screenWidth * 0.02,
                      height: screenHeight * 0.01,
                      decoration: BoxDecoration(
                        color: circleColor2.withOpacity(0.7),
                        // ✅ دائرة أصغر بنفس اللون
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: screenWidth * 0.02),
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      text: "$title2: ",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF2C73D9),
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: description2,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2C73D9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
