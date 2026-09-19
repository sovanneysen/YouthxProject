import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';

// ==================================================================
// 4. VERIFY EMAIL SCREEN (4-digit code entry)
// ==================================================================
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  bool get isComplete =>
      controllers.every((controller) => controller.text.trim().isNotEmpty);

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void onDigitChanged(int index, String value) {
    setState(() {}); // refresh so the Verify button enables/disables correctly

    if (value.isNotEmpty && index < 3) {
      focusNodes[index + 1].requestFocus(); // jump to next box
    }
    if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus(); // jump back on delete
    }
  }

  void verify() {
    // Placeholder: the Draft Backend has no email-verification endpoint.
    // AuthScreen routes straight to Home after login/auto-login, so this
    // screen is currently unreachable and kept only for the original UI.
    Get.offNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.close, color: Colors.black),
        title: const Text('YouthX', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF4A6CF7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.mail_outline,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verify your email',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "We sent a 4-digit code to your Gmail account. Please enter it below to continue your journey.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 32),

            // 4 code boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: TextField(
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '', // hides the 0/1 character counter
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A6CF7),
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => onDigitChanged(index, value),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  disabledBackgroundColor: const Color(
                    0xFF4A6CF7,
                  ).withOpacity(0.35),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isComplete
                    ? verify
                    : null, // disabled until all 4 filled
                child: const Text(
                  'Verify →',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextButton(
              onPressed: () {},
              child: const Text("Didn't receive the code? Resend code"),
            ),
          ],
        ),
      ),
    );
  }
}
