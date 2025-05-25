import 'dart:convert'; // Keep for debugging print

import 'package:flutter/material.dart';
import 'package:myfinalpro/registration/AccountConformation.dart';
import 'package:myfinalpro/services/Api_services.dart'; // Your ApiService
import 'package:myfinalpro/widget/custom.dart';

class CreateAccount extends StatefulWidget {
  // Receive the initially collected user data
  final Map<String, dynamic> initialUserData;

  const CreateAccount({super.key, required this.initialUserData});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  bool isYesSelected = false;
  bool isNoSelected = false;

  final TextEditingController _therapistNameController =
  TextEditingController();
  final TextEditingController _therapistEmailController =
  TextEditingController();
  final TextEditingController _therapistPhoneController =
  TextEditingController();

  final GlobalKey<FormState> _therapistFormKey =
  GlobalKey<FormState>(); // Key for therapist form validation

  bool _isLoading = false;
  String? _errorMessage;

  // Function to handle the final registration process
  Future<void> _performRegistration() async {
    // Clear previous errors and set loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    int? finalDoctorId; // Use nullable int for doctor ID

    try {
      // --- Step 1: Handle Doctor Addition (if 'Yes' is selected) ---
      if (isYesSelected) {
        // Validate therapist form fields ONLY if 'Yes' is selected
        if (!_therapistFormKey.currentState!.validate()) {
          setState(() {
            _isLoading = false;
            _errorMessage = "يرجى إكمال معلومات الأخصائي المطلوبة.";
          });
          return; // Stop if validation fails
        }

        print("Attempting to add doctor..."); // Debug log
        final addDoctorResponse = await ApiService.addDoctor(
          _therapistNameController.text.trim(),
          email: _therapistEmailController.text.trim(),
          phone: _therapistPhoneController.text.trim(),
          // Degree and About use defaults from ApiService
        );

        if (addDoctorResponse['success']) {
          finalDoctorId = addDoctorResponse['doctorId']; // Get the ID
          print(
              "Doctor added successfully. Doctor ID: $finalDoctorId"); // Debug log
          if (finalDoctorId == null) {
            // This case should ideally be handled by ApiService returning success=false
            // if ID parsing fails, but double-check here.
            throw Exception(
                "Doctor added but API did not return a valid Doctor ID.");
          }
        } else {
          // Failed to add doctor
          setState(() {
            _errorMessage =
            'فشل إضافة الأخصائي: ${addDoctorResponse['message']}';
            _isLoading = false;
          });
          print(
              "Failed to add doctor: ${addDoctorResponse['message']}"); // Debug log
          return; // Stop the registration process
        }
      } else if (isNoSelected) {
        finalDoctorId = 0; // Use 0 if no doctor, as per API example
        print(
            "No doctor selected. Using Doctor ID: $finalDoctorId"); // Debug log
      } else {
        // Should not be reachable if button logic is correct, but handle defensively
        setState(() {
          _errorMessage = 'يرجى تحديد ما إذا كان الطفل يتابع مع أخصائي.';
          _isLoading = false;
        });
        return;
      }

      // --- Step 2: Prepare Final Registration Data ---
      // Combine initial data with the determined doctor ID
      final Map<String, dynamic> finalRegisterData = {
        ...widget.initialUserData
      };
      finalRegisterData['doctor_ID'] = finalDoctorId; // Add the doctor ID

      // Remove any fields not needed for registration API (if any were added temporarily)
      // finalRegisterData.remove('some_temporary_field');

      // Explicitly set fields potentially missing from initial data if API requires them (e.g., image)
      // Based on your example, image_ is not sent during registration.
      // finalRegisterData['image_'] = null; // Example if API expected it

      print(
          "Final Data Sent to Register API: ${json.encode(finalRegisterData)}"); // Debug log

      // --- Step 3: Call User Registration API ---
      final registerResponse = await ApiService.registerUser(finalRegisterData);

      if (registerResponse['success']) {
        // Registration successful
        print("User registration successful!"); // Debug log
        final String userEmail = widget.initialUserData['email'] ??
            ''; // Get email for confirmation screen

        // Navigate to confirmation screen (ensure widget is still mounted)
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            // Use pushAndRemoveUntil to clear registration stack
            context,
            MaterialPageRoute(
              builder: (context) => AccountConformation(
                email: userEmail, // Pass email if needed by confirmation screen
              ),
            ),
                (Route<dynamic> route) => false, // Remove all previous routes
          );
        }
      } else {
        // Registration failed
        setState(() {
          _errorMessage = 'فشل التسجيل: ${registerResponse['message']}';
        });
        print(
            "User registration failed: ${registerResponse['message']}"); // Debug log
      }
    } catch (e) {
      // Catch any other errors (network, unexpected exceptions)
      print('Registration process error: $e');
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع: $e';
      });
    } finally {
      // Ensure loading indicator is turned off
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _therapistNameController.dispose();
    _therapistEmailController.dispose();
    _therapistPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.06),
              // Header copied from original
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
                        if (!_isLoading) {
                          Navigator.pop(context);
                        }
                      }, // Go back if not loading
                      icon: Icon(
                        Icons.keyboard_arrow_right_outlined,
                        size: 40,
                        color: Color(0xFF2C73D9),
                      ))
                ],
              ),
              Text(
                "إنشاء حساب",
                style: TextStyle(
                  color: Color(0xFF2C73D9),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: screenHeight * 0.01,
              ),
              // Progress indicator (Step 2) - Copied from original
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: screenWidth * 0.06, height: screenWidth * 0.06,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2C73D9),
                    ), // Completed
                    child: Icon(Icons.check,
                        color: Colors.white, size: screenWidth * 0.035),
                  ),
                  Container(
                    width: screenWidth * 0.1,
                    height: 2,
                    color: Color(0xFF2C73D9),
                  ),
                  // Connector active
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: screenWidth * 0.06, height: screenWidth * 0.06,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(0xFF2C73D9), width: 2),
                        ), // Active
                      ),
                      Container(
                        width: screenWidth * 0.023, height: screenWidth * 0.023,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2C73D9),
                        ), // Active dot
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: screenHeight * 0.01,
              ),
              Text(
                "هل يتابع طفلك مع اخصائى نفسي؟",
                style: TextStyle(
                  color: Color(0xFF2C73D9),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: screenHeight * 0.03,
              ),
              // Yes/No selection - Copied from original
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    // No Button
                    onTap: () {
                      setState(() {
                        isNoSelected = true;
                        isYesSelected = false;
                        _errorMessage = null;
                      });
                    },
                    child: Row(
                      children: [
                        Text(
                          "لا",
                          style: TextStyle(
                            color: isNoSelected
                                ? Colors.blue.shade700
                                : Color(0xFF4A4A4A),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Container(
                          width: screenWidth * 0.06,
                          height: screenWidth * 0.06,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                            isNoSelected ? Colors.blue : Colors.transparent,
                            border: Border.all(
                                color: isNoSelected ? Colors.blue : Colors.grey,
                                width: 2),
                          ),
                          child: isNoSelected
                              ? Icon(Icons.check, size: 15, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.2),
                  GestureDetector(
                    // Yes Button
                    onTap: () {
                      setState(() {
                        isYesSelected = true;
                        isNoSelected = false;
                        _errorMessage = null;
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          width: screenWidth * 0.06,
                          height: screenWidth * 0.06,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isYesSelected
                                ? Color(0xFF2C73D9)
                                : Colors.transparent,
                            border: Border.all(
                                color:
                                isYesSelected ? Color(0xFF2C73D9) : Colors.grey,
                                width: 2),
                          ),
                          child: isYesSelected
                              ? Icon(Icons.check, size: 15, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          "نعم",
                          style: TextStyle(
                            color: isYesSelected
                                ? Color(0xFF2C73D9)
                                : Color(0xFF4A4A4A),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: screenHeight * 0.04,
              ),

              // Conditionally show therapist fields wrapped in a Form
              if (isYesSelected)
                Form(
                  key: _therapistFormKey, // Assign key here
                  child: Column(
                    children: [
                      Text(
                        "معلومات الأخصائي النفسي لطفلك",
                        style: TextStyle(
                          color: Color(0xFF2C73D9),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      CustomTextField(
                        hintText: "ادخل اسم الاخصائي بالكامل",
                        obscureText: false,
                        controller: _therapistNameController,
                        validator: (value) {
                          // Required only if 'Yes' is selected
                          if (isYesSelected &&
                              (value == null || value.trim().isEmpty)) {
                            return 'يرجى إدخال اسم الأخصائي';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      CustomTextField(
                        hintText: "ادخل البريد الالكتروني للاخصائي (اختياري)",
                        obscureText: false,
                        controller: _therapistEmailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          // Optional field, but validate format if entered
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              !_isValidEmail(value.trim())) {
                            return 'يرجى إدخال بريد إلكتروني صحيح أو اتركه فارغًا';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      CustomTextField(
                          hintText: 'رقم هاتف الأخصائي (اختياري)',
                          obscureText: false,
                          controller: _therapistPhoneController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            // Optional field, basic phone validation if entered
                            if (value != null &&
                                value.trim().isNotEmpty &&
                                !RegExp(r'^\+?\d{10,}$')
                                    .hasMatch(value.trim())) {
                              return 'يرجى إدخال رقم هاتف صحيح أو اتركه فارغًا';
                            }
                            return null;
                          }),
                      SizedBox(height: screenHeight * 0.01),
                      // Add some space after therapist fields
                    ],
                  ),
                ),

              // Show error message if exists
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(height: screenHeight * 0.03),
              // Submit Button
              ElevatedButton(
                // Enable button only if 'Yes' or 'No' is selected AND not currently loading
                onPressed: (isYesSelected || isNoSelected) && !_isLoading
                    ? _performRegistration // Call the combined registration function
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isYesSelected || isNoSelected)
                      ? Color(0xFF2C73D9)
                      : Colors.grey, // Grey out if no selection
                  minimumSize: Size(screenWidth * 0.8, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  // Disable clicks while loading visually
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "إنشاء حساب",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // Helper for email validation (can be reused)
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}