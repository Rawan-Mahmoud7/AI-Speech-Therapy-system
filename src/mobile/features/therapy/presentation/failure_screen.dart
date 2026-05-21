import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class FailureScreen extends StatelessWidget {
  const FailureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    // 🔥 FIX: يدعم String أو Map أو null
    String letter = "s";

    if (args is String) {
      letter = args;
    } else if (args is Map && args["letter"] != null) {
      letter = args["letter"];
    }

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

                Image.asset(
                  'assets/images/failure.png',
                  height: 180,
                ),

                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        child: const Text(
                          "نأسف لعدم تمكنك من تخطي\nهذه المرحلة",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "أنت لم تنطق بطريقة صحيحة تجعلك تنتقل إلى المستوى التالي، قم بإعادة التمرين مرة أخرى",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF158F7A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    onPressed: () {
                      final args = ModalRoute.of(context)?.settings.arguments;

                      String letter = "s";

                      if (args is String) {
                        letter = args;
                      } else if (args is Map && args["letter"] != null) {
                        letter = args["letter"];
                      }

                      Navigator.pushReplacementNamed(
                        context,
                        letter == "s"
                            ? AppRoutes.exercise
                            : AppRoutes.exerciseR,
                        arguments: letter,
                      );
                    },

                    child: const Text(
                      "الإنتقال للتعليمات",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}