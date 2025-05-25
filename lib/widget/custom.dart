// import 'package:flutter/material.dart';
//
// class CustomTextField extends StatelessWidget {
//   final String hintText;
//   final bool obscureText;
//   final Function(String) onChanged;
//   final Function()? onSuffixIconPressed;
//
//   const CustomTextField({
//     required this.hintText,
//     required this.obscureText,
//     required this.onChanged,
//     this.onSuffixIconPressed,
//      final TextInputType keyboardType;
//     super.key, //required Padding prefixIcon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       obscureText: obscureText,
//       onChanged: onChanged,
//       decoration: InputDecoration(
//         hintText: hintText,
//         hintTextDirection: TextDirection.rtl, // الكتابة من اليمين لليسار
//         fillColor: Color(0xFFE6E9EA), // اللون الأبيض داخل الحقل
//         contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 15), // المسافة بين النص والحواف
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12), // زوايا دائرية
//           borderSide: BorderSide(
//             color: Colors.grey, // لون الحواف
//           ),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: Colors.grey, // لون الحواف عند التمكين
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: Color(0xFFE6E9EA),
//           ),
//         ),
//         prefixIcon: onSuffixIconPressed != null
//             ? IconButton(
//           icon: Icon(
//             obscureText ? Icons.visibility_off : Icons.visibility,
//             color: Colors.grey,
//           ),
//           onPressed: onSuffixIconPressed,
//         )import 'package:flutter/material.dart';
//
// class CustomTextField extends StatelessWidget {
//   final String hintText;
//   final bool obscureText;
//   final Function(String) onChanged;
//   final Function()? onSuffixIconPressed;
//   final TextInputType keyboardType;
//   final TextEditingController? controller; // Add controller parameter
//
//   const CustomTextField({
//     required this.hintText,
//     required this.obscureText,
//     required this.onChanged,
//     this.onSuffixIconPressed,
//     this.keyboardType = TextInputType.text,
//     this.controller, // Make it optional with default value null
//     super.key,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       controller: controller, // Use the controller
//       keyboardType: keyboardType,
//       obscureText: obscureText,
//       onChanged: onChanged,
//       decoration: InputDecoration(
//         hintText: hintText,
//         hintTextDirection: TextDirection.rtl,
//         fillColor: const Color(0xFFE6E9EA),
//         contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(
//             color: Colors.grey,
//           ),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(
//             color: Colors.grey,
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(
//             color: Color(0xFFE6E9EA),
//           ),
//         ),
//         prefixIcon: onSuffixIconPressed != null
//             ? IconButton(
//                 icon: Icon(
//                   obscureText ? Icons.visibility_off : Icons.visibility,
//                   color: Colors.grey,
//                 ),
//                 onPressed: onSuffixIconPressed,
//               )
//             : null,
//       ),
//     );
//   }
// }
//             : null,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final Function(String)?
      onChanged; // Make optional if validator is used primarily
  final Function()? onSuffixIconPressed;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final FormFieldValidator<String>?
      validator; // <<<--- ADDED: Validator function parameter
  final bool readOnly; // <<<--- ADDED: For read-only fields like Date Picker
  final VoidCallback?
      onTap; // <<<--- ADDED: For tap actions like opening Date Picker
  final IconData? suffixIcon; // <<<--- ADDED: For icons like calendar

  const CustomTextField({
    required this.hintText,
    this.obscureText = false, // Default to false
    this.onChanged, // Keep optional
    this.onSuffixIconPressed,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator, // <<<--- ADDED: To constructor
    this.readOnly = false, // <<<--- ADDED: Default to false
    this.onTap, // <<<--- ADDED: To constructor
    this.suffixIcon, // <<<--- ADDED: Optional suffix icon
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the suffix icon logic
    Widget? suffixWidget;
    if (onSuffixIconPressed != null) {
      // Password visibility toggle takes priority
      suffixWidget = IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: onSuffixIconPressed,
      );
    } else if (suffixIcon != null) {
      // Otherwise, use the provided suffix icon
      suffixWidget = Icon(suffixIcon, color: Colors.grey);
    }
    // If onTap is provided, wrap suffixWidget in InkWell if it exists,
    // otherwise, the tap action is on the field itself via onTap property below.
    // However, tapping the icon itself is often more intuitive for date pickers.
    if (onTap != null && suffixWidget != null) {
      suffixWidget = InkWell(onTap: onTap, child: suffixWidget);
    }

    return TextFormField(
      // Use TextFormField to enable validation
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
      // <<<--- PASS VALIDATOR: Pass the validator function here
      readOnly: readOnly,
      // <<<--- PASS READONLY
      onTap: onTap,
      // <<<--- PASS ONTAP
      decoration: InputDecoration(
        hintText: hintText,
        hintTextDirection: TextDirection.rtl,
        fillColor: const Color(0xFFE6E9EA),
        filled: true,
        // Ensure the fillColor is applied
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide
              .none, // Remove border side if using fillColor primarily
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
          // Style for validation error
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          // Style for validation error when focused
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2.0),
        ),
        // Use prefixIcon argument for password toggle consistency if desired
        // prefixIcon: onSuffixIconPressed != null ? ... : null, // Example if needed on left
        suffixIcon: suffixWidget, // Use the determined suffix widget
      ),
    );
  }
}