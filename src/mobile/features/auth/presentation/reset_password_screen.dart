import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../../../services/api_service.dart';
import 'auth_header.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String email = "";
  String otp = ""; // ✅ إضافة otp

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      email = args["email"] ?? "";
      otp = args["otp"] ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
                children: [

                const AuthHeader(title: "إعادة تعيين كلمة المرور"),

            const SizedBox(height: 40),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "الرجاء إدخال كلمة مرور جديدة وقوية إلى حسابك",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "كلمة المرور الجديدة",
                  filled: true,
                  fillColor: Color(0xFFE6F2F0),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "تأكيد كلمة المرور",
                  filled: true,
                  fillColor: Color(0xFFE6F2F0),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF158F7A),
                        ),
                        onPressed: () async {

                          if (passwordController.text != confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("كلمات المرور غير متطابقة ❌")),
                            );
                            return;
                          }

                          var result = await ApiService.resetPassword(
                            email,
                            passwordController.text,
                            confirmPasswordController.text,
                            otp, // ✅ هنا بقى صح
                          );

                          if (result['message'] != null) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.login,
                                  (route) => false,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("فشل إعادة التعيين ❌")),
                            );
                          }
                        },
                      child: const Text(
                        "إعادة تعيين كلمة المرور",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ),
            ),
                ],
            ),
        ),
    );
  }
}