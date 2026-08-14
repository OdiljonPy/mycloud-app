import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/payment_models.dart';

class PaymentRepository {
  final Dio _dio = DioClient.instance;

  String _extractError(dynamic data) {
    if (data == null) return 'Unknown error';
    if (data is Map) {
      if (data.containsKey('detail')) return data['detail'].toString();
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('non_field_errors')) {
        final errs = data['non_field_errors'];
        return errs is List ? errs.join(', ') : errs.toString();
      }
      return data.values.join(', ');
    } else if (data is List) {
      return data.join(', ');
    }
    return data.toString();
  }

  Future<List<CardToken>> getCards() async {
    try {
      final r = await _dio.get('/payment/cards/');
      final raw = (r.data is List ? r.data : (r.data['results'] ?? [])) as List;
      return raw
          .map((e) => CardToken.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CardToken> addCard({
    required String cardNumber,
    required String expireDate,
  }) async {
    try {
      final r = await _dio.post('/payment/cards/', data: {
        'card_number': cardNumber,
        'expire_date': expireDate,
      });
      return CardToken.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> deleteCard(int cardId) async {
    try {
      await _dio.delete('/payment/cards/$cardId/');
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CardToken> setDefaultCard(int cardId) async {
    try {
      final r = await _dio.post('/payment/cards/$cardId/set-default/');
      return CardToken.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CardToken> verifyCard({
    required int cardId,
    required String smsCode,
  }) async {
    try {
      final r = await _dio.post(
        '/payment/cards/$cardId/verify/',
        data: {'sms_code': smsCode},
      );
      return CardToken.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<PurchasePlanResponse> purchasePlan(int planId) async {
    try {
      final r = await _dio.post(
        '/payment/subscriptions/purchase/',
        data: {'plan_id': planId},
      );
      return PurchasePlanResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  // Plans are effectively static (pricing/storage tiers) — cached for the
  // app session so every _loadData()/page-open doesn't re-fetch the same
  // list (was ~64 GET /storage/plan/ calls in one logged session).
  static List<Plan>? _cachedPlans;

  static void clearPlansCache() => _cachedPlans = null;

  Future<List<Plan>> getPlans({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPlans != null) return _cachedPlans!;
    try {
      final r = await _dio.get('/storage/plan/');
      final raw = (r.data is List ? r.data : (r.data['results'] ?? [])) as List;
      final plans =
          raw.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
      _cachedPlans = plans;
      return plans;
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CurrentSubscription?> getCurrentSubscription() async {
    try {
      final r = await _dio.get('/storage/subscription/current/');
      return CurrentSubscription.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
