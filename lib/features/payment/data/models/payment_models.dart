// Models strictly matching Swagger API definitions.

class CardToken {
  final int id;
  final String maskedCardNumber;
  final bool isDefault;
  final String status;

  const CardToken({
    required this.id,
    required this.maskedCardNumber,
    required this.isDefault,
    required this.status,
  });

  factory CardToken.fromJson(Map<String, dynamic> json) => CardToken(
        id: json['id'] as int? ?? 0,
        maskedCardNumber: json['masked_card_number'] as String? ?? '',
        isDefault: json['is_default'] as bool? ?? false,
        status: json['status'] as String? ?? '',
      );
}

class PlanItem {
  final int id;
  final String feature;
  final bool isAvailable;

  const PlanItem({
    required this.id,
    required this.feature,
    required this.isAvailable,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
        id: json['id'] as int? ?? 0,
        feature: json['feature'] as String? ?? '',
        isAvailable: json['is_available'] as bool? ?? false,
      );
}

class Plan {
  final int id;
  final String name;
  final String price;
  final String billingPeriod;
  final int storage;
  final bool isPopular;
  final List<PlanItem> items;

  const Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.billingPeriod,
    required this.storage,
    required this.isPopular,
    required this.items,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        price: json['price'] as String? ?? '0',
        billingPeriod: json['billing_period'] as String? ?? '',
        storage: json['storage'] as int? ?? 0,
        isPopular: json['is_popular'] as bool? ?? false,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CurrentSubscription {
  final int? planId;
  final String? planName;
  final String? billingPeriod;
  final String? startsAt;
  final String? endsAt;
  final int storageLimit;
  final int usedStorage;
  final int availableStorage;

  const CurrentSubscription({
    this.planId,
    this.planName,
    this.billingPeriod,
    this.startsAt,
    this.endsAt,
    required this.storageLimit,
    required this.usedStorage,
    required this.availableStorage,
  });

  factory CurrentSubscription.fromJson(Map<String, dynamic> json) =>
      CurrentSubscription(
        planId: json['plan_id'] as int?,
        planName: json['plan_name'] as String?,
        billingPeriod: json['billing_period'] as String?,
        startsAt: json['starts_at'] as String?,
        endsAt: json['ends_at'] as String?,
        storageLimit: json['storage_limit'] as int? ?? 0,
        usedStorage: json['used_storage'] as int? ?? 0,
        availableStorage: json['available_storage'] as int? ?? 0,
      );
}

class PurchasePlanResponse {
  final String message;
  final int subscriptionId;
  final int planId;
  final String planName;
  final String billingPeriod;
  final int storageLimit;
  final int usedStorage;
  final int availableStorage;
  final String startsAt;
  final String? endsAt;

  const PurchasePlanResponse({
    required this.message,
    required this.subscriptionId,
    required this.planId,
    required this.planName,
    required this.billingPeriod,
    required this.storageLimit,
    required this.usedStorage,
    required this.availableStorage,
    required this.startsAt,
    this.endsAt,
  });

  factory PurchasePlanResponse.fromJson(Map<String, dynamic> json) =>
      PurchasePlanResponse(
        message: json['message'] as String? ?? '',
        subscriptionId: json['subscription_id'] as int? ?? 0,
        planId: json['plan_id'] as int? ?? 0,
        planName: json['plan_name'] as String? ?? '',
        billingPeriod: json['billing_period'] as String? ?? '',
        storageLimit: json['storage_limit'] as int? ?? 0,
        usedStorage: json['used_storage'] as int? ?? 0,
        availableStorage: json['available_storage'] as int? ?? 0,
        startsAt: json['starts_at'] as String? ?? '',
        endsAt: json['ends_at'] as String?,
      );
}

class PaymentLinkResponse {
  final String? paymentLink;
  final String? merchantTransId;
  final String? amount;
  final int planId;
  final String planName;
  final int? transactionId;
  final String message;

  const PaymentLinkResponse({
    this.paymentLink,
    this.merchantTransId,
    this.amount,
    required this.planId,
    required this.planName,
    this.transactionId,
    required this.message,
  });

  factory PaymentLinkResponse.fromJson(Map<String, dynamic> json) =>
      PaymentLinkResponse(
        paymentLink: json['payment_link'] as String?,
        merchantTransId: json['merchant_trans_id'] as String?,
        amount: json['amount'] as String?,
        planId: json['plan_id'] as int? ?? 0,
        planName: json['plan_name'] as String? ?? '',
        transactionId: json['transaction_id'] as int?,
        message: json['message'] as String? ?? '',
      );
}
