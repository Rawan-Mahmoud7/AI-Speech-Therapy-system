import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class DoneScreen extends StatelessWidget {
  const DoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [

                const SizedBox(height: 40),

                const Text(
                  "تم إنشاء الحساب بنجاح",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF158F7A),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "مرحباً بك في نطقي",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30),

                Image.asset(
                  "assets/images/done.png",
                  height: 250,
                ),

                const SizedBox(height: 30),

                const Text(
                  "تم إنشاء حسابك بنجاح وأصبح جاهزاً للاستخدام الآن",
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF158F7A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.levels,
                            (route) => false,
                      );
                    },
                    child: const Text(
                      "ابدأ الآن",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}