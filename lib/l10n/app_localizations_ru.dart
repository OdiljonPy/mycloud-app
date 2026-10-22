// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Bulutcha';

  @override
  String get welcomeBack => 'С возвращением,';

  @override
  String get home => 'Главная';

  @override
  String get files => 'Файлы';

  @override
  String get shared => 'Общие';

  @override
  String get profile => 'Профиль';

  @override
  String get recent => 'Недавние';

  @override
  String get myCloudStorage => 'Моё облако';

  @override
  String get yourCloudStorage => 'Ваше облачное хранилище';

  @override
  String get used => 'использовано';

  @override
  String get total => 'всего';

  @override
  String get quickActions => 'Быстрые действия';

  @override
  String get myFiles => 'Мои файлы';

  @override
  String get favourites => 'Избранное';

  @override
  String get overallStats => 'Общая статистика';

  @override
  String get images => 'Изображения';

  @override
  String get videos => 'Видео';

  @override
  String get sharedByMe => 'Поделился я';

  @override
  String get sharedWithMe => 'Со мной';

  @override
  String get participants => 'участн.';

  @override
  String get folders => 'Папки';

  @override
  String get folder => 'Папка';

  @override
  String get createFolder => 'Создать папку';

  @override
  String get newFolder => 'Новая папка';

  @override
  String get folderName => 'Название папки';

  @override
  String get cancel => 'Отмена';

  @override
  String get create => 'Создать';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get rename => 'Переименовать';

  @override
  String get move => 'Переместить';

  @override
  String get download => 'Скачать';

  @override
  String get share => 'Поделиться';

  @override
  String get preview => 'Предпросмотр';

  @override
  String get details => 'Посмотреть детали';

  @override
  String get open => 'Открыть';

  @override
  String get addToFavourites => 'В избранное';

  @override
  String get removeFromFavourites => 'Убрать из избранного';

  @override
  String get deleteConfirm => 'Удалить?';

  @override
  String deleteConfirmMessage(String name) {
    return 'Вы уверены, что хотите удалить «$name»?\nЭто действие необратимо.';
  }

  @override
  String get successfullyMoved => 'Успешно перемещено';

  @override
  String fileSaved(String name) {
    return 'Файл сохранён: $name';
  }

  @override
  String get emptyFolder => 'Здесь пока пусто';

  @override
  String get emptyFolderSubtitle => 'Создайте папку или загрузите фото / видео';

  @override
  String get noFavourites => 'Нет избранных файлов';

  @override
  String get noFavouritesSubtitle => 'Нажмите звезду на файле чтобы добавить';

  @override
  String get filter => 'Фильтр';

  @override
  String get all => 'Все';

  @override
  String get photos => 'Фото';

  @override
  String get pinnedFolders => 'Закреплённые папки';

  @override
  String get maxPinnedFolders => 'Максимум 5 закреплённых папок';

  @override
  String get alreadyPinned => 'Папка уже закреплена';

  @override
  String get pin => 'Закрепить';

  @override
  String get unpin => 'Открепить';

  @override
  String get unpinFolder => 'Открепить папку?';

  @override
  String get shareViaLink => 'Поделиться по ссылке';

  @override
  String get shareByPhone => 'По номеру';

  @override
  String get shareByLink => 'По ссылке';

  @override
  String get linkName => 'Название ссылки';

  @override
  String get generate => 'Создать';

  @override
  String get generatedLink => 'Созданная ссылка';

  @override
  String get linkCopied => 'Ссылка скопирована';

  @override
  String get copy => 'Скопировать';

  @override
  String get copyLink => 'Скопировать ссылку';

  @override
  String get shareSuccess => 'Поделились успешно';

  @override
  String get addAtLeastOnePhone => 'Добавьте хотя бы один номер телефона';

  @override
  String get enter9Digits => 'Введите 9 цифр номера';

  @override
  String get enterLinkName => 'Введите название ссылки';

  @override
  String get fileDetails => 'Сведения о файле';

  @override
  String get folderDetails => 'Сведения о папке';

  @override
  String get fileName => 'Название';

  @override
  String get fileSize => 'Размер';

  @override
  String get createdAt => 'Дата создания';

  @override
  String get capturedAt => 'Снято в';

  @override
  String get totalSize => 'Общий размер';

  @override
  String get fileCount => 'Файлы';

  @override
  String get folderCount => 'Папки';

  @override
  String get shareRequests => 'Запросы доступа';

  @override
  String get shareRequestsSubtitle => 'Управление ссылками и доступами';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get shareRequestDetails => 'Детали запроса';

  @override
  String get request => 'Запрос';

  @override
  String get linkNameLabel => 'НАЗВАНИЕ ССЫЛКИ';

  @override
  String get shareLinkLabel => 'ССЫЛКА';

  @override
  String get permissionRequests => 'ЗАПРОСЫ ДОСТУПА';

  @override
  String get pending => 'Ожидание';

  @override
  String get approved => 'Одобрено';

  @override
  String get rejected => 'Отклонено';

  @override
  String get review => 'Рассмотреть';

  @override
  String get reviewAccessRequest => 'Рассмотреть запрос доступа';

  @override
  String get reviewAccessRequestSubtitle => 'Выберите, следует ли предоставить доступ этому пользователю.';

  @override
  String get reject => 'Отклонить';

  @override
  String get approve => 'Одобрить';

  @override
  String get accessApproved => 'Доступ одобрен';

  @override
  String get accessRejected => 'Доступ отклонён';

  @override
  String get noShareRequests => 'Нет запросов на доступ';

  @override
  String get noShareRequestsSubtitle => 'Поделитесь файлами по ссылке и они появятся здесь';

  @override
  String get personalData => 'ЛИЧНЫЕ ДАННЫЕ';

  @override
  String get changeName => 'Изменить имя';

  @override
  String get changePhone => 'Изменить телефон';

  @override
  String get changePassword => 'Изменить пароль';

  @override
  String get newName => 'Новое имя';

  @override
  String get newPhone => 'Новый номер';

  @override
  String get oldPassword => 'Старый пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get confirmPassword => 'Подтвердить пароль';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get passwordTooShort => 'Минимум 8 символов';

  @override
  String get nameUpdated => 'Имя обновлено';

  @override
  String get phoneUpdated => 'Телефон обновлён';

  @override
  String get passwordChanged => 'Пароль изменён';

  @override
  String get avatarUpdated => 'Аватар обновлён';

  @override
  String get storage => 'Хранилище';

  @override
  String get language => 'Язык';

  @override
  String get theme => 'ОФОРМЛЕНИЕ';

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Тёмная';

  @override
  String get logout => 'Выйти из аккаунта';

  @override
  String get logoutConfirm => 'Выход';

  @override
  String get logoutConfirmMessage => 'Вы уверены, что хотите выйти из аккаунта?';

  @override
  String get refresh => 'Обновить';

  @override
  String get retry => 'Повторить';

  @override
  String selected(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get selectAll => 'Все';

  @override
  String get deselectAll => 'Снять все';

  @override
  String get uploadFiles => 'Загрузить файлы';

  @override
  String get chooseLanguage => 'Выберите язык';

  @override
  String get home_breadcrumb => 'Главная';

  @override
  String get favourites_breadcrumb => 'Избранное';

  @override
  String selectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get addedToFavourites => 'Добавлено в избранное';

  @override
  String get favouriteUpdateFailed => 'Не удалось обновить избранное';

  @override
  String get unitBytes => 'байт';

  @override
  String get unitKb => 'КБ';

  @override
  String get unitMb => 'МБ';

  @override
  String get unitGb => 'ГБ';

  @override
  String get unitTb => 'ТБ';

  @override
  String storageUsedOfLimit(String used, String limit) {
    return '$used использовано из $limit';
  }

  @override
  String get couldNotOpenImage => 'Не удалось открыть изображение';

  @override
  String get couldNotOpenVideo => 'Не удалось открыть видео';

  @override
  String get videoFormatNotSupported => 'Формат видео не поддерживается для просмотра';

  @override
  String get noSharedWithMe => 'Никто не делился файлами';

  @override
  String get noSharedWithMeSubtitle => 'Когда кто-то поделится файлом — они появятся здесь';

  @override
  String get noSharedByMe => 'Вы ещё ни с кем не делились';

  @override
  String get noSharedByMeSubtitle => 'Нажмите кнопку шаринга чтобы поделиться файлами';

  @override
  String get noSharedItems => 'Нет расшаренных элементов';

  @override
  String sharedWithLabel(String name) {
    return 'Для $name';
  }

  @override
  String get revokeAccess => 'Отозвать доступ';

  @override
  String revokeAccessConfirm(String name) {
    return 'Отозвать доступ к «$name»?';
  }

  @override
  String get revoke => 'Отозвать';

  @override
  String filesCount(int count) {
    return '$count файлов';
  }

  @override
  String get openLabel => 'Открыть';

  @override
  String get usersTab => 'Пользователи';

  @override
  String get sharedItemsTab => 'Расшаренные';

  @override
  String get newNameHint => 'Новое название';

  @override
  String deleteItems(int count) {
    return '$count элементов';
  }

  @override
  String get pinLabel => '📌 Закрепить';

  @override
  String get unpinLabel => '📌 Открепить';

  @override
  String get favourite => 'Избранное';

  @override
  String get syncFolderName => '📱 Синхронизация';

  @override
  String syncStatusUploading(int uploaded, int total) {
    return 'Загружено $uploaded из $total';
  }

  @override
  String syncStatusWaiting(int count) {
    return 'Ожидание синхронизации: $count';
  }

  @override
  String get syncStatusComplete => 'Синхронизация завершена';

  @override
  String syncStatusErrors(int count) {
    return 'Ошибок: $count';
  }

  @override
  String get syncSettingsTitle => 'Авто-синхронизация';

  @override
  String get syncEnableToggle => 'Включить авто-синхронизацию';

  @override
  String get syncWifiOnly => 'Только по Wi-Fi';

  @override
  String get syncNowButton => 'Синхронизировать сейчас';

  @override
  String get syncResetButton => 'Сбросить очередь';

  @override
  String get syncFolderReadOnly => 'Это папка синхронизации. Файлы здесь управляются автоматически.';

  @override
  String get syncResetConfirmTitle => 'Сбросить очередь?';

  @override
  String get syncResetConfirmMessage => 'Все записи будут удалены. После этого приложение заново просканирует галерею.';

  @override
  String get syncResetConfirmButton => 'Сбросить';

  @override
  String get syncAutoUpload => 'Автоматически загружать фото и видео';

  @override
  String get syncNoMobileData => 'Не синхронизировать через мобильные данные';

  @override
  String get syncStatusTitle => 'Статус синхронизации';

  @override
  String get syncStatusPending => 'Ожидание';

  @override
  String get syncStatusUploading2 => 'Загрузка';

  @override
  String get syncStatusDone => 'Готово';

  @override
  String get syncStatusFailed => 'Ошибки';

  @override
  String get syncStop => 'Остановить';

  @override
  String get syncResumeButton => 'Продолжить синк';

  @override
  String get syncBubbleTitle => 'Загрузка файлов';

  @override
  String syncBubbleSummary(int active, int queued, int done) {
    return '$active активно · $queued в очереди · $done готово';
  }

  @override
  String get syncPausedDuringUpload => 'Синк на паузе во время загрузки — продолжится автоматически';

  @override
  String syncQueueFraction(int count, int total) {
    return '$count / $total файлов';
  }

  @override
  String syncFailedCount(int count) {
    return '$count с ошибкой';
  }

  @override
  String get syncQueueItemPending => 'В очереди';

  @override
  String get syncQueueItemPaused => 'На паузе';

  @override
  String get syncQueueItemCancelled => 'Отменено';

  @override
  String get syncPauseAllButton => 'Пауза всех';

  @override
  String get syncResumeAllButton => 'Продолжить все';

  @override
  String get syncCancelAllButton => 'Отменить все';

  @override
  String get syncCancelAllConfirmTitle => 'Отменить все?';

  @override
  String syncCancelAllConfirmMessage(int count) {
    return '$count файлов будет удалено из очереди синка. Сами файлы на телефоне останутся.';
  }

  @override
  String get syncCancelAllConfirmButton => 'Да, отменить все';

  @override
  String syncQueueShowingPartial(int shown, int total) {
    return 'Показано $shown из $total';
  }

  @override
  String get syncSelectedFiles => 'Выбранные файлы';

  @override
  String get syncSelectedFilesSubtitle => 'Синхронизировать только выбранные';

  @override
  String syncSelectedCount(int count) {
    return '$count медиа выбрано';
  }

  @override
  String get selectSyncFilesTitle => 'Выбор файлов для синхронизации';

  @override
  String get selectSyncFilesDone => 'Готово';

  @override
  String get selectSyncFilesPermissionDenied => 'Нет доступа к галерее. Разрешите доступ в настройках устройства.';

  @override
  String get syncTotal => 'Всего';

  @override
  String get uploadedLabel => 'Загружено';

  @override
  String get uploadPageTitle => 'Загрузка';

  @override
  String get cancelledLabel => 'Отменено';

  @override
  String get fileTypes => 'Типы файлов';

  @override
  String get viewAll => 'Все';

  @override
  String get recentFiles => 'Файлы галереи';

  @override
  String get sync => 'Синхр.';

  @override
  String get image => 'Изображение';

  @override
  String get video => 'Видео';

  @override
  String filesLabel(String count) {
    return '$count файлов';
  }

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String daysAgo(int count) {
    return '$count дней назад';
  }

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountConfirm => 'Удалить аккаунт';

  @override
  String get deleteAccountConfirmMessage => 'Вы уверены, что хотите удалить аккаунт? Это действие необратимо.';

  @override
  String get storageSubtitle => 'Отслеживайте использование хранилища и управляйте тарифом.';

  @override
  String get activeSubscriptionDetails => 'Детали вашей активной подписки';

  @override
  String get planName => 'Название тарифа';

  @override
  String get storageLimitLabel => 'Лимит хранилища';

  @override
  String get available => 'Доступно';

  @override
  String get planUsedLabel => 'Использовано';

  @override
  String get subscriptionStartsAt => 'Дата начала';

  @override
  String get subscriptionEndsAt => 'Дата окончания';

  @override
  String get billingMonthly => 'Ежемесячно';

  @override
  String get billingYearly => 'Ежегодно';

  @override
  String upgradeToPlan(String name) {
    return 'Улучшить до $name';
  }

  @override
  String get filesAlreadyInFolder => 'Файлы уже находятся в этой папке';

  @override
  String get folderEmpty => 'Папка пуста';

  @override
  String get accessRevoked => 'Доступ отозван';

  @override
  String get userNotFound => 'Пользователь не найден';

  @override
  String get paymentAndSubscription => 'Подписка и оплата';

  @override
  String get cardDeleted => 'Карта удалена';

  @override
  String get cardSetAsDefault => 'Карта установлена по умолчанию';

  @override
  String get myCards => 'Мои карты';

  @override
  String get addCard => 'Добавить карту';

  @override
  String get noCardsLinked => 'Карты не привязаны';

  @override
  String get noSubscription => 'Без подписки';

  @override
  String get currentPlan => 'Текущий тариф';

  @override
  String get changePlan => 'Изменить тариф';

  @override
  String get choosePlan => 'Выбрать тариф';

  @override
  String storageUsed(String used) {
    return '$used использовано';
  }

  @override
  String subscriptionUntil(String date) {
    return 'До: $date';
  }

  @override
  String get cardStatusActive => 'Активна';

  @override
  String get cardStatusPending => 'Ожидает подтверждения';

  @override
  String get cardStatusBlocked => 'Заблокирована';

  @override
  String get cardDefaultLabel => 'По умолчанию';

  @override
  String get setAsDefault => 'По умолчанию';

  @override
  String get deleteCardTitle => 'Удалить карту?';

  @override
  String deleteCardMessage(String number) {
    return 'Карта $number будет удалена.';
  }

  @override
  String get cardNumberLabel => 'Номер карты';

  @override
  String get enterCardNumber => 'Введите номер карты';

  @override
  String get cardNumber16Digits => 'Номер карты — 16 цифр';

  @override
  String get expiryDate => 'Срок действия';

  @override
  String get enterExpiryDate => 'Введите срок действия';

  @override
  String get expiryDateFormat => 'Формат: MM/YY';

  @override
  String get invalidMonth => 'Неверный месяц';

  @override
  String get cardExpired => 'Срок действия карты истёк';

  @override
  String get checkCardData => 'Вы неверно ввели данные, пожалуйста проверьте';

  @override
  String get validThruLabel => 'ДЕЙСТВУЕТ ДО';

  @override
  String get verifyCardTitle => 'Подтверждение карты';

  @override
  String get enterSmsCode => 'Введите SMS-код';

  @override
  String smsCodeSentFor(String number) {
    return 'Код отправлен для подтверждения карты\n$number';
  }

  @override
  String get cardAddedSuccess => 'Карта успешно добавлена';

  @override
  String get cardAlreadyExists => 'Эта карта уже добавлена.';

  @override
  String get cardTokenError => 'Не удалось добавить карту. Попробуйте ещё раз.';

  @override
  String get paymentGatewayUnavailable => 'Платёжный сервис временно недоступен. Попробуйте позже.';

  @override
  String get cardVerificationExpired => 'Сессия подтверждения карты истекла. Добавьте карту заново.';

  @override
  String get invalidVerificationCode => 'Неверный код подтверждения.';

  @override
  String get confirmButton => 'Подтвердить';

  @override
  String get plansTitle => 'Тарифы';

  @override
  String get noPlans => 'Нет тарифов';

  @override
  String get confirmPurchaseTitle => 'Подтверждение';

  @override
  String confirmPurchaseMessage(String name, String price, String period) {
    return 'Подключить тариф «$name» за $price UZS / $period?';
  }

  @override
  String get confirmFreePlanTitle => 'Вернуться на бесплатный тариф?';

  @override
  String confirmFreePlanMessage(String name) {
    return 'Вы перейдёте на тариф «$name». Продолжить?';
  }

  @override
  String get updatePlan => 'Обновить';

  @override
  String get freeLabel => 'Бесплатно';

  @override
  String storageFeature(String storage) {
    return '$storage Памяти';
  }

  @override
  String get dataPreservedNote => 'Ваши данные сохранятся при обновлении тарифа.';

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get switchPlanButton => 'Перейти на этот план';

  @override
  String get addCardPrompt => 'Добавьте карту для оплаты';

  @override
  String get downgradeWarningTitle => 'Подтвердите переход на другой тариф';

  @override
  String downgradeWarningMessage(String used, String plan, String limit) {
    return 'Сейчас используется $used из доступных. На плане «$plan» доступно $limit. После перехода синхронизация новых файлов остановится, пока хранилище не будет в пределах лимита. Существующие файлы не будут удалены.';
  }

  @override
  String get continueAnyway => 'Всё равно перейти';

  @override
  String get staySamePlan => 'Остаться на текущем плане';

  @override
  String get popularBadge => 'Популярный';

  @override
  String get planPeriodMonthly => '/мес';

  @override
  String get planPeriodYearly => '/год';

  @override
  String get cardTypeUzcard => 'Uzcard';

  @override
  String get cardTypeHumo => 'Humo';

  @override
  String get cardTypeVisa => 'Visa';

  @override
  String get cardTypeMastercard => 'Mastercard';

  @override
  String get cardTypeUnknown => 'Карта';

  @override
  String get errorInvalidCredentials => 'Неверный номер телефона или пароль';

  @override
  String get errorUserNotFound => 'Пользователь не найден';

  @override
  String get errorInvalidCode => 'Неверный код подтверждения';

  @override
  String get errorSessionExpired => 'Сессия истекла, попробуйте снова';

  @override
  String get errorSessionExpiredRelogin => 'Сессия истекла. Войдите заново';

  @override
  String get errorUserAlreadyExists => 'Пользователь с таким номером уже существует';

  @override
  String get genericErrorFallback => 'Произошла ошибка, попробуйте позже';

  @override
  String get planNameFree => 'Бесплатно';

  @override
  String get planNameStart => 'Старт';

  @override
  String get planNamePlus => 'Плюс';

  @override
  String get planNameFamily => 'Семья';

  @override
  String get planNamePro => 'Про';

  @override
  String get planNameMax => 'Макс';

  @override
  String get clearDoneButton => 'Очистить';

  @override
  String get allUploadedStatus => 'Всё загружено!';

  @override
  String get noNetworkWaiting => 'Нет сети — ожидание...';

  @override
  String uploadingProgress(int current, int total) {
    return 'Загрузка $current из $total...';
  }

  @override
  String get tapToSelectFiles => 'Нажмите чтобы выбрать';

  @override
  String get photosAndVideosOnly => 'Только фото и видео';

  @override
  String uploadingCountBadge(int count) {
    return '$count загружается';
  }

  @override
  String pausedCountBadge(int count) {
    return '$count на паузе';
  }

  @override
  String doneCountBadge(int count) {
    return '$count готово';
  }

  @override
  String get addFilesButton => 'Добавить';

  @override
  String get waitingForNetworkShort => 'Ожидание сети...';

  @override
  String get uploadingEllipsis => 'Загрузка...';

  @override
  String get selectPhotosVideos => 'Выбрать фото / видео';

  @override
  String get uploadMoreButton => 'Загрузить ещё';

  @override
  String get addMoreButton => 'Добавить ещё';

  @override
  String get pausedWillResumeAuto => 'Нет сети — возобновится автоматически';

  @override
  String shareButtonWithCount(int count) {
    return 'Поделиться ($count)';
  }

  @override
  String filesAndFoldersCount(int files, int folders) {
    return '$files файлов, $folders папок';
  }

  @override
  String get chooseFolderTitle => 'Выберите папку';

  @override
  String get homeFolderLabel => 'Главная';

  @override
  String get invalidPhoneNumber => 'Неверный номер телефона';

  @override
  String get repeatPasswordHint => 'Повторите пароль';

  @override
  String get removedFromFavourites => 'Убрано из избранного';

  @override
  String get alreadyInFavourites => 'Выбранные файлы уже в избранном';

  @override
  String get cannotMoveIntoItself => 'Нельзя переместить папку внутрь самой себя';

  @override
  String get forgotPasswordTitle => 'Забыли пароль?';

  @override
  String get forgotPasswordSubtitle => 'Введите номер телефона, и мы отправим код для сброса пароля.';

  @override
  String get phoneNumberLabel => 'Номер телефона';

  @override
  String get sendOtpCodeButton => 'Отправить код';

  @override
  String get verifyOtpCodeTitle => 'Подтвердите код';

  @override
  String get otpSentToPrefix => 'Мы отправили 6-значный код на ';

  @override
  String get enterCompleteOtpCode => 'Введите полный 6-значный код';

  @override
  String get verifyButton => 'Подтвердить';

  @override
  String get resendCodeButton => 'Отправить код повторно';

  @override
  String get otpCodeResentMessage => 'Код отправлен повторно';

  @override
  String get setNewPasswordTitle => 'Задайте новый пароль';

  @override
  String get setNewPasswordSubtitle => 'Придумайте надёжный пароль не менее 8 символов.';

  @override
  String get enterNewPasswordHint => 'Введите новый пароль';

  @override
  String get confirmNewPasswordHint => 'Подтвердите новый пароль';

  @override
  String get resetPasswordButton => 'Сбросить пароль';

  @override
  String get passwordResetSuccessMessage => 'Пароль успешно изменён!';

  @override
  String get errorOtpStillValid => 'Предыдущий код ещё действителен. Подождите перед запросом нового.';

  @override
  String get loginWelcomeTitle => 'С возвращением в\nBulutcha';

  @override
  String get loginSubtitle => 'Войдите, чтобы получить доступ к своим файлам.';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get enterYourPasswordHint => 'Введите пароль';

  @override
  String get signInButton => 'Войти';

  @override
  String get noAccountPrompt => 'Нет аккаунта? ';

  @override
  String get registerLink => 'Регистрация';

  @override
  String get createAccountTitle => 'Создать аккаунт';

  @override
  String get createAccountSubtitle => 'Зарегистрируйтесь по номеру телефона';

  @override
  String get fullNameLabel => 'Полное имя';

  @override
  String get fullNameHint => 'Иван Иванов';

  @override
  String get nameRequiredError => 'Введите имя';

  @override
  String get currentPasswordRequiredError => 'Введите текущий пароль';

  @override
  String get enterOtpCodeTitle => 'Введите код подтверждения';

  @override
  String get notifications => 'Уведомления';

  @override
  String get noNotificationsYet => 'Пока нет уведомлений';

  @override
  String get markAllAsRead => 'Отметить все прочитанными';

  @override
  String get markAsRead => 'Отметить прочитанным';

  @override
  String get deleteNotification => 'Удалить уведомление';

  @override
  String get notificationDeleteConfirmMessage => 'Удалить это уведомление? Это действие необратимо.';

  @override
  String get failedToLoadNotifications => 'Не удалось загрузить уведомления';

  @override
  String get allNotificationsMarkedRead => 'Все уведомления отмечены прочитанными';

  @override
  String get notificationAccessDenied => 'У вас больше нет доступа к этому.';

  @override
  String get notificationTooManyRequests => 'Слишком много запросов. Подождите немного.';

  @override
  String get notificationActionFailed => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get notifTypeSubscriptionExpiryWarning => 'Подписка скоро истекает';

  @override
  String get notifTypeSubscriptionExpired => 'Подписка истекла';

  @override
  String get notifTypeSubscriptionRenewed => 'Подписка продлена';

  @override
  String get notifTypeSubscriptionDowngraded => 'Подписка понижена';

  @override
  String get notifTypePaymentSuccess => 'Платёж прошёл успешно';

  @override
  String get notifTypePaymentFailed => 'Платёж не прошёл';

  @override
  String get notifTypeCardDeclined => 'Карта отклонена';

  @override
  String get notifTypeFileShared => 'Вам предоставили доступ к файлу';

  @override
  String get notifTypeFileShareRevoked => 'Доступ к файлу отозван';

  @override
  String get notifTypeShareRequestReceived => 'Новый запрос на доступ';

  @override
  String get notifTypeShareRequestApproved => 'Запрос на доступ одобрен';

  @override
  String get notifTypeShareRequestRejected => 'Запрос на доступ отклонён';

  @override
  String get notifTypeSystemAnnouncement => 'Системное уведомление';

  @override
  String get notifTypeStorageWarning => 'Мало свободного места';

  @override
  String get notifTypeStorageFull => 'Хранилище заполнено';

  @override
  String get notifTypeStorageDeletionWarning => 'Запланирована очистка хранилища';

  @override
  String get notifTypeUnknown => 'Новое уведомление';

  @override
  String notifBodySubscriptionExpiryWarning(String plan, String days) {
    return 'Ваш тариф «$plan» истекает через $days дн.';
  }

  @override
  String notifBodySubscriptionExpired(String plan) {
    return 'Ваш тариф «$plan» истёк';
  }

  @override
  String notifBodySubscriptionRenewed(String plan) {
    return 'Ваш тариф «$plan» продлён';
  }

  @override
  String notifBodySubscriptionDowngraded(String plan) {
    return 'Ваш тариф понижен до «$plan»';
  }

  @override
  String notifBodyPaymentSuccess(String amount, String plan) {
    return 'Платёж $amount за тариф «$plan» прошёл успешно';
  }

  @override
  String notifBodyPaymentFailed(String amount, String plan, String error) {
    return 'Платёж $amount за тариф «$plan» не прошёл: $error';
  }

  @override
  String notifBodyCardDeclined(String last4, String plan) {
    return 'Карта, оканчивающаяся на $last4, отклонена при оплате тарифа «$plan»';
  }

  @override
  String notifBodyFileSharedSingle(String sharedBy, String name) {
    return '$sharedBy: открыт доступ к файлу «$name»';
  }

  @override
  String notifBodyFileSharedMultiple(String sharedBy, String count) {
    return '$sharedBy: открыт доступ к файлам ($count)';
  }

  @override
  String notifBodyFileShareRevokedSingle(String sharedBy, String name) {
    return '$sharedBy: доступ к файлу «$name» отозван';
  }

  @override
  String notifBodyFileShareRevokedMultiple(String sharedBy, String count) {
    return '$sharedBy: доступ к файлам отозван ($count)';
  }

  @override
  String notifBodyShareRequestReceived(String requester, String itemName) {
    return 'Запрос на доступ к «$itemName» от $requester';
  }

  @override
  String notifBodyShareRequestApproved(String itemName) {
    return 'Ваш запрос на доступ к «$itemName» одобрен';
  }

  @override
  String notifBodyShareRequestRejected(String itemName) {
    return 'Ваш запрос на доступ к «$itemName» отклонён';
  }

  @override
  String notifBodyStorageWarning(String usedPercent) {
    return 'Использовано $usedPercent% хранилища';
  }

  @override
  String notifBodyStorageFull(String usedBytes, String limitBytes) {
    return 'Хранилище заполнено ($usedBytes из $limitBytes)';
  }

  @override
  String notifBodyStorageDeletionWarning(String deletionDate, String daysLeft) {
    return 'Файлы будут удалены $deletionDate (осталось $daysLeft дн.)';
  }

  @override
  String get notifBodySystemAnnouncementFallback => 'Подробности в приложении';

  @override
  String get errorNetworkUnavailable => 'Нет соединения. Проверьте интернет и повторите попытку.';

  @override
  String get errorRequestTimeout => 'Время ожидания истекло. Повторите попытку.';

  @override
  String get errorAccessDenied => 'Недостаточно прав для этого действия.';

  @override
  String get errorResourceNotFound => 'Объект не найден или уже удалён.';

  @override
  String get errorTooManyRequests => 'Слишком много запросов. Подождите и повторите попытку.';

  @override
  String get errorShareLimitReached => 'Достигнут лимит предоставления доступа.';

  @override
  String get errorServerUnavailable => 'Сервер временно недоступен. Повторите попытку позже.';

  @override
  String get errorValidation => 'Проверьте введённые данные и повторите попытку.';

  @override
  String get errorItemAlreadyExists => 'Такой объект уже существует.';

  @override
  String get errorOtpExpired => 'Срок действия кода истёк. Запросите новый код.';

  @override
  String get errorRequestCancelled => 'Действие отменено.';

  @override
  String get errorSystemFolderProtected => 'Эту системную папку нельзя удалить.';

  @override
  String get pressBackAgainToExit => 'Нажмите «Назад» ещё раз, чтобы закрыть приложение';

  @override
  String get splashTagline => 'Ваши файлы всегда под рукой.';

  @override
  String get languageContinue => 'Продолжить →';

  @override
  String get skipButton => 'Пропустить';

  @override
  String get getStartedButton => 'Начать';

  @override
  String get onboardingFilesTitle => 'Все файлы в одном месте';

  @override
  String get onboardingFilesSubtitle => 'Фото, видео, документы — всё надёжно хранится';

  @override
  String get onboardingSyncTitle => 'Автоматическая синхронизация';

  @override
  String get onboardingSyncSubtitle => 'Галерея загружается фоном — как Google Photos';

  @override
  String get onboardingPrivacyTitle => 'Безопасно и быстро';

  @override
  String get onboardingPrivacySubtitle => 'Ваши данные принадлежат только вам';

  @override
  String get uploadCheckingDuplicates => 'Загрузка завершена. Проверяем дубликаты…';

  @override
  String get syncResumed => 'Синхронизация продолжена.';

  @override
  String syncResumedWithDuplicates(int count) {
    return 'Синхронизация продолжена. Пропущено дубликатов: $count.';
  }

  @override
  String syncPausedForManualUpload(int count) {
    return 'Синхронизация приостановлена. Файлов для загрузки: $count.';
  }

  @override
  String get syncStatusScanning => 'Сканирование галереи...';

  @override
  String get localFileNotFound => 'Файл не найден';
}
