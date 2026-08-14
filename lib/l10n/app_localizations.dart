import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Bulutcha'**
  String get appName;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @shared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shared;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @myCloudStorage.
  ///
  /// In en, this message translates to:
  /// **'My Cloud Storage'**
  String get myCloudStorage;

  /// No description provided for @yourCloudStorage.
  ///
  /// In en, this message translates to:
  /// **'Your cloud storage'**
  String get yourCloudStorage;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get used;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get total;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @myFiles.
  ///
  /// In en, this message translates to:
  /// **'My Files'**
  String get myFiles;

  /// No description provided for @favourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favourites;

  /// No description provided for @overallStats.
  ///
  /// In en, this message translates to:
  /// **'Overall Statistics'**
  String get overallStats;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @sharedByMe.
  ///
  /// In en, this message translates to:
  /// **'Shared by me'**
  String get sharedByMe;

  /// No description provided for @sharedWithMe.
  ///
  /// In en, this message translates to:
  /// **'Shared with me'**
  String get sharedWithMe;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'participants'**
  String get participants;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// No description provided for @createFolder.
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get createFolder;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get newFolder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @addToFavourites.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get addToFavourites;

  /// No description provided for @removeFromFavourites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get removeFromFavourites;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get deleteConfirm;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?\nThis action is irreversible.'**
  String deleteConfirmMessage(String name);

  /// No description provided for @successfullyMoved.
  ///
  /// In en, this message translates to:
  /// **'Successfully moved'**
  String get successfullyMoved;

  /// No description provided for @fileSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved: {name}'**
  String fileSaved(String name);

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyFolder;

  /// No description provided for @emptyFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a folder or upload photos / videos'**
  String get emptyFolderSubtitle;

  /// No description provided for @noFavourites.
  ///
  /// In en, this message translates to:
  /// **'No favourite files'**
  String get noFavourites;

  /// No description provided for @noFavouritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap star on a file to add it'**
  String get noFavouritesSubtitle;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @pinnedFolders.
  ///
  /// In en, this message translates to:
  /// **'Pinned folders'**
  String get pinnedFolders;

  /// No description provided for @maxPinnedFolders.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 pinned folders'**
  String get maxPinnedFolders;

  /// No description provided for @alreadyPinned.
  ///
  /// In en, this message translates to:
  /// **'Folder already pinned'**
  String get alreadyPinned;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @unpinFolder.
  ///
  /// In en, this message translates to:
  /// **'Unpin folder?'**
  String get unpinFolder;

  /// No description provided for @shareViaLink.
  ///
  /// In en, this message translates to:
  /// **'Share via link'**
  String get shareViaLink;

  /// No description provided for @shareByPhone.
  ///
  /// In en, this message translates to:
  /// **'By phone'**
  String get shareByPhone;

  /// No description provided for @shareByLink.
  ///
  /// In en, this message translates to:
  /// **'By link'**
  String get shareByLink;

  /// No description provided for @linkName.
  ///
  /// In en, this message translates to:
  /// **'Link name'**
  String get linkName;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @generatedLink.
  ///
  /// In en, this message translates to:
  /// **'Generated link'**
  String get generatedLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @shareSuccess.
  ///
  /// In en, this message translates to:
  /// **'Shared successfully'**
  String get shareSuccess;

  /// No description provided for @addAtLeastOnePhone.
  ///
  /// In en, this message translates to:
  /// **'Add at least one phone number'**
  String get addAtLeastOnePhone;

  /// No description provided for @enter9Digits.
  ///
  /// In en, this message translates to:
  /// **'Enter 9 digits'**
  String get enter9Digits;

  /// No description provided for @enterLinkName.
  ///
  /// In en, this message translates to:
  /// **'Enter link name'**
  String get enterLinkName;

  /// No description provided for @fileDetails.
  ///
  /// In en, this message translates to:
  /// **'File details'**
  String get fileDetails;

  /// No description provided for @folderDetails.
  ///
  /// In en, this message translates to:
  /// **'Folder details'**
  String get folderDetails;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fileName;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fileSize;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createdAt;

  /// No description provided for @capturedAt.
  ///
  /// In en, this message translates to:
  /// **'Captured at'**
  String get capturedAt;

  /// No description provided for @totalSize.
  ///
  /// In en, this message translates to:
  /// **'Total size'**
  String get totalSize;

  /// No description provided for @fileCount.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get fileCount;

  /// No description provided for @folderCount.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folderCount;

  /// No description provided for @shareRequests.
  ///
  /// In en, this message translates to:
  /// **'Share Requests'**
  String get shareRequests;

  /// No description provided for @shareRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage links and access'**
  String get shareRequestsSubtitle;

  /// No description provided for @shareRequestDetails.
  ///
  /// In en, this message translates to:
  /// **'Share request details'**
  String get shareRequestDetails;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @linkNameLabel.
  ///
  /// In en, this message translates to:
  /// **'LINK NAME'**
  String get linkNameLabel;

  /// No description provided for @shareLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'SHARE LINK'**
  String get shareLinkLabel;

  /// No description provided for @permissionRequests.
  ///
  /// In en, this message translates to:
  /// **'PERMISSION REQUESTS'**
  String get permissionRequests;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @reviewAccessRequest.
  ///
  /// In en, this message translates to:
  /// **'Review access request'**
  String get reviewAccessRequest;

  /// No description provided for @reviewAccessRequestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose whether this user should get access.'**
  String get reviewAccessRequestSubtitle;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @accessApproved.
  ///
  /// In en, this message translates to:
  /// **'Access approved'**
  String get accessApproved;

  /// No description provided for @accessRejected.
  ///
  /// In en, this message translates to:
  /// **'Access rejected'**
  String get accessRejected;

  /// No description provided for @noShareRequests.
  ///
  /// In en, this message translates to:
  /// **'No share requests'**
  String get noShareRequests;

  /// No description provided for @noShareRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share files via link and they will appear here'**
  String get noShareRequestsSubtitle;

  /// No description provided for @personalData.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL DATA'**
  String get personalData;

  /// No description provided for @changeName.
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get changeName;

  /// No description provided for @changePhone.
  ///
  /// In en, this message translates to:
  /// **'Change phone'**
  String get changePhone;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @newName.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newName;

  /// No description provided for @newPhone.
  ///
  /// In en, this message translates to:
  /// **'New number'**
  String get newPhone;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get passwordTooShort;

  /// No description provided for @nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated'**
  String get nameUpdated;

  /// No description provided for @phoneUpdated.
  ///
  /// In en, this message translates to:
  /// **'Phone updated'**
  String get phoneUpdated;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get avatarUpdated;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutConfirm;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get logoutConfirmMessage;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}'**
  String selected(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @uploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Upload files'**
  String get uploadFiles;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @home_breadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_breadcrumb;

  /// No description provided for @favourites_breadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favourites_breadcrumb;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}'**
  String selectedCount(int count);

  /// No description provided for @addedToFavourites.
  ///
  /// In en, this message translates to:
  /// **'Added to favourites'**
  String get addedToFavourites;

  /// No description provided for @favouriteUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update favourites'**
  String get favouriteUpdateFailed;

  /// No description provided for @unitBytes.
  ///
  /// In en, this message translates to:
  /// **'bytes'**
  String get unitBytes;

  /// No description provided for @unitKb.
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get unitKb;

  /// No description provided for @unitMb.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get unitMb;

  /// No description provided for @unitGb.
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get unitGb;

  /// No description provided for @unitTb.
  ///
  /// In en, this message translates to:
  /// **'TB'**
  String get unitTb;

  /// No description provided for @storageUsedOfLimit.
  ///
  /// In en, this message translates to:
  /// **'{used} used of {limit}'**
  String storageUsedOfLimit(String used, String limit);

  /// No description provided for @couldNotOpenImage.
  ///
  /// In en, this message translates to:
  /// **'Could not open image'**
  String get couldNotOpenImage;

  /// No description provided for @couldNotOpenVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not open video'**
  String get couldNotOpenVideo;

  /// No description provided for @videoFormatNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This video format is not supported for playback'**
  String get videoFormatNotSupported;

  /// No description provided for @noSharedWithMe.
  ///
  /// In en, this message translates to:
  /// **'No one has shared files'**
  String get noSharedWithMe;

  /// No description provided for @noSharedWithMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone shares a file — it will appear here'**
  String get noSharedWithMeSubtitle;

  /// No description provided for @noSharedByMe.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t shared with anyone yet'**
  String get noSharedByMe;

  /// No description provided for @noSharedByMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the share button to share files'**
  String get noSharedByMeSubtitle;

  /// No description provided for @noSharedItems.
  ///
  /// In en, this message translates to:
  /// **'No shared items'**
  String get noSharedItems;

  /// No description provided for @sharedWithLabel.
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String sharedWithLabel(String name);

  /// No description provided for @revokeAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoke access'**
  String get revokeAccess;

  /// No description provided for @revokeAccessConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke access to \"{name}\"?'**
  String revokeAccessConfirm(String name);

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @filesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String filesCount(int count);

  /// No description provided for @openLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openLabel;

  /// No description provided for @usersTab.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersTab;

  /// No description provided for @sharedItemsTab.
  ///
  /// In en, this message translates to:
  /// **'Shared items'**
  String get sharedItemsTab;

  /// No description provided for @newNameHint.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newNameHint;

  /// No description provided for @deleteItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String deleteItems(int count);

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'📌 Pin'**
  String get pinLabel;

  /// No description provided for @unpinLabel.
  ///
  /// In en, this message translates to:
  /// **'📌 Unpin'**
  String get unpinLabel;

  /// No description provided for @favourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get favourite;

  /// No description provided for @syncFolderName.
  ///
  /// In en, this message translates to:
  /// **'📱 Sync'**
  String get syncFolderName;

  /// No description provided for @syncStatusUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {uploaded} of {total}'**
  String syncStatusUploading(int uploaded, int total);

  /// No description provided for @syncStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync: {count}'**
  String syncStatusWaiting(int count);

  /// No description provided for @syncStatusComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncStatusComplete;

  /// No description provided for @syncStatusErrors.
  ///
  /// In en, this message translates to:
  /// **'{count} errors'**
  String syncStatusErrors(int count);

  /// No description provided for @syncSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync'**
  String get syncSettingsTitle;

  /// No description provided for @syncEnableToggle.
  ///
  /// In en, this message translates to:
  /// **'Enable auto sync'**
  String get syncEnableToggle;

  /// No description provided for @syncWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only'**
  String get syncWifiOnly;

  /// No description provided for @syncNowButton.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNowButton;

  /// No description provided for @syncResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset queue'**
  String get syncResetButton;

  /// No description provided for @syncFolderReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This is your Sync folder. Files here are managed automatically.'**
  String get syncFolderReadOnly;

  /// No description provided for @syncResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset queue?'**
  String get syncResetConfirmTitle;

  /// No description provided for @syncResetConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'All records will be deleted. The app will re-scan the gallery after that.'**
  String get syncResetConfirmMessage;

  /// No description provided for @syncResetConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get syncResetConfirmButton;

  /// No description provided for @syncAutoUpload.
  ///
  /// In en, this message translates to:
  /// **'Automatically upload photos and videos'**
  String get syncAutoUpload;

  /// No description provided for @syncNoMobileData.
  ///
  /// In en, this message translates to:
  /// **'Do not sync over mobile data'**
  String get syncNoMobileData;

  /// No description provided for @syncStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncStatusTitle;

  /// No description provided for @syncStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get syncStatusPending;

  /// No description provided for @syncStatusUploading2.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get syncStatusUploading2;

  /// No description provided for @syncStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get syncStatusDone;

  /// No description provided for @syncStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get syncStatusFailed;

  /// No description provided for @syncStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get syncStop;

  /// No description provided for @syncResumeButton.
  ///
  /// In en, this message translates to:
  /// **'Resume Sync'**
  String get syncResumeButton;

  /// No description provided for @syncSelectedFiles.
  ///
  /// In en, this message translates to:
  /// **'Selected files'**
  String get syncSelectedFiles;

  /// No description provided for @syncSelectedFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync only selected'**
  String get syncSelectedFilesSubtitle;

  /// No description provided for @syncSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} media selected'**
  String syncSelectedCount(int count);

  /// No description provided for @selectSyncFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Select files to sync'**
  String get selectSyncFilesTitle;

  /// No description provided for @selectSyncFilesDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get selectSyncFilesDone;

  /// No description provided for @selectSyncFilesPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'No access to gallery. Allow access in system settings.'**
  String get selectSyncFilesPermissionDenied;

  /// No description provided for @syncTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get syncTotal;

  /// No description provided for @uploadedLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploadedLabel;

  /// No description provided for @uploadPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadPageTitle;

  /// No description provided for @cancelledLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledLabel;

  /// No description provided for @fileTypes.
  ///
  /// In en, this message translates to:
  /// **'File types'**
  String get fileTypes;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @recentFiles.
  ///
  /// In en, this message translates to:
  /// **'Gallery files'**
  String get recentFiles;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @filesLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String filesLabel(String count);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action is irreversible.'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @storageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your storage usage and manage your plan.'**
  String get storageSubtitle;

  /// No description provided for @activeSubscriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Active subscription details'**
  String get activeSubscriptionDetails;

  /// No description provided for @planName.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get planName;

  /// No description provided for @storageLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage limit'**
  String get storageLimitLabel;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @planUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get planUsedLabel;

  /// No description provided for @subscriptionStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get subscriptionStartsAt;

  /// No description provided for @subscriptionEndsAt.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get subscriptionEndsAt;

  /// No description provided for @billingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get billingMonthly;

  /// No description provided for @billingYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get billingYearly;

  /// No description provided for @upgradeToPlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {name}'**
  String upgradeToPlan(String name);

  /// No description provided for @filesAlreadyInFolder.
  ///
  /// In en, this message translates to:
  /// **'Files are already in this folder'**
  String get filesAlreadyInFolder;

  /// No description provided for @folderEmpty.
  ///
  /// In en, this message translates to:
  /// **'Folder is empty'**
  String get folderEmpty;

  /// No description provided for @accessRevoked.
  ///
  /// In en, this message translates to:
  /// **'Access revoked'**
  String get accessRevoked;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @paymentAndSubscription.
  ///
  /// In en, this message translates to:
  /// **'Payment & Subscription'**
  String get paymentAndSubscription;

  /// No description provided for @cardDeleted.
  ///
  /// In en, this message translates to:
  /// **'Card deleted'**
  String get cardDeleted;

  /// No description provided for @cardSetAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Card set as default'**
  String get cardSetAsDefault;

  /// No description provided for @myCards.
  ///
  /// In en, this message translates to:
  /// **'My cards'**
  String get myCards;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get addCard;

  /// No description provided for @noCardsLinked.
  ///
  /// In en, this message translates to:
  /// **'No cards linked'**
  String get noCardsLinked;

  /// No description provided for @noSubscription.
  ///
  /// In en, this message translates to:
  /// **'No subscription'**
  String get noSubscription;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @changePlan.
  ///
  /// In en, this message translates to:
  /// **'Change plan'**
  String get changePlan;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose plan'**
  String get choosePlan;

  /// No description provided for @storageUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} used'**
  String storageUsed(String used);

  /// No description provided for @subscriptionUntil.
  ///
  /// In en, this message translates to:
  /// **'Until: {date}'**
  String subscriptionUntil(String date);

  /// No description provided for @cardStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get cardStatusActive;

  /// No description provided for @cardStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending confirmation'**
  String get cardStatusPending;

  /// No description provided for @cardStatusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get cardStatusBlocked;

  /// No description provided for @cardDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get cardDefaultLabel;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @deleteCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete card?'**
  String get deleteCardTitle;

  /// No description provided for @deleteCardMessage.
  ///
  /// In en, this message translates to:
  /// **'Card {number} will be deleted.'**
  String deleteCardMessage(String number);

  /// No description provided for @cardNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get cardNumberLabel;

  /// No description provided for @enterCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter card number'**
  String get enterCardNumber;

  /// No description provided for @cardNumber16Digits.
  ///
  /// In en, this message translates to:
  /// **'Card number must be 16 digits'**
  String get cardNumber16Digits;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiryDate;

  /// No description provided for @enterExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Enter expiry date'**
  String get enterExpiryDate;

  /// No description provided for @expiryDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Format: MM/YY'**
  String get expiryDateFormat;

  /// No description provided for @invalidMonth.
  ///
  /// In en, this message translates to:
  /// **'Invalid month'**
  String get invalidMonth;

  /// No description provided for @cardExpired.
  ///
  /// In en, this message translates to:
  /// **'Card has expired'**
  String get cardExpired;

  /// No description provided for @checkCardData.
  ///
  /// In en, this message translates to:
  /// **'You entered invalid data, please check'**
  String get checkCardData;

  /// No description provided for @validThruLabel.
  ///
  /// In en, this message translates to:
  /// **'VALID THRU'**
  String get validThruLabel;

  /// No description provided for @verifyCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Card verification'**
  String get verifyCardTitle;

  /// No description provided for @enterSmsCode.
  ///
  /// In en, this message translates to:
  /// **'Enter SMS code'**
  String get enterSmsCode;

  /// No description provided for @smsCodeSentFor.
  ///
  /// In en, this message translates to:
  /// **'Code sent to confirm card\n{number}'**
  String smsCodeSentFor(String number);

  /// No description provided for @cardAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Card added successfully'**
  String get cardAddedSuccess;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @plansTitle.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plansTitle;

  /// No description provided for @noPlans.
  ///
  /// In en, this message translates to:
  /// **'No plans available'**
  String get noPlans;

  /// No description provided for @confirmPurchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmPurchaseTitle;

  /// No description provided for @confirmPurchaseMessage.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to «{name}» for {price} UZS / {period}?'**
  String confirmPurchaseMessage(String name, String price, String period);

  /// No description provided for @updatePlan.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get updatePlan;

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeLabel;

  /// No description provided for @storageFeature.
  ///
  /// In en, this message translates to:
  /// **'{storage} Storage'**
  String storageFeature(String storage);

  /// No description provided for @dataPreservedNote.
  ///
  /// In en, this message translates to:
  /// **'Your data will be preserved when upgrading.'**
  String get dataPreservedNote;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @switchPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Switch to this plan'**
  String get switchPlanButton;

  /// No description provided for @addCardPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add a card to pay'**
  String get addCardPrompt;

  /// No description provided for @downgradeWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm plan change'**
  String get downgradeWarningTitle;

  /// No description provided for @downgradeWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'You are currently using {used}. The «{plan}» plan offers {limit}. After switching, syncing new files will pause until your storage is within the limit. Existing files will not be deleted.'**
  String downgradeWarningMessage(String used, String plan, String limit);

  /// No description provided for @continueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Switch anyway'**
  String get continueAnyway;

  /// No description provided for @staySamePlan.
  ///
  /// In en, this message translates to:
  /// **'Stay on current plan'**
  String get staySamePlan;

  /// No description provided for @popularBadge.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popularBadge;

  /// No description provided for @planPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get planPeriodMonthly;

  /// No description provided for @planPeriodYearly.
  ///
  /// In en, this message translates to:
  /// **'/yr'**
  String get planPeriodYearly;

  /// No description provided for @cardTypeUzcard.
  ///
  /// In en, this message translates to:
  /// **'Uzcard'**
  String get cardTypeUzcard;

  /// No description provided for @cardTypeHumo.
  ///
  /// In en, this message translates to:
  /// **'Humo'**
  String get cardTypeHumo;

  /// No description provided for @cardTypeVisa.
  ///
  /// In en, this message translates to:
  /// **'Visa'**
  String get cardTypeVisa;

  /// No description provided for @cardTypeMastercard.
  ///
  /// In en, this message translates to:
  /// **'Mastercard'**
  String get cardTypeMastercard;

  /// No description provided for @cardTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get cardTypeUnknown;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect phone number or password'**
  String get errorInvalidCredentials;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get errorUserNotFound;

  /// No description provided for @errorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get errorInvalidCode;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired, please try again'**
  String get errorSessionExpired;

  /// No description provided for @errorSessionExpiredRelogin.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again'**
  String get errorSessionExpiredRelogin;

  /// No description provided for @errorUserAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A user with this phone number already exists'**
  String get errorUserAlreadyExists;

  /// No description provided for @genericErrorFallback.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again later'**
  String get genericErrorFallback;

  /// No description provided for @planNameFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planNameFree;

  /// No description provided for @planNameStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get planNameStart;

  /// No description provided for @planNamePlus.
  ///
  /// In en, this message translates to:
  /// **'Plus'**
  String get planNamePlus;

  /// No description provided for @planNameFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get planNameFamily;

  /// No description provided for @planNamePro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get planNamePro;

  /// No description provided for @clearDoneButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearDoneButton;

  /// No description provided for @allUploadedStatus.
  ///
  /// In en, this message translates to:
  /// **'All uploaded!'**
  String get allUploadedStatus;

  /// No description provided for @noNetworkWaiting.
  ///
  /// In en, this message translates to:
  /// **'No network — waiting...'**
  String get noNetworkWaiting;

  /// No description provided for @uploadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading {current} of {total}...'**
  String uploadingProgress(int current, int total);

  /// No description provided for @tapToSelectFiles.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get tapToSelectFiles;

  /// No description provided for @photosAndVideosOnly.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos only'**
  String get photosAndVideosOnly;

  /// No description provided for @uploadingCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} uploading'**
  String uploadingCountBadge(int count);

  /// No description provided for @pausedCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} paused'**
  String pausedCountBadge(int count);

  /// No description provided for @doneCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} done'**
  String doneCountBadge(int count);

  /// No description provided for @addFilesButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addFilesButton;

  /// No description provided for @waitingForNetworkShort.
  ///
  /// In en, this message translates to:
  /// **'Waiting for network...'**
  String get waitingForNetworkShort;

  /// No description provided for @uploadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploadingEllipsis;

  /// No description provided for @selectPhotosVideos.
  ///
  /// In en, this message translates to:
  /// **'Select photos / videos'**
  String get selectPhotosVideos;

  /// No description provided for @uploadMoreButton.
  ///
  /// In en, this message translates to:
  /// **'Upload more'**
  String get uploadMoreButton;

  /// No description provided for @addMoreButton.
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get addMoreButton;

  /// No description provided for @pausedWillResumeAuto.
  ///
  /// In en, this message translates to:
  /// **'No network — will resume automatically'**
  String get pausedWillResumeAuto;

  /// No description provided for @shareButtonWithCount.
  ///
  /// In en, this message translates to:
  /// **'Share ({count})'**
  String shareButtonWithCount(int count);

  /// No description provided for @filesAndFoldersCount.
  ///
  /// In en, this message translates to:
  /// **'{files} files, {folders} folders'**
  String filesAndFoldersCount(int files, int folders);

  /// No description provided for @chooseFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get chooseFolderTitle;

  /// No description provided for @homeFolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeFolderLabel;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @repeatPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get repeatPasswordHint;

  /// No description provided for @removedFromFavourites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favourites'**
  String get removedFromFavourites;

  /// No description provided for @alreadyInFavourites.
  ///
  /// In en, this message translates to:
  /// **'Selected files are already in favourites'**
  String get alreadyInFavourites;

  /// No description provided for @cannotMoveIntoItself.
  ///
  /// In en, this message translates to:
  /// **'Can\'t move a folder into itself'**
  String get cannotMoveIntoItself;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number and we\'ll send you a code to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @sendOtpCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Send OTP Code'**
  String get sendOtpCodeButton;

  /// No description provided for @verifyOtpCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP Code'**
  String get verifyOtpCodeTitle;

  /// No description provided for @otpSentToPrefix.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to '**
  String get otpSentToPrefix;

  /// No description provided for @enterCompleteOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the complete 6-digit code'**
  String get enterCompleteOtpCode;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @resendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCodeButton;

  /// No description provided for @otpCodeResentMessage.
  ///
  /// In en, this message translates to:
  /// **'OTP code resent'**
  String get otpCodeResentMessage;

  /// No description provided for @setNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPasswordTitle;

  /// No description provided for @setNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password with at least 8 characters.'**
  String get setNewPasswordSubtitle;

  /// No description provided for @enterNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPasswordHint;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordButton;

  /// No description provided for @passwordResetSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully!'**
  String get passwordResetSuccessMessage;

  /// No description provided for @errorOtpStillValid.
  ///
  /// In en, this message translates to:
  /// **'Previous verification code is still valid. Please wait before requesting a new one.'**
  String get errorOtpStillValid;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to\nBulutcha'**
  String get loginWelcomeTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to access your secure files.'**
  String get loginSubtitle;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @enterYourPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPasswordHint;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccountPrompt;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLink;

  /// No description provided for @enterOtpCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP Code'**
  String get enterOtpCodeTitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsRead;

  /// No description provided for @deleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get deleteNotification;

  /// No description provided for @notificationDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this notification? This action is irreversible.'**
  String get notificationDeleteConfirmMessage;

  /// No description provided for @failedToLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedToLoadNotifications;

  /// No description provided for @allNotificationsMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get allNotificationsMarkedRead;

  /// No description provided for @notifTypeSubscriptionExpiryWarning.
  ///
  /// In en, this message translates to:
  /// **'Subscription expiring soon'**
  String get notifTypeSubscriptionExpiryWarning;

  /// No description provided for @notifTypeSubscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscription expired'**
  String get notifTypeSubscriptionExpired;

  /// No description provided for @notifTypeSubscriptionRenewed.
  ///
  /// In en, this message translates to:
  /// **'Subscription renewed'**
  String get notifTypeSubscriptionRenewed;

  /// No description provided for @notifTypeSubscriptionDowngraded.
  ///
  /// In en, this message translates to:
  /// **'Subscription downgraded'**
  String get notifTypeSubscriptionDowngraded;

  /// No description provided for @notifTypePaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get notifTypePaymentSuccess;

  /// No description provided for @notifTypePaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get notifTypePaymentFailed;

  /// No description provided for @notifTypeCardDeclined.
  ///
  /// In en, this message translates to:
  /// **'Card declined'**
  String get notifTypeCardDeclined;

  /// No description provided for @notifTypeFileShared.
  ///
  /// In en, this message translates to:
  /// **'A file was shared with you'**
  String get notifTypeFileShared;

  /// No description provided for @notifTypeFileShareRevoked.
  ///
  /// In en, this message translates to:
  /// **'File access revoked'**
  String get notifTypeFileShareRevoked;

  /// No description provided for @notifTypeShareRequestReceived.
  ///
  /// In en, this message translates to:
  /// **'New access request'**
  String get notifTypeShareRequestReceived;

  /// No description provided for @notifTypeShareRequestApproved.
  ///
  /// In en, this message translates to:
  /// **'Access request approved'**
  String get notifTypeShareRequestApproved;

  /// No description provided for @notifTypeShareRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Access request rejected'**
  String get notifTypeShareRequestRejected;

  /// No description provided for @notifTypeSystemAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'System announcement'**
  String get notifTypeSystemAnnouncement;

  /// No description provided for @notifTypeStorageWarning.
  ///
  /// In en, this message translates to:
  /// **'Storage running low'**
  String get notifTypeStorageWarning;

  /// No description provided for @notifTypeStorageFull.
  ///
  /// In en, this message translates to:
  /// **'Storage full'**
  String get notifTypeStorageFull;

  /// No description provided for @notifTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'New notification'**
  String get notifTypeUnknown;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
    case 'uz': return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
