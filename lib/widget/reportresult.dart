import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'customcard.dart';

class ReportDetails extends StatefulWidget {
  const ReportDetails({super.key});

  @override
  State<ReportDetails> createState() => _ReportDetailsState();
}

class _ReportDetailsState extends State<ReportDetails> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: Padding(
          padding: EdgeInsets.only(top: 30),
          child: AppBar(
            automaticallyImplyLeading: false,
            title: const Text(
              "تقرير الثلاثة أشهر الأولى",
              style: TextStyle(
                color: Color(0xFF2C73D9),
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_right_outlined,
                  size: 40,
                  color: Color(0xFF2C73D9),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
            leading: IconButton(
              onPressed: () {},
              icon: Icon(Icons.share_rounded),
              color: Color(0XFF2C73D9),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(9.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "التقدم العام في التدريب",
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF2C73D9),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Container(
                              height: screenHeight * 0.08,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FontAwesomeIcons.trophy,
                                      size: 20, color: Colors.blue),
                                  SizedBox(width: screenWidth * 0.08),
                                  Text(
                                    "10%",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF2C73D9),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.05),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Text(
                            ":نتيجة الاختبار",
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF2C73D9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Container(
                            height: screenHeight * 0.08,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: screenWidth * 0.05),
                                Text(
                                  "8/10",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF2C73D9),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  ":المشاعر التي تم التدريب عليها",
                  style: TextStyle(
                    color: Color(0xFF2C73D9),
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomEmotionCard(
                  title1: ":الفرح",
                  description1:
                      "تم التدريب على التعرف على الفرح في الصور والقصص.",
                  circleColor1: Colors.greenAccent,
                  title2: ":الحزن",
                  description2:
                      "بدأ التدريب على التعرف على الحزن وإدراكه  في الذات",
                  circleColor2: Color(0xFF2C73D9),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  ":ملخص أداء الطفل في الاختبار",
                  style: TextStyle(
                    color: Color(0xFF2C73D9),
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                CustomEmotionCard(
                  title1: ":الفرح",
                  description1:
                      "تم التدريب على التعرف على الفرح في الصور والقصص.",
                  circleColor1: Color(0xFF2C73D9),
                  title2: ":الحزن",
                  description2:
                      "بدأ التدريب على التعرف على الحزن وإدراكه  في الذات",
                  circleColor2: Color(0xFF2C73D9),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  ":التوصيات",
                  style: TextStyle(
                    color: Color(0xFF2C73D9),
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomEmotionCard(
                  title1: ":الفرح",
                  description1:
                      "تم التدريب على التعرف على الفرح في الصور والقصص.",
                  circleColor1: Color(0xFF2C73D9),
                  title2: ":الحزن",
                  description2:
                      "بدأ التدريب على التعرف على الحزن وإدراكه  في الذات",
                  circleColor2: Color(0xFF2C73D9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
