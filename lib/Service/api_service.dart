import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../config.dart';

class ApiService {
  static String? currentUserId; // Set this after login/signup, clear on logout

  // AUTH
  static Future<Map<String, dynamic>?> login(String email,
      String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/login'), // fixed endpoint
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Set currentUserId after successful login
      currentUserId = data['userId']?.toString();
      return data;
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> signupWithId(String email,
      String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/signup'), // fixed endpoint
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      // Try to decode error message from backend
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'message': 'Registration failed'};
      }
    } else {
      return {'message': 'Registration failed'};
    }
  }

  // Example: GET user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<bool> updateProfile(String userId,
      Map<String, dynamic> profileData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profileData),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> addSkill(
      Map<String, dynamic> skillData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/skills'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(skillData),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateSkill(String skillId,
      Map<String, dynamic> skillData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/skills/$skillId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(skillData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getSkillsByUser(
      String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skills?userId=$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) {
        final map = Map<String, dynamic>.from(item);
        map['skillId'] = map['_id'];
        return map;
      }).toList();
    } else {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllSkills() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skills'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) {
        final map = Map<String, dynamic>.from(item);
        map['skillId'] = map['_id'];
        return map;
      }).toList();
    } else {
      return [];
    }
  }

  static Future<bool> deleteSkill(String skillId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/skills/$skillId'),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

  static Future<bool> saveLastClickedSkill(String userId, String skillName,
      int skillIndex) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/$userId/lastClickedSkill'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'lastClickedSkill': skillName,
        'lastClickedSkillIndex': skillIndex,
        'lastClickedSkillAt': DateTime.now().toIso8601String(),
      }),
    );
    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getSkills({String? search}) async {
    String url = '$baseUrl/api/skills';
    if (search != null && search
        .trim()
        .isNotEmpty) {
      final encoded = Uri.encodeQueryComponent(search.trim());
      url += '?search=$encoded';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) {
        final map = Map<String, dynamic>.from(item);
        map['skillId'] = map['_id'];
        return map;
      }).toList();
    } else {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getSkillById(String skillId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skills/$skillId'),
      headers: {'Content-Type': 'application/json'},
    );

    print('API getSkillById status: ${response.statusCode}');
    print('API getSkillById body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);

        // Sometimes backend returns skill directly, or wrapped in { "data": skill }
        if (decoded is Map<String, dynamic>) {
          final skill = decoded.containsKey('data') ? decoded['data'] : decoded;
          skill['skillId'] = skill['_id'] ?? skillId;
          return skill;
        } else {
          print('Unexpected format: not a Map');
        }
      } catch (e) {
        print('Error decoding skill by id: $e');
      }
    } else {
      print('Error fetching skill: ${response.statusCode}');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getReceivedRequests(
      String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/requests?receiverId=$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSentRequests(
      String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/requests?senderId=$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<bool> acceptRequest(String requestId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/requests/$requestId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': 'accepted'}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> declineRequest(String requestId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/requests/$requestId'),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

  static Future<bool> isBookmarked(String userId, String skillId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/$userId/bookmarks/$skillId'),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

  static Future<bool> addBookmark(String userId, String skillId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/$userId/bookmarks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'skillId': skillId}),
    );
    return response.statusCode == 201;
  }

  static Future<bool> removeBookmark(String userId, String skillId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/users/$userId/bookmarks/$skillId'),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

  static Future<bool> isRequestSent(String userId, String skillId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/requests?senderId=$userId&skillId=$skillId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List && data.isNotEmpty;
    }
    return false;
  }

  static Future<bool> sendRequest({
    required String skillId,
    required String title,
    required String senderId,
    required String receiverId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/requests'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'skillId': skillId,
        'title': title,
        'senderId': senderId,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
    return response.statusCode == 201;
  }

  // LESSONS (MongoDB)
  static Future<Map<String, dynamic>?> createLesson(Map<String, dynamic> lessonData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/lessons'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(lessonData),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateLesson(String lessonId, Map<String, dynamic> lessonData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/lessons/$lessonId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(lessonData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getLessonsForUser({String? instructorId, String? studentId}) async {
    String url = '$baseUrl/api/lessons?';
    if (instructorId != null) url += 'instructorId=$instructorId&';
    if (studentId != null) url += 'studentId=$studentId&';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getLessonById(String lessonId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/lessons/$lessonId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<bool> deleteLesson(String lessonId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/lessons/$lessonId'),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/by-email?email=$email'),
      headers: {'Content-Type': 'application/json'},
    );
    print('getUserByEmail status: \\${response.statusCode}');
    print('getUserByEmail body: \\${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Always map _id to userId for consistency
      if (data != null && data['_id'] != null) {
        data['userId'] = data['_id'];
      }
      return data;
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createUserWithGoogle(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/google-signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<bool> sendForgotPasswordOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) return true;
    return false;
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    if (response.statusCode == 200) return true;
    return false;
  }

  static Future<bool> resetPassword(String email, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'newPassword': newPassword}),
    );
    if (response.statusCode == 200) return true;
    return false;
  }

  static Future<Map<String, dynamic>> checkEmailExists(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/check-email?email=$email'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'exists': false};
    }
  }

  // Stripe Payment
  static Future<bool> makePayment(double amount, {required Function onOrderSuccess}) async {
    try {
      // 1. Call backend to create PaymentIntent
      final response = await http.post(
        Uri.parse('$baseUrl/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent');
      }
      final data = jsonDecode(response.body);
      final clientSecret = data['clientSecret'];
      if (clientSecret == null) throw Exception('No client secret');

      // 2. Initialize Stripe
      Stripe.publishableKey = 'pk_test_51SXEwXBGjrrAPkHaEO6brp2hT8ANxONrtAJLaaHfrb4UmaZkmau1V2BhtO84cQ4DbgHKjAZ6WGqUMczygl6pWcOH00V1X86tYE'; // <-- Your publishable key
      await Stripe.instance.applySettings();

      // 3. Present PaymentSheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Skill Buddy',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // 4. On success, call order saving function
      onOrderSuccess();
      return true;
    } catch (e) {
      print('Stripe payment error: $e');
      return false;
    }
  }
}