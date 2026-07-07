import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/share_repository.dart';
import 'share_event.dart';
import 'share_state.dart';

class ShareBloc extends Bloc<ShareEvent, ShareState> {
  final ShareRepository _repository;

  // Guards only the mutating handlers below (share/revoke/create-request/
  // approve-reject) — not the Load* handlers, which are read-only and some
  // are dispatched in pairs, so gating on the shared ShareLoading state
  // would drop one of them. A double-tap on share/revoke/approve/reject
  // while one is already in flight is a no-op instead of a duplicate
  // share/revoke/permission-decision request.
  bool _mutationInFlight = false;

  ShareBloc(this._repository) : super(const ShareInitial()) {
    on<LoadSharedByMe>(_onLoadSharedByMe);
    on<ShareFilesEvent>(_onShareFiles);
    on<RevokeShare>(_onRevokeShare);
    on<LoadSharedByMeUsers>(_onLoadSharedByMeUsers);
    on<LoadSharedByMeUser>(_onLoadSharedByMeUser);
    on<LoadSharedByMeUserFolder>(_onLoadSharedByMeUserFolder);
    on<LoadSharedWithMe>(_onLoadSharedWithMe);
    on<LoadSharedWithMeUser>(_onLoadSharedWithMeUser);
    on<LoadSharedWithMeUserFolder>(_onLoadSharedWithMeUserFolder);
    // ── новые ──
    on<CreateShareRequestEvent>(_onCreateShareRequest);
    on<LoadShareRequests>(_onLoadShareRequests);
    on<LoadShareRequestDetail>(_onLoadShareRequestDetail);
    on<UpdatePermissionStatus>(_onUpdatePermissionStatus);
  }

  Future<void> _onLoadSharedByMe(
      LoadSharedByMe event, Emitter<ShareState> emit) async {
    emit(const ShareLoading());
    try {
      final shares = await _repository.getSharedByMe();
      emit(SharedByMeLoaded(shares: shares));
    } catch (e) {
      emit(ShareError(error: e));
    }
  }

  Future<void> _onShareFiles(
      ShareFilesEvent event, Emitter<ShareState> emit) async {
    if (_mutationInFlight) return;
    _mutationInFlight = true;
    emit(const ShareLoading());
    try {
      final share = await _repository.shareFiles(event.body);
      emit(ShareSuccess(share: share));
    } catch (e) {
      emit(ShareError(error: e));
    } finally {
      _mutationInFlight = false;
    }
  }

  Future<void> _onRevokeShare(
      RevokeShare event, Emitter<ShareState> emit) async {
    if (_mutationInFlight) return;
    _mutationInFlight = true;
    emit(const ShareLoading());
    try {
      final share = await _repository.revokeShare(
        fileIds: event.fileIds,
        folderIds: event.folderIds,
        phoneNumbers: event.phoneNumbers,
      );
      emit(ShareSuccess(share: share));
    } catch (e) {
      emit(ShareError(error: e));
    } finally {
      _mutationInFlight = false;
    }
  }

  Future<void> _onLoadSharedByMeUsers(
      LoadSharedByMeUsers event, Emitter<ShareState> emit) async {
    emit(const ShareLoading());
    try {
      final users = await _repository.getSharedByMeUsers();
      // Defensive dedup — no client-side pagination here, but guards
      // against the backend returning the same user more than once.
      final seenIds = <int>{};
      final deduped =
          users.where((u) => seenIds.add(u.sharedWith.id)).toList();
      emit(SharedByMeUsersLoaded(users: deduped));
    } catch (e) {
      emit(ShareError(error: e));
    }
  }

  Future<void> _onLoadSharedByMeUser(
      LoadSharedByMeUser event, Emitter<ShareState> emit) async {
    emit(const ShareLoading());
    try {
      final response = await _repository.getSharedByMeUser(event.userId);
      emit(SharedUserFilesLoaded(response: response));
    } catch (e) {
      emit(ShareError(error: e));
    }
  }

  Future<void> _onLoadSharedByMeUserFolder(
      LoadSharedByMeUserFolder event, Emitter<ShareState> emit) async {
    emit(const ShareLoading());
    try {
      final response = await _repository.getSharedByMeUserFolder(
          event.userId, event.folderId);
      emit(SharedUserFilesLoaded(response: response));
    } catch (e) {
      emit(ShareError(error: e));
    }
  }

  Future<void> _onLoadSharedWithMe(
      LoadSharedWithMe event, Emitter<ShareState> emit) async {
    emit(const ShareLoading());
    try {
      final users = await _repository.getSharedWithMe();
      // Defensive dedup — no client-side pagination here, but guards
      // against the backend returning the same user more than once.
      final seenIds = <int>{};
      final deduped = users.where((u) => seenIds.add(u.owner.id)).toList();
      emit(SharedWithMeLoaded(users: deduped));
    } catch (e) {
      emit(ShareError(error: e));
    }
  }

  Future<void> _onLoadSharedWithMeUser(
      LoadSharedWithMeUser event, Emitter<ShareState> emit) async {
    emit(const ShareLoading());
    try {
      final response = await _repository.getSharedWithMeUser(event.userId);
      emit(SharedUserFilesLoaded(response: response));
    } catch (e) {
      emit(ShareError(error: e));
    }
  }

  Future<void> _onLoadSharedWithMeUserFolder(
      LoadSharedWithMeUserFolder event, Emitter<ShareState> emit) async {
    emit(const ShareLoading());
    try {
      final response = await _repository.getSharedWithMeUserFolder(
          event.userId, event.folderId);
      emit(SharedUserFilesLoaded(response: response));
    } catch (e) {
      emit(ShareError(error: e));
    }
  }

  Future<void> _onCreateShareRequest(
      CreateShareRequestEvent event, Emitter<ShareState> emit) async {
    if (_mutationInFlight) return;
    _mutationInFlight = true;
    emit(const ShareLoading());
    try {
      final request = await _repository.createShareRequest(event.body);
      emit(ShareRequestCreated(request: request));
    } catch (e) {
      emit(ShareError(error: e));
    } finally {
      _mutationInFlight = false;
    }
  }

  Future<void> _onLoadShareRequests(
      LoadShareRequests event, Emitter<ShareState> emit) async {
    emit(const ShareLoading());
    try {
      final requests = await _repository.getShareRequests();
      emit(ShareRequestsLoaded(requests: requests));
    } catch (e) {
      emit(ShareError(error: e));
    }
  }

  Future<void> _onLoadShareRequestDetail(
      LoadShareRequestDetail event, Emitter<ShareState> emit) async {
    emit(const ShareLoading());
    try {
      final detail = await _repository.getShareRequestDetail(event.id);
      emit(ShareRequestDetailLoaded(detail: detail));
    } catch (e) {
      emit(ShareError(error: e));
    }
  }

  Future<void> _onUpdatePermissionStatus(
      UpdatePermissionStatus event, Emitter<ShareState> emit) async {
    if (_mutationInFlight) return;
    _mutationInFlight = true;
    try {
      final permission = await _repository.updatePermissionStatus(
        permissionId: event.permissionId,
        status: event.status,
      );
      emit(PermissionStatusUpdated(permission: permission));
    } catch (e) {
      emit(ShareError(error: e));
    } finally {
      _mutationInFlight = false;
    }
  }
}