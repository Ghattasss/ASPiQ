import 'package:flutter/material.dart';
import 'package:myfinalpro/login/login_view.dart';
import 'package:myfinalpro/registration/create Account.dart'; // Correct path

import '../widget/custom.dart';

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  bool _obscureText = true;

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>(); // Add form key for validation

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController =
  TextEditingController(); // Changed to email only
  final TextEditingController _passwordController = TextEditingController();

  // Function to validate email format
  bool _isValidEmail(String email) {
    // Basic email regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // --- Date Picker Function ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(), // Sensible default
        firstDate: DateTime(1950), // Reasonable earliest date
        lastDate: DateTime.now()); // Cannot be born in the future
    if (picked != null) {
      // Format the date as YYYY-MM-DD which is common for APIs
      String formattedDate = "${picked.year.toString().padLeft(4, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _birthDateController.text = formattedDate; // Update the controller
      });
    }
  }

  // ---------------------------

  // Function to navigate and pass data (NO API calls here)
  void _navigateToCreateAccount() {
    // Use Form key to validate
    if (_formKey.currentState!.validate()) {
      // Prepare user data map with keys matching the final API structure
      Map<String, dynamic> collectedUserData = {
        'name_': _nameController.text.trim(),
        'surname': _usernameController.text.trim(),
        // Assuming username maps to surname
        'email': _emailController.text.trim(),
      'birthDate': _selectedDate?.toUtc().toIso8601String(),
        // Pass as string (YYYY-MM-DD format preferred)
        'password': _passwordController.text,
        // doctor_ID will be added in the next step
      };

      print(
          "Data collected in RegistrationView: $collectedUserData"); // Debug log

      // Navigate to CreateAccount screen, passing the collected data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAccount(
              initialUserData: collectedUserData), // Pass the data
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تصحيح الأخطاء في النموذج')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          // Wrap Column with Form widget
          child: Form(
            key: _formKey, // Assign the key
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.06),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: screenWidth * 0.1,
                    ),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          "assets/images/logo.png",
                          width: screenWidth * 0.4,
                          height: screenHeight * 0.2,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_right_outlined,
                          size: 40,
                          color: Color(0xFF2C73D9),
                        ))
                  ],
                ),
                const Text(
                  "إنشاء حساب",
                  style: TextStyle(
                    color: Color(0xFF2C73D9),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                // Progress indicator (Step 1) - Copied from original
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: screenWidth * 0.06,
                      height: screenWidth * 0.06,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 2),
                      ),
                    ),
                    Container(
                      width: screenWidth * 0.1,
                      height: 2,
                      color: Colors.grey,
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: screenWidth * 0.06,
                          height: screenWidth * 0.06,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Color(0xFF2C73D9), width: 2),
                          ),
                        ),
                        Container(
                          width: screenWidth * 0.023,
                          height: screenWidth * 0.023,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2C73D9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),

                // Form fields with validation
                CustomTextField(
                  hintText: "ادخل اسم الطفل بالكامل",
                  obscureText: false,
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم الطفل';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),

                // --- Birth Date Field with Date Picker ---

                GestureDetector(
                  onTap: () => _pickDate(context),
                  child: AbsorbPointer(
                    child: CustomTextField(
                      hintText: "ادخل تاريخ ميلاد الطفل ",
                      obscureText: false,
                      controller: _birthDateController,
                      keyboardType: TextInputType.datetime,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال تاريخ الميلاد';
                        }
                        return null;
                      },
                      suffixIcon: Icons.calendar_today,
                    ),
                  ),
                ),

                // ---------------------------------------

                SizedBox(height: screenHeight * 0.02),
                CustomTextField(
                  hintText: "ادخل اسم المستخدم (للأب/الأم)",
                  // Maps to 'surname'
                  obscureText: false,
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم المستخدم';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomTextField(
                  hintText: "ادخل البريد الالكتروني",
                  // Changed hint
                  obscureText: false,
                  controller: _emailController,
                  // Changed controller
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال البريد الإلكتروني';
                    }
                    if (!_isValidEmail(value.trim())) {
                      return 'يرجى إدخال بريد إلكتروني صحيح';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomTextField(
                  hintText: "أدخل كلمة المرور",
                  obscureText: _obscureText,
                  controller: _passwordController,
                  onSuffixIconPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.05),

                // Submit button - Navigates to next step
                ElevatedButton(
                  onPressed: _navigateToCreateAccount,
                  // Calls validation and navigation
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C73D9),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "التالي",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login link - Copied from original
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginView()),
                        );
                      },
                      child: const Text(
                        " قم بتسجيل الدخول",
                        style: TextStyle(
                          color: Color(0xFF2C73D9),
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(
                      " هل لديك حساب بالفعل ؟ ",
                      style: TextStyle(
                        color: Color(0xFF4A4A4A),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = picked.toIso8601String().split('T')[0]; // YYYY-MM-DD
      });

      // ✅ طباعة التاريخ بالصيغة المطلوبة
      final birthDateIso = _selectedDate?.toUtc().toIso8601String();
      print('birthDate: $birthDateIso'); // Example: 2025-04-24T19:40:26.978Z
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _usernameController.dispose();
    _emailController.dispose(); // Changed
    _passwordController.dispose();
    super.dispose();
  }
}