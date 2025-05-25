import 'package:flutter/material.dart';
import 'package:myfinalpro/widget/reportresult.dart';

import 'customreport.dart';

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(90),
        child: Padding(
          padding: EdgeInsets.only(top: 20),
          child: AppBar(
            automaticallyImplyLeading: false,
            title: const Text(
              "التقارير",
              style: TextStyle(
                color: Color(0xFF2C73D9),
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              children: [
                CustomInfoContainer(
                  title: "تقرير الثلاثة أشهر الأولى",
                  // يمكنك تغيير النص حسب الحاجة
                  rightButtonText: "تنزيل",
                  leftButtonText: "عرض",
                  onRightButtonPressed: () {},
                  onLeftButtonPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ReportDetails()));
                  },
                ),
                SizedBox(
                  height: screenHeight * 0.03,
                ),
                CustomInfoContainer(
                  title: "تقرير الثلاثة أشهر الثانية",
                  // يمكنك تغيير النص حسب الحاجة
                  rightButtonText: "تنزيل",
                  leftButtonText: "عرض",
                  onRightButtonPressed: () {
                    // كود الضغط على الزر الموجود على اليمين
                  },
                  onLeftButtonPressed: () {
                    // كود الضغط على الزر الموجود على اليسار
                  },
                ),
                SizedBox(
                  height: screenHeight * 0.03,
                ),
                CustomInfoContainer(
                  title: "تقرير الثلاثة أشهر الثالثه",
                  // يمكنك تغيير النص حسب الحاجة
                  rightButtonText: "تنزيل",
                  leftButtonText: "عرض",
                  onRightButtonPressed: () {
                    // كود الضغط على الزر الموجود على اليمين
                  },
                  onLeftButtonPressed: () {
                    // كود الضغط على الزر الموجود على اليسار
                  },
                ),
                SizedBox(
                  height: screenHeight * 0.03,
                ),
                CustomInfoContainer(
                  title: "تقرير الثلاثة أشهر الرابعه",
                  // يمكنك تغيير النص حسب الحاجة
                  rightButtonText: "تنزيل",
                  leftButtonText: "عرض",
                  onRightButtonPressed: () {
                    // كود الضغط على الزر الموجود على اليمين
                  },
                  onLeftButtonPressed: () {
                    // كود الضغط على الزر الموجود على اليسار
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
