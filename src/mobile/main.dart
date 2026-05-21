import 'package:flutter/material.dart';

// Routes
import 'core/routes/app_routes.dart';

// Screens
import 'core/services/api_service.dart';
import 'features/auth/presentation/done_screen.dart';
import 'features/auth/presentation/forget_password_screen.dart';
import 'features/auth/presentation/information_screen.dart';
import 'features/auth/presentation/reset_password_screen.dart';
import 'features/auth/presentation/verify_code_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/doctor/presentation/contact_doctor_screen.dart';

// Therapy Screens
import 'features/therapy/presentation/instructions_screen.dart';
import 'features/therapy/presentation/levels_screen.dart';
import 'features/therapy/presentation/exercise_screen.dart';
import 'features/therapy/presentation/exercise_screen_r.dart';
import 'features/therapy/presentation/failure_screen.dart';
import 'features/therapy/presentation/success_screen.dart';

// 🔥 مستويات حرف السين
import 'features/therapy/presentation/level_one_screen_s.dart';
import 'features/therapy/presentation/level_two_screen_s.dart';
import 'features/therapy/presentation/level_three_screen_s.dart';
import 'features/therapy/presentation/level_four_screen_s.dart';

// 🔴 مستويات حرف الراء
import 'features/therapy/presentation/level_one_screen_r.dart';
import 'features/therapy/presentation/level_two_screen_r.dart';
import 'features/therapy/presentation/level_three_screen_r.dart';
import 'features/therapy/presentation/level_four_screen_r.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadToken();

  runApp(NutqiApp());
}


class NutqiApp extends StatelessWidget {
  const NutqiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutqi',
      debugShowCheckedModeBanner: false,

      initialRoute: AppRoutes.splash,

      routes: {

        // 🔹 أساسية
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.login: (_) =>  LoginScreen(),
        AppRoutes.signup: (_) =>  SignUpScreen(),

        // 🔹 Auth
        AppRoutes.forgotPassword: (_) =>  ForgotPasswordScreen(),
        AppRoutes.verifyCode: (_) => const VerifyCodeScreen(),
        AppRoutes.resetPassword: (_) => const ResetPasswordScreen(),

        // 🔹 بيانات
        AppRoutes.information: (_) => const InformationScreen(),
        AppRoutes.done: (_) => const DoneScreen(),
        AppRoutes.instructions: (context) => const InstructionsScreen(),

        // 🔹 Levels
        AppRoutes.levels: (_) => const LevelsScreen(),

        // 🔹 تمارين
        AppRoutes.exercise: (_) => const ExerciseScreen(),
        AppRoutes.exerciseR: (_) => const ExerciseScreenR(),
        AppRoutes.failure: (_) => const FailureScreen(),
        AppRoutes.success: (_) => const SuccessScreen(),

        // 🔹 دكتور
        AppRoutes.doctor: (_) => const ContactDoctorScreen(),

        // 🔥 مستويات حرف السين
        AppRoutes.levelOneS: (_) => const LevelOneScreenS(),
        AppRoutes.levelTwoS: (_) => const LevelTwoScreenS(),
        AppRoutes.levelThreeS: (_) => const LevelThreeScreenS(),
        AppRoutes.levelFourS: (_) => const LevelFourScreenS(),

        // 🔴 مستويات حرف الراء
        AppRoutes.levelOneR: (_) => const LevelOneScreenR(),
        AppRoutes.levelTwoR: (_) => const LevelTwoScreenR(),
        AppRoutes.levelThreeR: (_) => const LevelThreeScreenR(),
        AppRoutes.levelFourR: (_) => const LevelFourScreenR(),
      },
    );
  }
}