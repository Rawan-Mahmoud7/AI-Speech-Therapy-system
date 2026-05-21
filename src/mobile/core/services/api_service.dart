import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      "https://shiftless-handgrip-mantis.ngrok-free.dev/api";

  static String? token;

  static int? userId;
  static String? userName;
  static String? role;

  static int? currentSessionId;

  // =========================
  // 🔐 HEADERS
  // =========================
  static Map<String, String> get headers {
    return {
      "Accept": "application/json",
      "ngrok-skip-browser-warning": "true",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // =========================
  // 🔐 LOGIN
  // =========================
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        "Accept": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: {
        "email": email,
        "password": password,
      },
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      token = data['token'];

      userId = data['user']['id'];
      userName = data['user']['name'];
      role = data['user']['role'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token!);
      await prefs.setInt("userId", userId!);
    }

    return data;
  }

  static Future<Map<String, dynamic>> register(
      String name,
      String email,
      String password,
      String confirmPassword,
      int doctorId,
      ) async {

    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        "name": name.trim(),
        "email": email.trim(),
        "password": password,
        "password_confirmation": confirmPassword,
        "role": "patient",
        "doctor_id": doctorId,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    final data = jsonDecode(response.body);

    // 👇 نرجّع كمان statusCode
    data['statusCode'] = response.statusCode;

    return data;
  }

  // =========================
  // 📥 LOAD TOKEN
  // =========================
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    userId = prefs.getInt("userId");
  }

  // =========================
  // 👨‍⚕️ GET DOCTORS
  // =========================
  static Future<List> getDoctors() async {
    final response = await http.get(
      Uri.parse("$baseUrl/doctors"),
      headers: {
        "Accept": "application/json",
        "ngrok-skip-browser-warning": "true",
        "Authorization": token != null ? "Bearer $token" : "",
      },
    );

    print("📡 RAW RESPONSE: ${response.body}");

    final data = jsonDecode(response.body);

    return data['data'] ?? [];
  }

  // =========================
  // 👤 GET PATIENTS
  // =========================
  static Future<List> getPatients() async {
    final response = await http.get(
      Uri.parse("$baseUrl/patients"),
      headers: headers,
    );

    return json.decode(response.body)['data'];
  }

  // =========================
  // 🎯 CREATE SESSION (FIXED 🔥🔥🔥)
  // =========================
  static Future<Map<String, dynamic>> createSession({
    required int level,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/sessions"),
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "user_id": userId,
        "level": level,
      }),
    );

    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {

      final sessionData = data['data'];

      if (sessionData is Map && sessionData['id'] != null) {

        currentSessionId =
            int.tryParse(sessionData['id'].toString());
      }
    }

    return data;
  }

  static Future<int> ensureSession(int level) async {

    if (currentSessionId != null) {
      return currentSessionId!;
    }

    await createSession(
      level: level,
    );

    return currentSessionId ?? 0;
  }

  // =========================
  // 📊 GET SESSION
  // =========================
  static Future<Map<String, dynamic>> getSession(int sessionId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/sessions/$sessionId"),
      headers: headers,
    );

    return jsonDecode(response.body);
  }

  // =========================
  // 📝 UPDATE FEEDBACK
  // =========================
  static Future<Map<String, dynamic>> updateDoctorFeedback({
    required int sessionId,
    required String feedback,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/sessions/$sessionId/feedback"),
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "doctor_feedback": feedback,
      }),
    );

    return jsonDecode(response.body);
  }

  // =========================
  // 🎤 UPLOAD AUDIO
  // =========================
  static Future<Map<String, dynamic>> uploadAudio({
    required String path,
    required int sessionId,
    required int level,
    required String targetPhoneme,
    String? expectedText,
  }) async {

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/audio/upload"),
    );

    request.headers.addAll({
      ...headers,
      "ngrok-skip-browser-warning": "true",
    });

    request.fields['session_id'] = sessionId.toString();

    request.fields['level'] = level.toString();

    // ✅ الحرف المستهدف
    request.fields['target_phoneme'] = targetPhoneme;

    // ✅ الكلمة أو الجملة
    if (expectedText != null) {
      request.fields['expected_text'] = expectedText;
    }

    request.files.add(
      await http.MultipartFile.fromPath('audio', path),
    );

    print(request.fields);

    var streamedResponse = await request.send();

    var response = await http.Response.fromStream(streamedResponse);

    print("📥 UPLOAD RESPONSE: ${response.body}");

    return jsonDecode(response.body);
  }

  // =========================
  // 🤖 ANALYZE
  // =========================
  static Future<Map<String, dynamic>> analyze(int audioId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/ai/analyze/$audioId"),
        headers: {
          ...headers,
          "Content-Type": "application/json",
        },
      );

      print("📡 ANALYZE RESPONSE: ${response.body}");

      final data = jsonDecode(response.body);

      return data;
    } catch (e) {
      print("❌ ANALYZE ERROR: $e");
      rethrow;
    }
  }

  // =========================
  // 📝 UPDATE PROFILE
  // =========================
  static Future<Map<String, dynamic>> updateProfile({
    required int age,
    required String gender,
    required String type,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/patient/profile"),
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "age": age,
        "gender": gender,
        "speech_disorder": type,
      }),
    );

    return jsonDecode(response.body);
  }

  // =========================
  // 📩 OTP
  // =========================
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/send-otp"),
      headers: headers,
      body: {"email": email},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(
      String email, String otp) async {
    final response = await http.post(
      Uri.parse("$baseUrl/verify-otp"),
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "otp": otp,
      }),
    );

    return jsonDecode(response.body);
  }
  static Future<Map<String, dynamic>> resetPassword(
      String email,
      String password,
      String confirmPassword,
      String otp,
      ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
        "password_confirmation": confirmPassword,
        "otp": otp,
      }),
    );

    return jsonDecode(response.body);
  }
}