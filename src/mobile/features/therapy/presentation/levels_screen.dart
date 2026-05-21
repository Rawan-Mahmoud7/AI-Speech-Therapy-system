import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {

  int currentLevel = 0;
  List<bool> completed = [false, false, false, false];

  late String letter;
  int? userId;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    letter = ModalRoute.of(context)?.settings.arguments as String? ?? "s";
  }

  Future<void> init() async {
    try {

      userId = ApiService.userId;

      if (userId == null || userId == 0) {
        throw Exception("Invalid userId");
      }

      await loadProgress();

    } catch (e) {
      print("INIT ERROR: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final uid = userId!;

    final keyCurrent = "currentLevel_${uid}_$letter";

    currentLevel = prefs.getInt(keyCurrent) ?? 0;

    completed = [
      prefs.getBool("level0_${uid}_$letter") ?? false,
      prefs.getBool("level1_${uid}_$letter") ?? false,
      prefs.getBool("level2_${uid}_$letter") ?? false,
      prefs.getBool("level3_${uid}_$letter") ?? false,
    ];

    setState(() {});
  }

  Future<void> saveProgress(int level) async {
    final prefs = await SharedPreferences.getInstance();

    final uid = userId!;

    await prefs.setInt(
      "currentLevel_${uid}_$letter",
      currentLevel,
    );

    await prefs.setBool(
      "level${level}_${uid}_$letter",
      true,
    );
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        backgroundColor: const Color(0xFFBFE1DE),

        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                        const SizedBox(height: 20),

                    const Text(
                      "المستويات",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF158F7A),
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 45),

                    _buildLevel(3),
                    const SizedBox(height: 50),

                    _buildLevel(2),
                    const SizedBox(height: 50),

                    _buildLevel(1),
                    const SizedBox(height: 50),

                    _buildLevel(0),

                    const SizedBox(height: 55),

                    SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF158F7A),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.instructions,
                              );
                            },
                            child: const Text(
                              "كيفية الاستخدام",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                        ),
                    ),

                          const SizedBox(height: 100),
                        ],
                    ),
                ),
            ),
        ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFAED3CF),
        currentIndex: 0,
        selectedItemColor: const Color(0xFF158F7A),
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(
              context,
              AppRoutes.information,
              arguments: true,
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "",
          ),
        ],
      ),
    );
  }

  Widget _buildLevel(int level) {

    bool isUnlocked = level == 0 || completed[level - 1];
    bool isCurrent = level == currentLevel;
    bool isCompleted = completed[level];

    return GestureDetector(
      onTap: () async {

        if (!isUnlocked) return;

        await ApiService.createSession(
          level: level + 1,
        );

        final sessionId = ApiService.currentSessionId;

        if (sessionId == null || sessionId is! int) {
          print("❌ Invalid sessionId: $sessionId");
          return;
        }

        String route = "";

        if (letter == "s") {
          if (level == 0) route = AppRoutes.levelOneS;
          if (level == 1) route = AppRoutes.levelTwoS;
          if (level == 2) route = AppRoutes.levelThreeS;
          if (level == 3) route = AppRoutes.levelFourS;
        } else {
          if (level == 0) route = AppRoutes.levelOneR;
          if (level == 1) route = AppRoutes.levelTwoR;
          if (level == 2) route = AppRoutes.levelThreeR;
          if (level == 3) route = AppRoutes.levelFourR;
        }

        final result = await Navigator.pushNamed(
          context,
          route,
          arguments: {
            "level": level,
            "sessionId": sessionId,
            "letter": letter,
            "userId": userId,
          },
        );

        if (result == true) {

          final prefs = await SharedPreferences.getInstance();

          setState(() {
            completed[level] = true;

            if (level + 1 > currentLevel) {
              currentLevel = level + 1;
            }
          });

          await prefs.setInt(
            "currentLevel_${userId}_$letter",
            currentLevel,
          );

          await prefs.setBool(
            "level${level}_${userId}_$letter",
            true,
          );
        }
      },

      child: Column(
        children: [

        Stack(
        alignment: Alignment.center,
        children: [

          Container(
            width: 190,
            height: 60,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFF158F7A)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(40),
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 28)
                : Text(
              (level + 1).toString().padLeft(2, '0'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (!isUnlocked)
            const Positioned(
              right: 20,
              child: Icon(Icons.lock, color: Colors.black54),
            ),
        ],
      ),
          const SizedBox(height: 10),

          Container(
            width: 140,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
            ),
          ),

          const SizedBox(height: 12),

          if (isCurrent && !isCompleted)
            const Text(
              "ابدأ الآن",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}