abstract class PaymentEvent {
  const PaymentEvent();
}

class LoadPaymentData extends PaymentEvent {
  const LoadPaymentData();
}

class AddCardEvent extends PaymentEvent {
  final String cardNumber;
  final String expireDate;

  const AddCardEvent({required this.cardNumber, required this.expireDate});
}

class DeleteCardEvent extends PaymentEvent {
  final int cardId;

  const DeleteCardEvent(this.cardId);
}

class SetDefaultCardEvent extends PaymentEvent {
  final int cardId;

  const SetDefaultCardEvent(this.cardId);
}

class VerifyCardEvent extends PaymentEvent {
  final int cardId;
  final String smsCode;

  const VerifyCardEvent({required this.cardId, required this.smsCode});
}

class LoadPlansEvent extends PaymentEvent {
  final bool forceRefresh;

  const LoadPlansEvent({this.forceRefresh = false});
}

class PurchasePlanEvent extends PaymentEvent {
  final int planId;

  const PurchasePlanEvent(this.planId);
}
