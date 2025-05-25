// import 'package:flutter/material.dart';
// import 'package:myfinalpro/widget/about_app.dart';
// import 'package:myfinalpro/widget/chatpot.dart';
// import 'package:myfinalpro/widget/editaccount.dart';
// import 'package:myfinalpro/widget/report.dart';
//
// //import 'package:myfinalpro/widget/seesion.dart';
//
// import '../session/seesion.dart';
//
// class SideBarMenuTest extends StatefulWidget {
//   const SideBarMenuTest({Key? key}) : super(key: key);
//
//   @override
//   State<SideBarMenuTest> createState() => _SideBarMenuTestState();
// }
//
// class _SideBarMenuTestState extends State<SideBarMenuTest> {
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final double circleSize = screenWidth * 0.4;
//     final double editIconSize = circleSize * 0.3;
//
//     return Scaffold(
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               margin: EdgeInsets.zero,
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   // العمود الذي يحتوي على النصوص
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       mainAxisSize: MainAxisSize.min,
//                       children: const [
//                         Text(
//                           "حسناء حسني",
//                           style: TextStyle(
//                             color: Colors.blue,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                         Text(
//                           "hasnaahosny1",
//                           style: TextStyle(
//                             color: Colors.grey,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 12), // مسافة صغيرة بين العمود والصورة
//                   // الصورة مع أيقونة التعديل
//                   Stack(
//                     children: [
//                       Container(
//                         width: screenWidth * 0.2,
//                         height: screenWidth * 0.2,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           image: DecorationImage(
//                             image: AssetImage("assets/images/image 4.png"),
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         bottom: 0,
//                         right: 0,
//                         child: Container(
//                           width: screenWidth * 0.07,
//                           height: screenWidth * 0.07,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: Colors.white,
//                           ),
//                           child: Icon(
//                             Icons.edit,
//                             size: screenWidth * 0.04,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             // مثال على ListTile مع onTap لجعل الصف قابل للنقر بالكامل
//             Directionality(
//               textDirection: TextDirection.rtl,
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 leading: const Icon(
//                   Icons.person,
//                   color: Color(0xFF2C73D9),
//                 ),
//                 title: const Text(
//                   "تعديل الملف الشخصي",
//                   style: TextStyle(fontSize: 20, color: Color(0xFF2C73D9)),
//                 ),
//                 trailing: const Icon(
//                   Icons.keyboard_arrow_left,
//                   color: Color(0xFF2C73D9),
//                   size: 35,
//                 ),
//                 onTap: () {
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => EditProfileScreen()));
//                 },
//               ),
//             ),
//             const SizedBox(height: 8),
//             Directionality(
//               textDirection: TextDirection.rtl,
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 leading: const Icon(
//                   Icons.home_filled,
//                   color: Color(0xFF2C73D9),
//                 ),
//                 title: const Text(
//                   "الصفحة الرئيسية",
//                   style: TextStyle(fontSize: 20, color: Color(0xFF2C73D9)),
//                 ),
//                 trailing: const Icon(
//                   Icons.keyboard_arrow_left,
//                   color: Color(0xFF2C73D9),
//                   size: 35,
//                 ),
//                 onTap: () {
//                   // ضع هنا كود التنقل للصفحة الرئيسية
//                   print("الصفحة الرئيسية");
//                 },
//               ),
//             ),
//             const SizedBox(height: 8),
//             Directionality(
//               textDirection: TextDirection.rtl,
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 leading: const Icon(
//                   Icons.notifications,
//                   color: Color(0xFF2C73D9),
//                 ),
//                 title: const Text(
//                   "الإشعارات",
//                   style: TextStyle(fontSize: 20, color: Color(0xFF2C73D9)),
//                 ),
//                 trailing: const Icon(
//                   Icons.keyboard_arrow_left,
//                   color: Color(0xFF2C73D9),
//                   size: 35,
//                 ),
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => SessionView()));
//                 },
//               ),
//             ),
//             const SizedBox(height: 8),
//             Directionality(
//               textDirection: TextDirection.rtl,
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 leading: const Icon(
//                   Icons.list_alt_sharp,
//                   color: Color(0xFF2C73D9),
//                 ),
//                 title: const Text(
//                   "التقارير",
//                   style: TextStyle(
//                     fontSize: 20,
//                     color: Color(0xFF2C73D9),
//                   ),
//                 ),
//                 trailing: const Icon(
//                   Icons.keyboard_arrow_left,
//                   color: Color(0xFF2C73D9),
//                   size: 35,
//                 ),
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => ReportView()));
//                 },
//               ),
//             ),
//             const SizedBox(height: 8),
//             Directionality(
//               textDirection: TextDirection.rtl,
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 leading: const Icon(
//                   Icons.smart_toy_outlined,
//                   color: Color(0xFF2C73D9),
//                 ),
//                 title: const Text(
//                   "المساعد الذكي",
//                   style: TextStyle(fontSize: 20, color: Color(0xFF2C73D9)),
//                 ),
//                 trailing: const Icon(
//                   Icons.keyboard_arrow_left,
//                   color: Color(0xFF2C73D9),
//                   size: 35,
//                 ),
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => ChatBotScreen()));
//                 },
//               ),
//             ),
//             const SizedBox(height: 8),
//             Directionality(
//               textDirection: TextDirection.rtl,
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 leading: const Icon(
//                   Icons.help_outline,
//                   color: Color(0xFF2C73D9),
//                 ),
//                 title: const Text(
//                   "حول التطبيق",
//                   style: TextStyle(fontSize: 20, color: Color(0xFF2C73D9)),
//                 ),
//                 trailing: const Icon(
//                   Icons.keyboard_arrow_left,
//                   color: Color(0xFF2C73D9),
//                   size: 35,
//                 ),
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => About_App()));
//                 },
//               ),
//             ),
//             // يمكنك إضافة المزيد من عناصر القائمة هنا...
//           ],
//         ),
//       ),
//       appBar: AppBar(
//         title: const Text('اختبار سايد بار'),
//       ),
//       body: const Center(
//         child: Text('هذه شاشة اختبار للسايد بار'),
//       ),
//     );
//   }
// }
//
// void main() {
//   runApp(const MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: SideBarMenuTest(),
//   ));
// }