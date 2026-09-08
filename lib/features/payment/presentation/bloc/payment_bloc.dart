import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/payment_repository.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _repository;

  // Guards only the mutating (money-moving) handlers below — not
  // LoadPaymentData/LoadPlansEvent, which are read-only and dispatched
  // together on page open, so gating on the shared PaymentLoading state
  // would drop one of that pair. A double-tap on Add/Delete/Verify/Set
  // default/Purchase while one is already in flight is a no-op instead of
  // a duplicate charge/verification/deletion request.
  bool _mutationInFlight = false;

  PaymentBloc(this._repository) : super(const PaymentInitial()) {
    on<LoadPaymentData>(_onLoadPaymentData);
    on<AddCardEvent>(_onAddCard);
    on<DeleteCardEvent>(_onDeleteCard);
    on<SetDefaultCardEvent>(_onSetDefaultCard);
    on<VerifyCardEvent>(_onVerifyCard);
    on<LoadPlansEvent>(_onLoadPlans);
    on<PurchasePlanEvent>(_onPurchasePlan);
    on<PurchasePlanLinkEvent>(_onPurchasePlanLink);
  }

  Future<void> _onLoadPaymentData(
      LoadPaymentData event, Emitter<PaymentState> emit) async {
    emit(const PaymentLoading());
    try {
      final cards = await _repository.getCards();
      final subscription = await _repository.getCurrentSubscription();
      emit(PaymentDataLoaded(cards: cards, subscription: subscription));
    } catch (e) {
      emit(PaymentError(e));
    }
  }

  Future<void> _onAddCard(
      AddCardEvent event, Emitter<PaymentState> emit) async {
    if (_mutationInFlight) return;
    _mutationInFlight = true;
    emit(const PaymentLoading());
    try {
      final card = await _repository.addCard(
        cardNumber: event.cardNumber,
        expireDate: event.expireDate,
      );
      emit(CardAdded(card));
    } catch (e) {
      emit(PaymentError(e));
    } finally {
      _mutationInFlight = false;
    }
  }

  Future<void> _onDeleteCard(
      DeleteCardEvent event, Emitter<PaymentState> emit) async {
    if (_mutationInFlight) return;
    _mutationInFlight = true;
    emit(const PaymentLoading());
    try {
      await _repository.deleteCard(event.cardId);
      emit(CardDeleted(event.cardId));
    } catch (e) {
      emit(PaymentError(e));
    } finally {
      _mutationInFlight = false;
    }
  }

  Future<void> _onSetDefaultCard(
      SetDefaultCardEvent event, Emitter<PaymentState> emit) async {
    if (_mutationInFlight) return;
    _mutationInFlight = true;
    emit(const PaymentLoading());
    try {
      final card = await _repository.setDefaultCard(event.cardId);
      emit(CardSetDefault(card));
    } catch (e) {
      emit(PaymentError(e));
    } finally {
      _mutationInFlight = false;
    }
  }

  Future<void> _onVerifyCard(
      VerifyCardEvent event, Emitter<PaymentState> emit) async {
    if (_mutationInFlight) return;
    _mutationInFlight = true;
    emit(const PaymentLoading());
    try {
      final card = await _repository.verifyCard(
        cardId: event.cardId,
        smsCode: event.smsCode,
      );
      emit(CardVerified(card));
    } catch (e) {
      emit(PaymentError(e));
    } finally {
      _mutationInFlight = false;
    }
  }

  Future<void> _onLoadPlans(
      LoadPlansEvent event, Emitter<PaymentState> emit) async {
    emit(const PaymentLoading());
    try {
      final plans = await _repository.getPlans(forceRefresh: event.forceRefresh);
      emit(PlansLoaded(plans));
    } catch (e) {
      emit(PaymentError(e));
    }
  }

  Future<void> _onPurchasePlan(
      PurchasePlanEvent event, Emitter<PaymentState> emit) async {
    if (_mutationInFlight) return;
    _mutationInFlight = true;
    emit(const PaymentLoading());
    try {
      final response = await _repository.purchasePlan(event.planId);
      emit(PlanPurchased(response));
    } catch (e) {
      emit(PaymentError(e));
    } finally {
      _mutationInFlight = false;
    }
  }

  Future<void> _onPurchasePlanLink(
      PurchasePlanLinkEvent event, Emitter<PaymentState> emit) async {
    if (_mutationInFlight) return;
    _mutationInFlight = true;
    emit(const PaymentLoading());
    try {
      final response = await _repository.purchasePlanLink(event.planId);
      emit(PlanLinkGenerated(response));
    } catch (e) {
      emit(PaymentError(e));
    } finally {
      _mutationInFlight = false;
    }
  }
}
