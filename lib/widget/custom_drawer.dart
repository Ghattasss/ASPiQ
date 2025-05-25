/*import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double circleSize = screenWidth * 0.4;
    final double editIconSize = circleSize * 0.3;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "حسناء حسني",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        "hasnaahosny1",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  children: [
                    Container(
                      width: screenWidth * 0.2,
                      height: screenWidth * 0.2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage("assets/images/image 4.png"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: screenWidth * 0.07,
                        height: screenWidth * 0.07,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          Icons.edit,
                          size: screenWidth * 0.04,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.person, "تعديل الملف الشخصي", () {
            Navigator.pushNamed(context, "editProfile");
          }),
          _buildDrawerItem(Icons.home_filled, "الصفحة الرئيسية", () {
            Navigator.pop(context); // إغلاق الدراور فقط
          }),
          _buildDrawerItem(Icons.notifications, "الإشعارات", () {
            Navigator.pushNamed(context, "notifications");
          }),
          _buildDrawerItem(Icons.list_alt_sharp, "التقارير", () {
            Navigator.pushNamed(context, "reports");
          }),
          _buildDrawerItem(Icons.smart_toy_outlined, "المساعد الذكي", () {
            Navigator.pushNamed(context, "chatbot");
          }),
          _buildDrawerItem(Icons.help_outline, "حول التطبيق", () {
            Navigator.pushNamed(context, "aboutApp");
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        leading: Icon(icon, color: Color(0xFF2C73D9)),
        title: Text(title,
            style: TextStyle(fontSize: 20, color: Color(0xFF2C73D9))),
        trailing:
            Icon(Icons.keyboard_arrow_left, color: Color(0xFF2C73D9), size: 35),
        onTap: onTap,
      ),
    );
  }
}*/
