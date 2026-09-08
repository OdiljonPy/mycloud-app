import '../../data/models/payment_models.dart';

abstract class PaymentState {
  const PaymentState();
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentDataLoaded extends PaymentState {
  final List<CardToken> cards;
  final CurrentSubscription? subscription;

  const PaymentDataLoaded({
    required this.cards,
    required this.subscription,
  });
}

class CardAdded extends PaymentState {
  final CardToken card;

  const CardAdded(this.card);
}

class CardVerified extends PaymentState {
  final CardToken card;

  const CardVerified(this.card);
}

class CardDeleted extends PaymentState {
  final int cardId;

  const CardDeleted(this.cardId);
}

class CardSetDefault extends PaymentState {
  final CardToken card;

  const CardSetDefault(this.card);
}

class PlansLoaded extends PaymentState {
  final List<Plan> plans;

  const PlansLoaded(this.plans);
}

class PlanPurchased extends PaymentState {
  final PurchasePlanResponse response;

  const PlanPurchased(this.response);
}

class PlanLinkGenerated extends PaymentState {
  final PaymentLinkResponse response;

  const PlanLinkGenerated(this.response);
}

class PaymentError extends PaymentState {
  final Object error;

  const PaymentError(this.error);
}
