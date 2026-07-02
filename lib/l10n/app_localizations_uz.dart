// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appName => 'Bulutcha';

  @override
  String get welcomeBack => 'Xush kelibsiz,';

  @override
  String get home => 'Bosh sahifa';

  @override
  String get files => 'Fayllar';

  @override
  String get shared => 'Ulashilgan';

  @override
  String get profile => 'Profil';

  @override
  String get recent => 'So\'nggi';

  @override
  String get myCloudStorage => 'Mening bulutim';

  @override
  String get yourCloudStorage => 'Bulut xotirangiz';

  @override
  String get used => 'ishlatilgan';

  @override
  String get total => 'jami';

  @override
  String get quickActions => 'Tezkor amallar';

  @override
  String get myFiles => 'Mening fayllarim';

  @override
  String get favourites => 'Sevimlilar';

  @override
  String get overallStats => 'Umumiy statistika';

  @override
  String get images => 'Rasmlar';

  @override
  String get videos => 'Videolar';

  @override
  String get sharedByMe => 'Men ulashganlar';

  @override
  String get sharedWithMe => 'Menga ulashilgan';

  @override
  String get participants => 'ishtirokchi';

  @override
  String get folders => 'Papkalar';

  @override
  String get folder => 'Papka';

  @override
  String get createFolder => 'Papka yaratish';

  @override
  String get newFolder => 'Yangi papka';

  @override
  String get folderName => 'Papka nomi';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get create => 'Yaratish';

  @override
  String get save => 'Saqlash';

  @override
  String get delete => 'O\'chirish';

  @override
  String get rename => 'Nomini o\'zgartirish';

  @override
  String get move => 'Ko\'chirish';

  @override
  String get download => 'Yuklab olish';

  @override
  String get share => 'Ulashish';

  @override
  String get preview => 'Ko\'rib chiqish';

  @override
  String get details => 'Batafsil';

  @override
  String get open => 'Ochish';

  @override
  String get addToFavourites => 'Sevimlilarga qo\'shish';

  @override
  String get removeFromFavourites => 'Sevimlilardan olib tashlash';

  @override
  String get deleteConfirm => 'O\'chirilsinmi?';

  @override
  String deleteConfirmMessage(String name) {
    return '\"$name\" ni o\'chirishni xohlaysizmi?\nBu amalni qaytarib bo\'lmaydi.';
  }

  @override
  String get successfullyMoved => 'Muvaffaqiyatli ko\'chirildi';

  @override
  String fileSaved(String name) {
    return 'Fayl saqlandi: $name';
  }

  @override
  String get emptyFolder => 'Hozircha bo\'sh';

  @override
  String get emptyFolderSubtitle => 'Papka yarating yoki rasm/video yuklang';

  @override
  String get noFavourites => 'Sevimli fayllar yo\'q';

  @override
  String get noFavouritesSubtitle => 'Qo\'shish uchun fayl ustidagi yulduzni bosing';

  @override
  String get filter => 'Filtr';

  @override
  String get all => 'Barchasi';

  @override
  String get photos => 'Rasmlar';

  @override
  String get pinnedFolders => 'Mahkamlangan papkalar';

  @override
  String get maxPinnedFolders => 'Maksimal 5 ta mahkamlangan papka';

  @override
  String get alreadyPinned => 'Papka allaqachon mahkamlangan';

  @override
  String get pin => 'Mahkamlash';

  @override
  String get unpin => 'Mahkamni olib tashlash';

  @override
  String get unpinFolder => 'Papkani olib tashlash?';

  @override
  String get shareViaLink => 'Havola orqali ulashish';

  @override
  String get shareByPhone => 'Telefon orqali';

  @override
  String get shareByLink => 'Havola orqali';

  @override
  String get linkName => 'Havola nomi';

  @override
  String get generate => 'Yaratish';

  @override
  String get generatedLink => 'Yaratilgan havola';

  @override
  String get linkCopied => 'Havola nusxalandi';

  @override
  String get copy => 'Nusxalash';

  @override
  String get copyLink => 'Havolani nusxalash';

  @override
  String get shareSuccess => 'Muvaffaqiyatli ulashildi';

  @override
  String get addAtLeastOnePhone => 'Kamida bitta telefon raqam qo\'shing';

  @override
  String get enter9Digits => '9 ta raqam kiriting';

  @override
  String get enterLinkName => 'Havola nomini kiriting';

  @override
  String get fileDetails => 'Fayl ma\'lumotlari';

  @override
  String get folderDetails => 'Papka ma\'lumotlari';

  @override
  String get fileName => 'Nomi';

  @override
  String get fileSize => 'Hajmi';

  @override
  String get createdAt => 'Yaratilgan vaqt';

  @override
  String get capturedAt => 'Suratga olingan vaqt';

  @override
  String get totalSize => 'Umumiy hajm';

  @override
  String get fileCount => 'Fayllar';

  @override
  String get folderCount => 'Papkalar';

  @override
  String get shareRequests => 'Ulashish so\'rovlari';

  @override
  String get shareRequestsSubtitle => 'Havolalar va ruxsatlarni boshqarish';

  @override
  String get shareRequestDetails => 'Ulashish so\'rovi tafsilotlari';

  @override
  String get request => 'So\'rov';

  @override
  String get linkNameLabel => 'HAVOLA NOMI';

  @override
  String get shareLinkLabel => 'ULASHISH HAVOLASI';

  @override
  String get permissionRequests => 'RUXSAT SO\'ROVLARI';

  @override
  String get pending => 'Kutilmoqda';

  @override
  String get approved => 'Tasdiqlangan';

  @override
  String get rejected => 'Rad etilgan';

  @override
  String get review => 'Ko\'rib chiqish';

  @override
  String get reviewAccessRequest => 'Ruxsat so\'rovini ko\'rib chiqish';

  @override
  String get reviewAccessRequestSubtitle => 'Bu foydalanuvchi ulashilgan kontentga kirish huquqiga ega bo\'lishi kerakmi?';

  @override
  String get reject => 'Rad etish';

  @override
  String get approve => 'Tasdiqlash';

  @override
  String get accessApproved => 'Ruxsat berildi';

  @override
  String get accessRejected => 'Ruxsat rad etildi';

  @override
  String get noShareRequests => 'Ulashish so\'rovlari yo\'q';

  @override
  String get noShareRequestsSubtitle => 'Fayllarni havola orqali ulashing va ular bu yerda paydo bo\'ladi';

  @override
  String get personalData => 'SHAXSIY MA\'LUMOTLAR';

  @override
  String get changeName => 'Ismni o\'zgartirish';

  @override
  String get changePhone => 'Telefon raqamini o\'zgartirish';

  @override
  String get changePassword => 'Parolni o\'zgartirish';

  @override
  String get newName => 'Yangi ism';

  @override
  String get newPhone => 'Yangi raqam';

  @override
  String get oldPassword => 'Eski parol';

  @override
  String get newPassword => 'Yangi parol';

  @override
  String get confirmPassword => 'Parolni tasdiqlash';

  @override
  String get passwordsDoNotMatch => 'Parollar mos kelmaydi';

  @override
  String get passwordTooShort => 'Kamida 8 ta belgi';

  @override
  String get nameUpdated => 'Ism yangilandi';

  @override
  String get phoneUpdated => 'Telefon yangilandi';

  @override
  String get passwordChanged => 'Parol o\'zgartirildi';

  @override
  String get avatarUpdated => 'Avatar yangilandi';

  @override
  String get storage => 'Xotira';

  @override
  String get language => 'Til';

  @override
  String get theme => 'KO\'RINISH';

  @override
  String get light => 'Yorug\'';

  @override
  String get dark => 'Qorong\'u';

  @override
  String get logout => 'Hisobdan chiqish';

  @override
  String get logoutConfirm => 'Chiqish';

  @override
  String get logoutConfirmMessage => 'Hisobdan chiqishni xohlaysizmi?';

  @override
  String get refresh => 'Yangilash';

  @override
  String get retry => 'Qayta urinish';

  @override
  String selected(int count) {
    return 'Tanlangan: $count';
  }

  @override
  String get selectAll => 'Barchasi';

  @override
  String get deselectAll => 'Barchasini bekor qilish';

  @override
  String get uploadFiles => 'Fayllarni yuklash';

  @override
  String get chooseLanguage => 'Tilni tanlang';

  @override
  String get home_breadcrumb => 'Bosh sahifa';

  @override
  String get favourites_breadcrumb => 'Sevimlilar';

  @override
  String selectedCount(int count) {
    return 'Tanlangan: $count';
  }

  @override
  String get addedToFavourites => 'Sevimlilarga qo\'shildi';

  @override
  String get couldNotOpenImage => 'Rasmni ochib bo\'lmadi';

  @override
  String get couldNotOpenVideo => 'Videoni ochib bo\'lmadi';

  @override
  String get noSharedWithMe => 'Hech kim fayl ulashmagan';

  @override
  String get noSharedWithMeSubtitle => 'Kimdir fayl ulashsa — bu yerda ko\'rinadi';

  @override
  String get noSharedByMe => 'Siz hali hech kim bilan ulashmadingiz';

  @override
  String get noSharedByMeSubtitle => 'Fayllarni ulashish uchun ulashish tugmasini bosing';

  @override
  String get noSharedItems => 'Ulashilgan elementlar yo\'q';

  @override
  String sharedWithLabel(String name) {
    return '$name uchun';
  }

  @override
  String get revokeAccess => 'Ruxsatni bekor qilish';

  @override
  String revokeAccessConfirm(String name) {
    return '\"$name\" ga ruxsatni bekor qilasizmi?';
  }

  @override
  String get revoke => 'Bekor qilish';

  @override
  String filesCount(int count) {
    return '$count fayl';
  }

  @override
  String get openLabel => 'Ochish';

  @override
  String get usersTab => 'Foydalanuvchilar';

  @override
  String get sharedItemsTab => 'Ulashilgan elementlar';

  @override
  String get newNameHint => 'Yangi nom';

  @override
  String deleteItems(int count) {
    return '$count ta element';
  }

  @override
  String get pinLabel => '📌 Mahkamlash';

  @override
  String get unpinLabel => '📌 Olib tashlash';

  @override
  String get favourite => 'Sevimli';

  @override
  String get syncFolderName => '📱 Sinxronizatsiya';

  @override
  String syncStatusUploading(int uploaded, int total) {
    return '$uploaded/$total yuklandi';
  }

  @override
  String syncStatusWaiting(int count) {
    return 'Sinxronizatsiya kutilmoqda: $count';
  }

  @override
  String get syncStatusComplete => 'Sinxronizatsiya tugallandi';

  @override
  String syncStatusErrors(int count) {
    return '$count ta xato';
  }

  @override
  String get syncSettingsTitle => 'Avto-sinxronizatsiya';

  @override
  String get syncEnableToggle => 'Avto-sinxronizatsiyani yoqish';

  @override
  String get syncWifiOnly => 'Faqat Wi-Fi orqali';

  @override
  String get syncNowButton => 'Hozir sinxronlash';

  @override
  String get syncResetButton => 'Navbatni tozalash';

  @override
  String get syncFolderReadOnly => 'Bu sizning Sinxronizatsiya papkangiz. Bu yerdagi fayllar avtomatik boshqariladi.';

  @override
  String get syncResetConfirmTitle => 'Navbatni tozalash?';

  @override
  String get syncResetConfirmMessage => 'Barcha yozuvlar o\'chiriladi. Keyin ilova galereyani qayta skanerlaydi.';

  @override
  String get syncResetConfirmButton => 'Tozalash';

  @override
  String get syncAutoUpload => 'Foto va videolarni avtomatik yuklash';

  @override
  String get syncNoMobileData => 'Mobil internet orqali sinxronlamaslik';

  @override
  String get syncStatusTitle => 'Sinxronizatsiya holati';

  @override
  String get syncStatusPending => 'Kutilmoqda';

  @override
  String get syncStatusUploading2 => 'Yuklanmoqda';

  @override
  String get syncStatusDone => 'Tayyor';

  @override
  String get syncStatusFailed => 'Xatolar';

  @override
  String get syncStop => 'To\'xtatish';

  @override
  String get syncResumeButton => 'Sinxronizatsiyani davom ettirish';

  @override
  String get syncSelectedFiles => 'Tanlangan fayllar';

  @override
  String get syncSelectedFilesSubtitle => 'Faqat tanlanganlarni sinxronlashtirish';

  @override
  String get syncTotal => 'Jami';

  @override
  String get uploadedLabel => 'Yuklandi';

  @override
  String get uploadPageTitle => 'Yuklash';

  @override
  String get cancelledLabel => 'Bekor qilindi';

  @override
  String get fileTypes => 'Fayl turlari';

  @override
  String get viewAll => 'Barchasi';

  @override
  String get recentFiles => 'Galereya fayllari';

  @override
  String get sync => 'Sinxr.';

  @override
  String get image => 'Rasm';

  @override
  String get video => 'Video';

  @override
  String filesLabel(String count) {
    return '$count fayllar';
  }

  @override
  String get today => 'Bugun';

  @override
  String get yesterday => 'Kecha';

  @override
  String daysAgo(int count) {
    return '$count kun oldin';
  }

  @override
  String get deleteAccount => 'Hisobni o\'chirish';

  @override
  String get deleteAccountConfirm => 'Hisobni o\'chirish';

  @override
  String get deleteAccountConfirmMessage => 'Hisobingizni o\'chirishni xohlaysizmi? Bu amalni qaytarib bo\'lmaydi.';

  // ── Payment ──────────────────────────────────────────────────────────────

  @override
  String get paymentAndSubscription => 'To\'lov va obuna';

  @override
  String get cardDeleted => 'Karta o\'chirildi';

  @override
  String get cardSetAsDefault => 'Karta standart qilib belgilandi';

  @override
  String get myCards => 'Mening kartalarim';

  @override
  String get addCard => 'Karta qo\'shish';

  @override
  String get noCardsLinked => 'Kartalar biriktirilmagan';

  @override
  String get noSubscription => 'Obuna yo\'q';

  @override
  String get currentPlan => 'Joriy tarif';

  @override
  String get changePlan => 'Tarifni o\'zgartirish';

  @override
  String get choosePlan => 'Tarif tanlash';

  @override
  String storageUsed(String used) => '$used ishlatilgan';

  @override
  String subscriptionUntil(String date) => 'Gacha: $date';

  @override
  String get cardStatusActive => 'Faol';

  @override
  String get cardStatusPending => 'Tasdiqlanishi kutilmoqda';

  @override
  String get cardStatusBlocked => 'Bloklangan';

  @override
  String get cardDefaultLabel => 'Standart';

  @override
  String get setAsDefault => 'Standart qilish';

  @override
  String get deleteCardTitle => 'Kartani o\'chirish?';

  @override
  String deleteCardMessage(String number) => '$number kartasi o\'chiriladi.';

  @override
  String get cardNumberLabel => 'Karta raqami';

  @override
  String get enterCardNumber => 'Karta raqamini kiriting';

  @override
  String get cardNumber16Digits => 'Karta raqami — 16 ta raqam';

  @override
  String get expiryDate => 'Amal qilish muddati';

  @override
  String get enterExpiryDate => 'Amal qilish muddatini kiriting';

  @override
  String get expiryDateFormat => 'Format: MM/YY';

  @override
  String get invalidMonth => 'Noto\'g\'ri oy';

  @override
  String get validThruLabel => 'AMAL QILISH MUDDATI';

  @override
  String get verifyCardTitle => 'Kartani tasdiqlash';

  @override
  String get enterSmsCode => 'SMS kodni kiriting';

  @override
  String smsCodeSentFor(String number) =>
      '$number kartasini tasdiqlash uchun kod yuborildi';

  @override
  String get cardAddedSuccess => 'Karta muvaffaqiyatli qo\'shildi';

  @override
  String get confirmButton => 'Tasdiqlash';

  @override
  String get plansTitle => 'Tariflar';

  @override
  String get noPlans => 'Tariflar mavjud emas';

  @override
  String get confirmPurchaseTitle => 'Tasdiqlash';

  @override
  String confirmPurchaseMessage(String name, String price, String period) =>
      '«$name» tarifini $price UZS / $period ga ulashni istaysizmi?';

  @override
  String get updatePlan => 'Ulash';

  @override
  String get freeLabel => 'Bepul';

  @override
  String storageFeature(String storage) => '$storage Xotira';

  @override
  String get dataPreservedNote =>
      'Tarif yangilanishida ma\'lumotlaringiz saqlanib qoladi.';

  @override
  String get unknownError => 'Noma\'lum xato';

  @override
  String get storageSubtitle => 'Xotira foydalanishini kuzating va tarifingizni boshqaring.';

  @override
  String get activeSubscriptionDetails => 'Faol obuna tafsilotlari';

  @override
  String get planName => 'Tarif nomi';

  @override
  String get storageLimitLabel => 'Xotira limiti';

  @override
  String get available => 'Mavjud';

  @override
  String get billingMonthly => 'Oylik';

  @override
  String get billingYearly => 'Yillik';

  @override
  String upgradeToPlan(String name) => '$name ga o\'tish';
}
