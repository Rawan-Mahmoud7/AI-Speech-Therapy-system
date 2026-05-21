import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  final List<Map<String, String>> pages = [
    {
      "image": "assets/images/onboarding1.png",
      "title": "مرحباً بك في برنامج نُطقي",
      "desc": "نظام متكامل لمتابعة الأشخاص المصابين بصعوبة في الكلام",
    },
    {
      "image": "assets/images/onboarding2.png",
      "title": "نحن نساعدك على التحدث بطلاقة",
      "desc": "من خلال تدريبات يومية ونصائح مهمة",
    },
    {
      "image": "assets/images/onboarding3.png",
      "title": "ابدأ رحلتك الآن",
      "desc": "انضم إلينا للحصول على أفضل نتيجة",
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFBFE1DE),
        body: Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
                child: Column(
                  children: [

                  // 🔵 Skip فوق شمال
                  Align(
                  alignment: Alignment.topLeft,
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      "تخطي",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    reverse: true,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              pages[index]["image"]!,
                              height: 250,
                            ),
                            const SizedBox(height: 30),
                            Text(
                              pages[index]["title"]!,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              pages[index]["desc"]!,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 🔵 زرار تحت شمال مع خط
                Padding(
                    padding: const EdgeInsets.only(left: 25, bottom: 40),
                    child: Align(
                        alignment: Alignment.bottomLeft,
                        child: GestureDetector(
                            onTap: () {
                              if (currentIndex == pages.length - 1) {
                                _finishOnboarding();
                              } else {
                                _controller.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentIndex == pages.length - 1
                                    ? "ابدأ"
                                    : "التالي",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 40,
                                height: 2,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                    ),
                ),
                  ],
                ),
            ),
        ),
    );
  }
}