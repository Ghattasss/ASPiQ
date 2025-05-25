import 'package:flutter/material.dart';

class CustomProfileTextField extends StatelessWidget {
  final String? label; // جعل الـ label اختياري
  final String hint;
  final bool obscureText;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixIconPressed;

  const CustomProfileTextField({
    Key? key,
    this.label, // اختياري
    required this.hint,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixIconPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (label != null)
            Text(
              label!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
              ),
            ),
          if (label != null) const SizedBox(height: 4),
          TextFormField(
            textAlign: TextAlign.right,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.blueAccent),
              hintTextDirection: TextDirection.rtl,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2C73D9)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2C73D9)),
              ),
              // استخدام prefixIcon ليظهر على اليسار (كما طلبت سابقاً)
              prefixIcon: suffixIcon != null
                  ? IconButton(
                      icon: suffixIcon!,
                      onPressed: onSuffixIconPressed,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
