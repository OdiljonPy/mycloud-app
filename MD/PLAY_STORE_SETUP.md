# Google Play Store ga chiqarish yo'riqnomasi

## 1. Signing Key yaratish

### Terminalda quyidagi buyruqni ishga tushiring:

```bash
keytool -genkey -v -keystore ~/bulutcha-upload-key.jks \
-storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
-alias bulutcha
```

### Buyruq sizdan so'raydi:

1. **Enter keystore password:** - Parol kiriting (masalan: `BulutchaSecure2024!`)
2. **Re-enter new password:** - Parolni qayta kiriting
3. **What is your first and last name?** - Ismingiz (masalan: `Odiljon`)
4. **What is the name of your organizational unit?** - Bo'lim (masalan: `Development`)
5. **What is the name of your organization?** - Kompaniya (masalan: `Bulutcha`)
6. **What is the name of your City or Locality?** - Shahar (masalan: `Tashkent`)
7. **What is the name of your State or Province?** - Viloyat (masalan: `Tashkent`)
8. **What is the two-letter country code for this unit?** - Mamlakat (masalan: `UZ`)
9. **Is CN=..., OU=..., O=..., L=..., ST=..., C=... correct?** - `yes` deb yozing
10. **Enter key password for <bulutcha>** - Enter bosing (xuddi keystore paroli ishlatiladi)

### Natijada:
- `~/bulutcha-upload-key.jks` fayli yaratiladi

---

## 2. key.properties fayl yaratish

`android/key.properties` fayl yarating va quyidagi ma'lumotlarni kiriting:

```properties
storePassword=BulutchaSecure2024!
keyPassword=BulutchaSecure2024!
keyAlias=bulutcha
storeFile=/Users/admin/bulutcha-upload-key.jks
```

**⚠️ MUHIM:**
- `storePassword` va `keyPassword` - siz kiritgan parollar
- `storeFile` - JKS fayl yo'li (to'liq path)

---

## 3. Release APK/AAB yaratish

### APK yaratish:
```bash
fvm flutter build apk --release
```

**Natija:** `build/app/outputs/flutter-apk/app-release.apk`

### AAB yaratish (Google Play uchun tavsiya etiladi):
```bash
fvm flutter build appbundle --release
```

**Natija:** `build/app/outputs/bundle/release/app-release.aab`

---

## 4. Google Play Console setup

### 4.1. Play Console ga kiring:
https://play.google.com/console

### 4.2. Yangi ilova yarating:
1. **Create app** tugmasini bosing
2. **App name:** Bulutcha
3. **Default language:** O'zbek yoki English
4. **App or game:** App
5. **Free or paid:** Free
6. **Declarations** - checkboxlarni belgilang
7. **Create app**

### 4.3. App details to'ldiring:
- **Short description** (80 ta belgi)
- **Full description** (4000 ta belgi)
- **App icon** (512x512 PNG)
- **Feature graphic** (1024x500 PNG)
- **Screenshots** (telefon va planshet uchun)

### 4.4. Release yarating:
1. **Production** → **Create new release**
2. **Upload** → `app-release.aab` faylini yuklang
3. **Release name:** 1.0.0
4. **Release notes** yozing
5. **Save** → **Review release**
6. **Start rollout to Production**

---

## 5. Ilova ma'lumotlari

```
Application ID: com.bulutcha.app
App Name: Bulutcha
Version: 1.0.0+1
```

---

## 6. Xavfsizlik

**⚠️ JUDA MUHIM:**
1. `android/key.properties` - Git ga qo'shilMAYDI (`.gitignore` da bor)
2. `bulutcha-upload-key.jks` - Git ga qo'shilMAYDI
3. Bu fayllarni xavfsiz joyda saqlang (Google Drive, 1Password, va h.k.)
4. Parollarni yo'qotmang - JKS faylsiz yangi versiya chiqara olmaysiz!

---

## 7. Keyingi versiyalar

Yangi versiya chiqarish uchun:

1. `pubspec.yaml` da versiyani oshiring:
   ```yaml
   version: 1.0.1+2  # 1.0.0+1 dan
   ```

2. Build yarating:
   ```bash
   fvm flutter build appbundle --release
   ```

3. Play Console ga yuklang

---

## 8. Foydali linklar

- [Play Console](https://play.google.com/console)
- [Flutter Publishing Guide](https://docs.flutter.dev/deployment/android)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)