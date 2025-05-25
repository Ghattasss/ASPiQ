import 'package:flutter/material.dart';

class CustomProfileTextField extends StatelessWidget {
  // ... (المعاملات كما هي) ...
  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final bool readOnly;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final FormFieldValidator<String>? validator;
  final TextDirection? textDirection;
  final TextAlign textAlign;

  const CustomProfileTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.validator,
    this.textDirection,
    this.textAlign = TextAlign.right, // <--- المحاذاة لليمين
  });

  @override
  Widget build(BuildContext context) {
    // --- تعريف الألوان المطلوبة ---
    const Color borderColor =
        Color(0xFF2C73D9); // <--- اللون الأزرق للحدود دائمًا
    const Color inputTextColor = Color(0xFF719EDF); // لون النص الداخلي
    final Color labelColor =
        Colors.grey.shade800; // لون الـ label (يمكن جعله أزرق أيضًا إذا أردت)
    final Color readOnlyFillColor = Colors.grey.shade100;
    const Color fillColor = Colors.white;
    // --------------------------

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4.0, bottom: 6.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: labelColor,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            readOnly: readOnly,
            keyboardType: keyboardType,
            validator: validator,
            textDirection: textDirection ??
                (Localizations.localeOf(context).languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr),
            textAlign: textAlign, // <-- تطبيق المحاذاة لليمين
            style: const TextStyle(
              fontSize: 16,
              color: inputTextColor,
              fontWeight: FontWeight.w500,
            ), // <-- لون النص الداخلي
            cursorColor: borderColor, // <-- المؤشر بنفس لون الحدود
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: readOnly ? readOnlyFillColor : fillColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 16),

              // --- تصميم الحدود (كلها بنفس اللون الأزرق الآن) ---
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(
                    color: borderColor, width: 1.5), // <--- اللون الأزرق
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(
                    color: borderColor, width: 1.5), // <--- اللون الأزرق
              ),
              focusedBorder: OutlineInputBorder(
                // يمكن زيادة السمك عند التركيز
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(
                    color: borderColor, width: 2.0), // <--- اللون الأزرق
              ),
              errorBorder: OutlineInputBorder(
                // حدود الخطأ تبقى حمراء
                borderRadius: BorderRadius.circular(12.0),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                // حدود الخطأ عند التركيز
                borderRadius: BorderRadius.circular(12.0),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 2.0),
              ),
              disabledBorder: OutlineInputBorder(
                // حدود الحقل المعطل
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                    color: borderColor.withOpacity(0.5),
                    width: 1.0), // <--- أزرق باهت
              ),
              // -------------------------------------------------------
                suffixIcon: suffixIcon != null
                  ? Padding( // إضافة Padding خارجي لتحسين المظهر
                      padding: const EdgeInsetsDirectional.only(end: 12.0),
                      child: suffixIcon, // <-- عرض الأيقونة مباشرة
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
