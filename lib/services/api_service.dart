import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kToken = 'auth_token';
const String _kDoctorId = 'doctor_id';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // NOTE: String.fromEnvironment does NOT work at Flutter web runtime unless
  // passed via --dart-define at compile time. Hardcode the URL directly.
  static const String baseUrl = 'https://clinicai-4zu2.onrender.com';

  late final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: '$baseUrl/api',
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(_AuthInterceptor())
        ..interceptors.add(_ErrorInterceptor());

  Dio get dio => _dio;

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    // Debug: confirm the exact URL being hit at runtime
    final loginUrl = '$baseUrl/api/auth/login';
    // ignore: avoid_print
    print('[ApiService] LOGIN → POST $loginUrl');

    final loginDio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/api',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // ignore: avoid_print
    loginDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // ignore: avoid_print
          print('[ApiService] Dio request → ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          // ignore: avoid_print
          print(
            '[ApiService] Dio response → ${response.statusCode} from ${response.realUri}',
          );
          handler.next(response);
        },
        onError: (DioException e, handler) {
          // ignore: avoid_print
          print(
            '[ApiService] Dio error → type=${e.type} status=${e.response?.statusCode} msg=${e.message}',
          );
          // ignore: avoid_print
          print('[ApiService] Dio error uri → ${e.requestOptions.uri}');
          handler.next(e);
        },
      ),
    );

    final resp = await loginDio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = resp.data as Map<String, dynamic>;

    final token = data['access_token']?.toString() ?? '';
    final doctorId = data['doctor_id']?.toString() ?? '';

    if (token.isEmpty) {
      throw Exception('Server returned empty token');
    }

    await _saveToken(token);
    await _saveDoctorId(doctorId);
    return data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final resp = await _dio.get('/auth/me');
    return resp.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kDoctorId);
  }

  // ── Dashboard ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardSummary() async {
    final resp = await _dio.get('/dashboard/summary');
    return resp.data as Map<String, dynamic>;
  }

  // ── Appointments ────────────────────────────────────────────────────────────

  Future<List<dynamic>> getAppointments({
    String filter = 'upcoming',
    String? q,
  }) async {
    final resp = await _dio.get(
      '/appointments',
      queryParameters: {
        'filter': filter,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> data,
  ) async {
    final resp = await _dio.post('/appointments', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rescheduleAppointment(
    String id,
    DateTime newStartTime, {
    int durationMinutes = 30,
  }) async {
    final resp = await _dio.patch(
      '/appointments/$id/reschedule',
      data: {
        'new_start_time': newStartTime.toIso8601String(),
        'duration_minutes': durationMinutes,
      },
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelAppointment(
    String id, {
    String reason = '',
  }) async {
    final resp = await _dio.post(
      '/appointments/$id/cancel',
      data: {'reason': reason},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeAppointment(
    String id, {
    String notes = '',
  }) async {
    final resp = await _dio.post(
      '/appointments/$id/complete',
      data: {'notes': notes},
    );
    return resp.data as Map<String, dynamic>;
  }

  // ── Patients ────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getPatients({String? q}) async {
    final resp = await _dio.get(
      '/patients',
      queryParameters: {if (q != null && q.isNotEmpty) 'q': q},
    );
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getPatient(String id) async {
    final resp = await _dio.get('/patients/$id');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> data) async {
    final resp = await _dio.post('/patients', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePatient(
    String id,
    Map<String, dynamic> data,
  ) async {
    final resp = await _dio.patch('/patients/$id', data: data);
    return resp.data as Map<String, dynamic>;
  }

  // ── Calendar ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCalendar({
    String view = 'day',
    required String date,
  }) async {
    final resp = await _dio.get(
      '/calendar',
      queryParameters: {'view': view, 'date': date},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAvailability(String date) async {
    final resp = await _dio.get(
      '/calendar/availability',
      queryParameters: {'date': date},
    );
    return resp.data as Map<String, dynamic>;
  }

  // ── Slots ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> blockSlot({
    required DateTime start,
    required DateTime end,
    String reason = '',
  }) async {
    final resp = await _dio.post(
      '/slots/block',
      data: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'reason': reason,
      },
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteBlockedSlot(String slotId) async {
    await _dio.delete('/slots/block/$slotId');
  }

  // ── Profile ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final resp = await _dio.get('/profile');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final resp = await _dio.patch('/profile', data: data);
    return resp.data as Map<String, dynamic>;
  }

  // ── Notifications ────────────────────────────────────────────────────────────

  Future<List<dynamic>> getNotifications() async {
    final resp = await _dio.get('/notifications');
    return resp.data as List<dynamic>;
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.post('/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.post('/notifications/read-all');
  }

  // ── Search ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> search(String q) async {
    final resp = await _dio.get('/search', queryParameters: {'q': q});
    return resp.data as Map<String, dynamic>;
  }

  // ── Admin ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> onboardDoctor(Map<String, dynamic> data) async {
    final resp = await _dio.post('/admin/doctors', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listDoctors() async {
    final resp = await _dio.get('/admin/doctors');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> updateDoctor(
    String doctorId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _dio.patch('/admin/doctors/$doctorId', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<void> deleteDoctor(String doctorId) async {
    await _dio.delete('/admin/doctors/$doctorId');
  }

  // ── Token helpers ────────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  static Future<String?> getDoctorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDoctorId);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
  }

  Future<void> _saveDoctorId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDoctorId, id);
  }
}

// ── Auth Interceptor ─────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await ApiService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ── Error Interceptor ─────────────────────────────────────────────────────────
// NOTE: No toasts here — individual screens handle their own error UI.
// This interceptor only re-throws so callers can handle errors themselves.

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
