import '../models/share_models.dart';
import '../remote/share_remote_data_source.dart';
import 'share_repository.dart';

/// Repository implementation that delegates to [ShareRemoteDataSource].
class ShareRepositoryImpl implements ShareRepository {
  final ShareRemoteDataSource _remoteDataSource;

  ShareRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<FileShareModel>> getSharedByMe() {
    return _remoteDataSource.getSharedByMe();
  }

  @override
  Future<FileShareModel> shareFiles(FileShareCreateModel body) {
    return _remoteDataSource.shareFiles(body);
  }

  @override
  Future<FileShareModel> revokeShare({
    List<String> fileIds = const [],
    List<String> folderIds = const [],
    List<String> phoneNumbers = const [],
  }) {
    return _remoteDataSource.revokeShare(
      fileIds: fileIds,
      folderIds: folderIds,
      phoneNumbers: phoneNumbers,
    );
  }

  @override
  Future<List<SharedByMeUserModel>> getSharedByMeUsers() {
    return _remoteDataSource.getSharedByMeUsers();
  }

  @override
  Future<ControllerDefaultResponseModel> getSharedByMeUser(int userId) {
    return _remoteDataSource.getSharedByMeUser(userId);
  }

  @override
  Future<ControllerDefaultResponseModel> getSharedByMeUserFolder(
      int userId, String folderId) {
    return _remoteDataSource.getSharedByMeUserFolder(userId, folderId);
  }

  @override
  Future<List<SharedWithMeUserModel>> getSharedWithMe() {
    return _remoteDataSource.getSharedWithMe();
  }

  @override
  Future<ControllerDefaultResponseModel> getSharedWithMeUser(int userId) {
    return _remoteDataSource.getSharedWithMeUser(userId);
  }

  @override
  Future<ControllerDefaultResponseModel> getSharedWithMeUserFolder(
      int userId, String folderId) {
    return _remoteDataSource.getSharedWithMeUserFolder(userId, folderId);
  }

  // ================= NEW SHARE REQUEST METHODS =================

  @override
  Future<ShareRequestListModel> createShareRequest(
      ShareRequestCreateModel body) {
    return _remoteDataSource.createShareRequest(body);
  }

  @override
  Future<List<ShareRequestListModel>> getShareRequests() {
    return _remoteDataSource.getShareRequests();
  }

  @override
  Future<ShareRequestDetailModel> getShareRequestDetail(int id) {
    return _remoteDataSource.getShareRequestDetail(id);
  }

  @override
  Future<ShareRequestPermission> updatePermissionStatus({
    required int permissionId,
    required String status,
  }) {
    return _remoteDataSource.updatePermissionStatus(
      permissionId: permissionId,
      status: status,
    );
  }
}
