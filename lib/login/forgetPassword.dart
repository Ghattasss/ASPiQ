import 'package:flutter/material.dart';
import 'package:myfinalpro/registration/Code%20verification.dart'; // تأكد من المسار الصحيح

import '../services/Api_services.dart'; // استيراد ApiService

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({Key? key}) : super(key: key);

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  String? selectedMethod;
  bool isLoading = false;
  String? errorMessage;
  final _emailFormKey = GlobalKey<FormState>(); // مفتاح للتحقق من صحة الإيميل

  // إرسال OTP عبر البريد الإلكتروني باستخدام ApiService
  Future<void> sendOTPByEmail(String email, BuildContext dialogContext) async {
    // استلام context الحوار
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    // أغلق مربع الحوار قبل بدء التحميل في الشاشة الرئيسية
    Navigator.pop(dialogContext);

    try {
      final result = await ApiService.sendOtp(email, 'email');

      // تحقق من أن الويدجت لا يزال جزءًا من الشجرة قبل تحديث الحالة
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        final token = result['token'];
        final message = result['message'] ?? 'تم إرسال الرمز بنجاح.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CodeVerification(token: token!, email: email),
          ),
        );
      } else {
        setState(() {
          errorMessage = result['message'] ?? "حدث خطأ أثناء إرسال رمز التحقق";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage =
        "تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.";
        print("Error in sendOTPByEmail: $e");
      });
    }
  }

  // إرسال OTP عبر الهاتف (يحتاج API خاص به)
  Future<void> sendOTPByPhone(String phone, BuildContext context) async {
    setState(() {
      errorMessage = "إعادة التعيين عبر الهاتف غير مدعومة حاليًا.";
      isLoading = false; // تأكد من إيقاف التحميل
    });
    Navigator.pop(context); // أغلق مربع الحوار
    // ملاحظة: إذا توفر API للهاتف، قم باستدعائه هنا
    // final result = await ApiService.sendOtp(phone, 'phone'); // أو دالة مخصصة للهاتف
    // ... handle result ...
    // Navigator.push(context, MaterialPageRoute(builder: (context) => Resetpasswordbyphone()));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double boxSize = screenWidth * 0.06;
    double iconBoxSize = screenWidth * 0.12;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: Text(
            "نسيت كلمة المرور؟",
            style: TextStyle(
              color: Color(0xFF2C73D9),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 8.0),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context); // رجوع للشاشة السابقة
              },
              icon: Icon(
                Icons.keyboard_arrow_right_outlined,
                size: 40,
                color: Color(0xFF2C73D9),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.05),
              Center(
                child: Image.asset(
                  "assets/images/amico.png", // تأكد من وجود الصورة
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.29,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: screenHeight * 0.07),
              Text(
                "كيف تفضل استعادة حسابك؟",
                style: TextStyle(
                  color: Color(0xFF2C73D9),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // عرض رسالة الخطأ إذا وجدت
              if (errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              // صف المتابعة عبر البريد الإلكتروني
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedMethod = "email";
                    errorMessage = null; // مسح الخطأ عند تغيير الاختيار
                  });
                },
                child: Container(
                  // جعل الصف كله قابل للنقر
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: boxSize,
                        height: boxSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: Color(0xFF2C73D9), width: 2),
                          color: selectedMethod == "email"
                              ? Colors.blue
                              : Colors.transparent,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "المتابعة عبر البريد الإلكتروني",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.002),
                            Text(
                              "البريد الإلكتروني المرتبط بحسابك",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: iconBoxSize,
                            height: iconBoxSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2C73D9),
                            ),
                          ),
                          Icon(
                            Icons.alternate_email,
                            color: Colors.white,
                            size: screenWidth * 0.06,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // صف المتابعة عبر رقم الهاتف
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedMethod = "phone";
                    errorMessage = null; // مسح الخطأ عند تغيير الاختيار
                  });
                },
                child: Container(
                  // جعل الصف كله قابل للنقر
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: boxSize,
                        height: boxSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: Color(0xFF2C73D9), width: 2),
                          color: selectedMethod == "phone"
                              ? Colors.blue
                              : Colors.transparent,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "المتابعة عبر رقم الهاتف",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.002),
                            Text(
                              "رقم الهاتف المرتبط بحسابك",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: iconBoxSize,
                            height: iconBoxSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2C73D9),
                            ),
                          ),
                          Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: screenWidth * 0.06,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.08),

              // زر المتابعة
              ElevatedButton(
                onPressed: isLoading
                    ? null // تعطيل الزر أثناء التحميل
                    : () {
                  if (selectedMethod == "email") {
                    _showEmailInputDialog(context);
                  } else if (selectedMethod == "phone") {
                    _showPhoneInputDialog(context);
                  } else {
                    setState(() {
                      errorMessage =
                      "الرجاء اختيار طريقة لاستعادة الحساب";
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2C73D9),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ))
                    : const Text(
                  "متابعة",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: screenHeight * 0.02), // مسافة إضافية
            ],
          ),
        ),
      ),
    );
  }

  // مربع حوار لإدخال البريد الإلكتروني
  void _showEmailInputDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      // منع الإغلاق بالنقر خارج الحوار أثناء التحميل المحتمل
      barrierDismissible: !isLoading,
      builder: (dialogContext) => AlertDialog(
        // استخدام dialogContext منفصل
        title: Text("أدخل البريد الإلكتروني", textAlign: TextAlign.center),
        content: Form(
          // استخدام Form للتحقق
          key: _emailFormKey,
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
                hintText: "أدخل بريدك الإلكتروني",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined)),
            textAlign: TextAlign.right,
            // مناسب للعربية
            textDirection: TextDirection.rtl,
            // مناسب للعربية
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال البريد الإلكتروني';
              }
              // تحقق أساسي من @ والنقطة
              if (!value.contains('@') || !value.contains('.')) {
                return 'الرجاء إدخال بريد إلكتروني صحيح';
              }
              return null; // صالح
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              // التحقق من صحة الفورم قبل الإرسال
              if (_emailFormKey.currentState!.validate()) {
                final email = emailController.text.trim();
                // استدعاء الدالة وتمرير context الحوار لإغلاقه
                sendOTPByEmail(email, dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2C73D9),
            ),
            child: Text("إرسال", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // مربع حوار لإدخال رقم الهاتف
  void _showPhoneInputDialog(BuildContext context) {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (dialogContext) => AlertDialog(
        title: Text("أدخل رقم الهاتف", textAlign: TextAlign.center),
        content: TextField(
          controller: phoneController,
          decoration: InputDecoration(
              hintText: "أدخل رقم الهاتف المرتبط بحسابك",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_outlined)),
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
          // الأرقام عادة LTR
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              if (phoneController.text.trim().isNotEmpty) {
                // استدعاء الدالة وتمرير context الحوار لإغلاقه
                sendOTPByPhone(phoneController.text.trim(), dialogContext);
              } else {
                // يمكن إضافة رسالة خطأ هنا إذا كان الحقل فارغًا
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("الرجاء إدخال رقم الهاتف")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2C73D9),
            ),
            child: Text("إرسال", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}