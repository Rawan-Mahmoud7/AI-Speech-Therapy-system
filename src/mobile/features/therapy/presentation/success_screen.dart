import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

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
                  "لقد نجحت في إجتياز المرحلة بنجاح",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6F9F98),
                  ),
                ),

                const SizedBox(height: 40),

                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/success.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

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

                    // 👇 يرجع لصفحة Levels ويفتح المستوى التالي
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: const Text(
                      "الإنتقال للمرحلة التالية",
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