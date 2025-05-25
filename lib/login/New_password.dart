import 'package:flutter/material.dart';

import '../services/Api_services.dart'; // استيراد ApiService
import 'login_view.dart'; // استيراد شاشة تسجيل الدخول للانتقال إليها

class NewPasswordScreen extends StatefulWidget {
  final String token; // الـ Token المستلم من الخطوة السابقة (Send-OTP)

  const NewPasswordScreen({Key? key, required this.token}) : super(key: key);

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    setState(() {
      _errorMessage = null; // مسح الأخطاء السابقة
    });

    // التحقق من صحة الفورم
    if (!_formKey.currentState!.validate()) {
      return; // لا تقم بالاستدعاء إذا كان الفورم غير صالح
    }

    // التأكد من تطابق كلمتي المرور (تم التحقق منه في validator، لكن تحقق إضافي لا يضر)
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'كلمتا المرور غير متطابقتين.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // استدعاء API وتمرير التوكن وكلمة المرور الجديدة
      final result = await ApiService.resetPassword(
        widget.token,
        _newPasswordController.text,
      );

      if (!mounted) return; // تحقق بعد await

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ??
                  'تم تغيير كلمة المرور بنجاح. يمكنك الآن تسجيل الدخول.')),
        );
        // الانتقال إلى شاشة تسجيل الدخول وحذف كل الشاشات السابقة
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginView()),
              (Route<dynamic> route) => false,
        );
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'فشل تحديث كلمة المرور. حاول مرة أخرى.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع: ${e.toString()}';
        print("Error in _resetPassword: $e");
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تعيين كلمة مرور جديدة',
          style:
          TextStyle(color: Color(0xFF2C73D9), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // منع الرجوع التلقائي
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05, vertical: screenHeight * 0.03),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.05),
                Icon(Icons.lock_reset,
                    size: screenWidth * 0.25, color: Color(0xFF2C73D9)),
                SizedBox(height: screenHeight * 0.03),
                Text(
                  'أدخل كلمة المرور الجديدة لحسابك',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C73D9),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.04),

                // حقل كلمة المرور الجديدة
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  // تحقق أثناء الكتابة
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    hintText: 'أدخل كلمة المرور الجديدة',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none, // Style consistency
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        // Maybe slight highlight on focus
                          color: Theme.of(context)
                              .primaryColor
                              .withOpacity(0.5), // Example focus color
                          width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      // شكل حقل الخطأ
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: Colors.red.shade700, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      // شكل حقل الخطأ عند التركيز
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: Colors.red.shade700, width: 2.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور الجديدة';
                    }
                    // مثال: التحقق من الطول (يمكنك تعديل الشرط)
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    // مثال: تحقق من وجود رقم (اختياري)
                    // if (!value.contains(RegExp(r'[0-9]'))) {
                    //   return 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل';
                    // }
                    // مثال: تحقق من وجود حرف كبير (اختياري)
                    // if (!value.contains(RegExp(r'[A-Z]'))) {
                    //   return 'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل';
                    // }
                    return null; // صالح
                  },
                ),
                SizedBox(height: screenHeight * 0.02),

                // حقل تأكيد كلمة المرور
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  // تحقق أثناء الكتابة
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    hintText: 'أعد إدخال كلمة المرور الجديدة',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none, // Style consistency
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        // Maybe slight highlight on focus
                          color: Theme.of(context)
                              .primaryColor
                              .withOpacity(0.5), // Example focus color
                          width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      // شكل حقل الخطأ
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: Colors.red.shade700, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      // شكل حقل الخطأ عند التركيز
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: Colors.red.shade700, width: 2.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء تأكيد كلمة المرور';
                    }
                    if (value != _newPasswordController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null; // صالح
                  },
                ),
                SizedBox(height: screenHeight * 0.03),

                // عرض رسالة الخطأ
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // زر إعادة التعيين
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2C73D9),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ))
                      : const Text(
                    'إعادة تعيين كلمة المرور',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02), // مسافة إضافية
              ],
            ),
          ),
        ),
      ),
    );
  }
}