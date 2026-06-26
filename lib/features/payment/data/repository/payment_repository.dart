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

  // GET /payment/cards/
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

  // POST /payment/cards/
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

  // DELETE /payment/cards/{card_id}/
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

  // POST /payment/cards/{card_id}/set-default/
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

  // POST /payment/cards/{card_id}/verify/
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

  // POST /payment/subscriptions/purchase/
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

  // GET /storage/plan/
  Future<List<Plan>> getPlans() async {
    try {
      final r = await _dio.get('/storage/plan/');
      final raw = (r.data is List ? r.data : (r.data['results'] ?? [])) as List;
      return raw
          .map((e) => Plan.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  // GET /storage/subscription/current/
  Future<CurrentSubscription> getCurrentSubscription() async {
    try {
      final r = await _dio.get('/storage/subscription/current/');
      return CurrentSubscription.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException(
        message: _extractError(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
