// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Bulutcha';

  @override
  String get welcomeBack => 'Welcome back,';

  @override
  String get home => 'Home';

  @override
  String get files => 'Files';

  @override
  String get shared => 'Shared';

  @override
  String get profile => 'Profile';

  @override
  String get recent => 'Recent';

  @override
  String get myCloudStorage => 'My Cloud Storage';

  @override
  String get yourCloudStorage => 'Your cloud storage';

  @override
  String get used => 'used';

  @override
  String get total => 'total';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get myFiles => 'My Files';

  @override
  String get favourites => 'Favourites';

  @override
  String get overallStats => 'Overall Statistics';

  @override
  String get images => 'Images';

  @override
  String get videos => 'Videos';

  @override
  String get sharedByMe => 'Shared by me';

  @override
  String get sharedWithMe => 'Shared with me';

  @override
  String get participants => 'participants';

  @override
  String get folders => 'Folders';

  @override
  String get folder => 'Folder';

  @override
  String get createFolder => 'Create Folder';

  @override
  String get newFolder => 'New Folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get move => 'Move';

  @override
  String get download => 'Download';

  @override
  String get share => 'Share';

  @override
  String get preview => 'Preview';

  @override
  String get details => 'Details';

  @override
  String get open => 'Open';

  @override
  String get addToFavourites => 'Add to favourites';

  @override
  String get removeFromFavourites => 'Remove from favourites';

  @override
  String get deleteConfirm => 'Delete?';

  @override
  String deleteConfirmMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?\nThis action is irreversible.';
  }

  @override
  String get successfullyMoved => 'Successfully moved';

  @override
  String fileSaved(String name) {
    return 'File saved: $name';
  }

  @override
  String get emptyFolder => 'Nothing here yet';

  @override
  String get emptyFolderSubtitle => 'Create a folder or upload photos / videos';

  @override
  String get noFavourites => 'No favourite files';

  @override
  String get noFavouritesSubtitle => 'Tap star on a file to add it';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get photos => 'Photos';

  @override
  String get pinnedFolders => 'Pinned folders';

  @override
  String get maxPinnedFolders => 'Maximum 5 pinned folders';

  @override
  String get alreadyPinned => 'Folder already pinned';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get unpinFolder => 'Unpin folder?';

  @override
  String get shareViaLink => 'Share via link';

  @override
  String get shareByPhone => 'By phone';

  @override
  String get shareByLink => 'By link';

  @override
  String get linkName => 'Link name';

  @override
  String get generate => 'Generate';

  @override
  String get generatedLink => 'Generated link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get copy => 'Copy';

  @override
  String get copyLink => 'Copy link';

  @override
  String get shareSuccess => 'Shared successfully';

  @override
  String get addAtLeastOnePhone => 'Add at least one phone number';

  @override
  String get enter9Digits => 'Enter 9 digits';

  @override
  String get enterLinkName => 'Enter link name';

  @override
  String get fileDetails => 'File details';

  @override
  String get folderDetails => 'Folder details';

  @override
  String get fileName => 'Name';

  @override
  String get fileSize => 'Size';

  @override
  String get createdAt => 'Created at';

  @override
  String get capturedAt => 'Captured at';

  @override
  String get totalSize => 'Total size';

  @override
  String get fileCount => 'Files';

  @override
  String get folderCount => 'Folders';

  @override
  String get shareRequests => 'Share Requests';

  @override
  String get shareRequestsSubtitle => 'Manage links and access';

  @override
  String get shareRequestDetails => 'Share request details';

  @override
  String get request => 'Request';

  @override
  String get linkNameLabel => 'LINK NAME';

  @override
  String get shareLinkLabel => 'SHARE LINK';

  @override
  String get permissionRequests => 'PERMISSION REQUESTS';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get review => 'Review';

  @override
  String get reviewAccessRequest => 'Review access request';

  @override
  String get reviewAccessRequestSubtitle => 'Choose whether this user should get access.';

  @override
  String get reject => 'Reject';

  @override
  String get approve => 'Approve';

  @override
  String get accessApproved => 'Access approved';

  @override
  String get accessRejected => 'Access rejected';

  @override
  String get noShareRequests => 'No share requests';

  @override
  String get noShareRequestsSubtitle => 'Share files via link and they will appear here';

  @override
  String get personalData => 'PERSONAL DATA';

  @override
  String get changeName => 'Change name';

  @override
  String get changePhone => 'Change phone';

  @override
  String get changePassword => 'Change password';

  @override
  String get newName => 'New name';

  @override
  String get newPhone => 'New number';

  @override
  String get oldPassword => 'Old password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Minimum 8 characters';

  @override
  String get nameUpdated => 'Name updated';

  @override
  String get phoneUpdated => 'Phone updated';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get avatarUpdated => 'Avatar updated';

  @override
  String get storage => 'Storage';

  @override
  String get language => 'Language';

  @override
  String get theme => 'APPEARANCE';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get logout => 'Sign out';

  @override
  String get logoutConfirm => 'Sign out';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to sign out?';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String selected(int count) {
    return 'Selected: $count';
  }

  @override
  String get selectAll => 'All';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get uploadFiles => 'Upload files';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get home_breadcrumb => 'Home';

  @override
  String get favourites_breadcrumb => 'Favourites';

  @override
  String selectedCount(int count) {
    return 'Selected: $count';
  }

  @override
  String get addedToFavourites => 'Added to favourites';

  @override
  String get favouriteUpdateFailed => 'Failed to update favourites';

  @override
  String get unitBytes => 'bytes';

  @override
  String get unitKb => 'KB';

  @override
  String get unitMb => 'MB';

  @override
  String get unitGb => 'GB';

  @override
  String get unitTb => 'TB';

  @override
  String storageUsedOfLimit(String used, String limit) {
    return '$used used of $limit';
  }

  @override
  String get couldNotOpenImage => 'Could not open image';

  @override
  String get couldNotOpenVideo => 'Could not open video';

  @override
  String get videoFormatNotSupported => 'This video format is not supported for playback';

  @override
  String get noSharedWithMe => 'No one has shared files';

  @override
  String get noSharedWithMeSubtitle => 'When someone shares a file — it will appear here';

  @override
  String get noSharedByMe => 'You haven\'t shared with anyone yet';

  @override
  String get noSharedByMeSubtitle => 'Tap the share button to share files';

  @override
  String get noSharedItems => 'No shared items';

  @override
  String sharedWithLabel(String name) {
    return 'For $name';
  }

  @override
  String get revokeAccess => 'Revoke access';

  @override
  String revokeAccessConfirm(String name) {
    return 'Revoke access to \"$name\"?';
  }

  @override
  String get revoke => 'Revoke';

  @override
  String filesCount(int count) {
    return '$count files';
  }

  @override
  String get openLabel => 'Open';

  @override
  String get usersTab => 'Users';

  @override
  String get sharedItemsTab => 'Shared items';

  @override
  String get newNameHint => 'New name';

  @override
  String deleteItems(int count) {
    return '$count items';
  }

  @override
  String get pinLabel => '📌 Pin';

  @override
  String get unpinLabel => '📌 Unpin';

  @override
  String get favourite => 'Favourite';

  @override
  String get syncFolderName => '📱 Sync';

  @override
  String syncStatusUploading(int uploaded, int total) {
    return 'Uploading $uploaded of $total';
  }

  @override
  String syncStatusWaiting(int count) {
    return 'Waiting to sync: $count';
  }

  @override
  String get syncStatusComplete => 'Sync complete';

  @override
  String syncStatusErrors(int count) {
    return '$count errors';
  }

  @override
  String get syncSettingsTitle => 'Auto Sync';

  @override
  String get syncEnableToggle => 'Enable auto sync';

  @override
  String get syncWifiOnly => 'Wi-Fi only';

  @override
  String get syncNowButton => 'Sync now';

  @override
  String get syncResetButton => 'Reset queue';

  @override
  String get syncFolderReadOnly => 'This is your Sync folder. Files here are managed automatically.';

  @override
  String get syncResetConfirmTitle => 'Reset queue?';

  @override
  String get syncResetConfirmMessage => 'All records will be deleted. The app will re-scan the gallery after that.';

  @override
  String get syncResetConfirmButton => 'Reset';

  @override
  String get syncAutoUpload => 'Automatically upload photos and videos';

  @override
  String get syncNoMobileData => 'Do not sync over mobile data';

  @override
  String get syncStatusTitle => 'Sync status';

  @override
  String get syncStatusPending => 'Pending';

  @override
  String get syncStatusUploading2 => 'Uploading';

  @override
  String get syncStatusDone => 'Done';

  @override
  String get syncStatusFailed => 'Errors';

  @override
  String get syncStop => 'Stop';

  @override
  String get syncResumeButton => 'Resume Sync';

  @override
  String get syncSelectedFiles => 'Selected files';

  @override
  String get syncSelectedFilesSubtitle => 'Sync only selected';

  @override
  String syncSelectedCount(int count) {
    return '$count media selected';
  }

  @override
  String get selectSyncFilesTitle => 'Select files to sync';

  @override
  String get selectSyncFilesDone => 'Done';

  @override
  String get selectSyncFilesPermissionDenied => 'No access to gallery. Allow access in system settings.';

  @override
  String get syncTotal => 'Total';

  @override
  String get uploadedLabel => 'Uploaded';

  @override
  String get uploadPageTitle => 'Upload';

  @override
  String get cancelledLabel => 'Cancelled';

  @override
  String get fileTypes => 'File types';

  @override
  String get viewAll => 'View all';

  @override
  String get recentFiles => 'Gallery files';

  @override
  String get sync => 'Sync';

  @override
  String get image => 'Image';

  @override
  String get video => 'Video';

  @override
  String filesLabel(String count) {
    return '$count files';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm => 'Delete account';

  @override
  String get deleteAccountConfirmMessage => 'Are you sure you want to delete your account? This action is irreversible.';

  @override
  String get storageSubtitle => 'Track your storage usage and manage your plan.';

  @override
  String get activeSubscriptionDetails => 'Active subscription details';

  @override
  String get planName => 'Plan name';

  @override
  String get storageLimitLabel => 'Storage limit';

  @override
  String get available => 'Available';

  @override
  String get billingMonthly => 'Monthly';

  @override
  String get billingYearly => 'Yearly';

  @override
  String upgradeToPlan(String name) {
    return 'Upgrade to $name';
  }

  @override
  String get filesAlreadyInFolder => 'Files are already in this folder';

  @override
  String get folderEmpty => 'Folder is empty';

  @override
  String get accessRevoked => 'Access revoked';

  @override
  String get userNotFound => 'User not found';

  @override
  String get paymentAndSubscription => 'Payment & Subscription';

  @override
  String get cardDeleted => 'Card deleted';

  @override
  String get cardSetAsDefault => 'Card set as default';

  @override
  String get myCards => 'My cards';

  @override
  String get addCard => 'Add card';

  @override
  String get noCardsLinked => 'No cards linked';

  @override
  String get noSubscription => 'No subscription';

  @override
  String get currentPlan => 'Current plan';

  @override
  String get changePlan => 'Change plan';

  @override
  String get choosePlan => 'Choose plan';

  @override
  String storageUsed(String used) {
    return '$used used';
  }

  @override
  String subscriptionUntil(String date) {
    return 'Until: $date';
  }

  @override
  String get cardStatusActive => 'Active';

  @override
  String get cardStatusPending => 'Pending confirmation';

  @override
  String get cardStatusBlocked => 'Blocked';

  @override
  String get cardDefaultLabel => 'Default';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get deleteCardTitle => 'Delete card?';

  @override
  String deleteCardMessage(String number) {
    return 'Card $number will be deleted.';
  }

  @override
  String get cardNumberLabel => 'Card number';

  @override
  String get enterCardNumber => 'Enter card number';

  @override
  String get cardNumber16Digits => 'Card number must be 16 digits';

  @override
  String get expiryDate => 'Expiry date';

  @override
  String get enterExpiryDate => 'Enter expiry date';

  @override
  String get expiryDateFormat => 'Format: MM/YY';

  @override
  String get invalidMonth => 'Invalid month';

  @override
  String get validThruLabel => 'VALID THRU';

  @override
  String get verifyCardTitle => 'Card verification';

  @override
  String get enterSmsCode => 'Enter SMS code';

  @override
  String smsCodeSentFor(String number) {
    return 'Code sent to confirm card\n$number';
  }

  @override
  String get cardAddedSuccess => 'Card added successfully';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get plansTitle => 'Plans';

  @override
  String get noPlans => 'No plans available';

  @override
  String get confirmPurchaseTitle => 'Confirm';

  @override
  String confirmPurchaseMessage(String name, String price, String period) {
    return 'Subscribe to «$name» for $price UZS / $period?';
  }

  @override
  String get updatePlan => 'Subscribe';

  @override
  String get freeLabel => 'Free';

  @override
  String storageFeature(String storage) {
    return '$storage Storage';
  }

  @override
  String get dataPreservedNote => 'Your data will be preserved when upgrading.';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get switchPlanButton => 'Switch to this plan';

  @override
  String get addCardPrompt => 'Add a card to pay';

  @override
  String get downgradeWarningTitle => 'Confirm plan change';

  @override
  String downgradeWarningMessage(String used, String plan, String limit) {
    return 'You are currently using $used. The «$plan» plan offers $limit. After switching, syncing new files will pause until your storage is within the limit. Existing files will not be deleted.';
  }

  @override
  String get continueAnyway => 'Switch anyway';

  @override
  String get staySamePlan => 'Stay on current plan';

  @override
  String get popularBadge => 'Popular';

  @override
  String get cardTypeUzcard => 'Uzcard';

  @override
  String get cardTypeHumo => 'Humo';

  @override
  String get cardTypeVisa => 'Visa';

  @override
  String get cardTypeMastercard => 'Mastercard';

  @override
  String get cardTypeUnknown => 'Card';

  @override
  String get errorInvalidCredentials => 'Incorrect phone number or password';

  @override
  String get errorUserNotFound => 'User not found';

  @override
  String get errorInvalidCode => 'Invalid verification code';

  @override
  String get errorSessionExpired => 'Session expired, please try again';

  @override
  String get errorSessionExpiredRelogin => 'Session expired. Please sign in again';

  @override
  String get errorUserAlreadyExists => 'A user with this phone number already exists';

  @override
  String get genericErrorFallback => 'Something went wrong, please try again later';

  @override
  String get planNameFree => 'Free';

  @override
  String get planNameStart => 'Start';

  @override
  String get planNamePlus => 'Plus';

  @override
  String get planNameFamily => 'Family';

  @override
  String get planNamePro => 'Pro';

  @override
  String get clearDoneButton => 'Clear';

  @override
  String get allUploadedStatus => 'All uploaded!';

  @override
  String get noNetworkWaiting => 'No network — waiting...';

  @override
  String uploadingProgress(int current, int total) {
    return 'Uploading $current of $total...';
  }

  @override
  String get tapToSelectFiles => 'Tap to select';

  @override
  String get photosAndVideosOnly => 'Photos and videos only';

  @override
  String uploadingCountBadge(int count) {
    return '$count uploading';
  }

  @override
  String pausedCountBadge(int count) {
    return '$count paused';
  }

  @override
  String doneCountBadge(int count) {
    return '$count done';
  }

  @override
  String get addFilesButton => 'Add';

  @override
  String get waitingForNetworkShort => 'Waiting for network...';

  @override
  String get uploadingEllipsis => 'Uploading...';

  @override
  String get selectPhotosVideos => 'Select photos / videos';

  @override
  String get uploadMoreButton => 'Upload more';

  @override
  String get addMoreButton => 'Add more';

  @override
  String get pausedWillResumeAuto => 'No network — will resume automatically';

  @override
  String shareButtonWithCount(int count) {
    return 'Share ($count)';
  }

  @override
  String filesAndFoldersCount(int files, int folders) {
    return '$files files, $folders folders';
  }

  @override
  String get chooseFolderTitle => 'Choose folder';

  @override
  String get homeFolderLabel => 'Home';

  @override
  String get invalidPhoneNumber => 'Invalid phone number';

  @override
  String get repeatPasswordHint => 'Repeat your password';

  @override
  String get removedFromFavourites => 'Removed from favourites';

  @override
  String get alreadyInFavourites => 'Selected files are already in favourites';

  @override
  String get cannotMoveIntoItself => 'Can\'t move a folder into itself';

  @override
  String get forgotPasswordTitle => 'Forgot Password?';

  @override
  String get forgotPasswordSubtitle => 'Enter your phone number and we\'ll send you a code to reset your password.';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get sendOtpCodeButton => 'Send OTP Code';

  @override
  String get verifyOtpCodeTitle => 'Verify OTP Code';

  @override
  String get otpSentToPrefix => 'We sent a 6-digit code to ';

  @override
  String get enterCompleteOtpCode => 'Enter the complete 6-digit code';

  @override
  String get verifyButton => 'Verify';

  @override
  String get resendCodeButton => 'Resend Code';

  @override
  String get otpCodeResentMessage => 'OTP code resent';

  @override
  String get setNewPasswordTitle => 'Set New Password';

  @override
  String get setNewPasswordSubtitle => 'Create a strong password with at least 8 characters.';

  @override
  String get enterNewPasswordHint => 'Enter new password';

  @override
  String get confirmNewPasswordHint => 'Confirm new password';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get passwordResetSuccessMessage => 'Password reset successfully!';

  @override
  String get errorOtpStillValid => 'Previous verification code is still valid. Please wait before requesting a new one.';

  @override
  String get loginWelcomeTitle => 'Welcome back to\nBulutcha';

  @override
  String get loginSubtitle => 'Please sign in to access your secure files.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get enterYourPasswordHint => 'Enter your password';

  @override
  String get signInButton => 'Sign In';

  @override
  String get noAccountPrompt => 'Don\'t have an account? ';

  @override
  String get registerLink => 'Register';

  @override
  String get enterOtpCodeTitle => 'Enter OTP Code';
}
