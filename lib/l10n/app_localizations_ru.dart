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
  String get reviewAccessRequestSubtitle =>
      'Выберите, следует ли предоставить доступ этому пользователю.';

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
  String get noShareRequestsSubtitle =>
      'Поделитесь файлами по ссылке и они появятся здесь';

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
  String get logoutConfirmMessage =>
      'Вы уверены, что хотите выйти из аккаунта?';

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
  String get couldNotOpenImage => 'Не удалось открыть изображение';

  @override
  String get couldNotOpenVideo => 'Не удалось открыть видео';

  @override
  String get noSharedWithMe => 'Никто не делился файлами';

  @override
  String get noSharedWithMeSubtitle =>
      'Когда кто-то поделится файлом — они появятся здесь';

  @override
  String get noSharedByMe => 'Вы ещё ни с кем не делились';

  @override
  String get noSharedByMeSubtitle =>
      'Нажмите кнопку шаринга чтобы поделиться файлами';

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
  String get syncFolderReadOnly =>
      'Это папка синхронизации. Файлы здесь управляются автоматически.';

  @override
  String get syncResetConfirmTitle => 'Сбросить очередь?';

  @override
  String get syncResetConfirmMessage =>
      'Все записи будут удалены. После этого приложение заново просканирует галерею.';

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
<<<<<<< HEAD
  String get syncSelectedFiles => 'Выбранные файлы';

  @override
  String get syncSelectedFilesSubtitle => 'Синхронизировать только выбранные';

  @override
  String get syncTotal => 'Всего';

  @override
  String get uploadedLabel => 'Загружено';

  @override
  String get uploadPageTitle => 'Загрузка';

  @override
  String get cancelledLabel => 'Отменено';
=======
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
  String get deleteAccountConfirmMessage =>
      'Вы уверены, что хотите удалить аккаунт? Это действие необратимо.';
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
}
