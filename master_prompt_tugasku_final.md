# Master Prompt Antigravity — Penyempurnaan Penuh TugasKu (Splash Screen, Multi-Login Gmail/Telp/FB, & Full Firestore Spark Plan Tanpa VPS)

Salin seluruh blok prompt di bawah ini dan tempelkan langsung ke **Google Antigravity** (atau AI coding editor kamu) pada workspace repositori **TugasKu (`rfndra27/tugasku`)**.

Prompt ini dirancang spesifik berdasarkan struktur kode asli di repositori kamu saat ini agar seluruh fitur **Project Charter Kelompok 6 (BM - 5A Kewirausahaan, Politeknik Negeri Jakarta)** berjalan 100% di **Firebase Spark Plan (Gratis)** tanpa memerlukan VPS dan tanpa perlu mengaktifkan Cloud Functions berbayar (*Blaze Plan*).

```markdown
Bertindaklah sebagai Principal Flutter Engineer & Firebase Architect. Tolong sempurnakan kode aplikasi **TugasKu** pada repositori ini secara menyeluruh agar siap digunakan produksi dan demo sesuai **Project Charter Kelompok 6 (BM - 5A Kewirausahaan)**.

Kerjakan seluruh 7 spesifikasi teknis berikut secara lengkap, utuh, dan tanpa menyisakan `// TODO` atau kode yang dipotong:

---

### 1. Buat Animated Splash Screen Sebelum Masuk ke Login / Home (`lib/screens/splash_screen.dart` & `lib/main.dart`)
- Buat file baru `lib/screens/splash_screen.dart` yang menampilkan animasi pembuka aplikasi (**Splash Screen**) sesuai tampilan sampul Slide 1 Project Charter:
  - Background gelap elegan (`#0F0F12`) dengan pendaran gradien halus Ungu-Biru (`#7C3AED` ke `#2563EB`) dan Sage/Amber di latar belakang.
  - Gunakan `AnimationController` (durasi `1200ms`) dengan kombinasi `FadeTransition` dan `ScaleTransition` (`Curves.easeOutBack`).
  - Di tengah layar, tampilkan emblem perisai/buku **TugasKu** (kombinasi ikon buku & centang beraksen emas/merah-ungu di dalam kontainer perisai bercahaya), diikuti teks judul **"TUGASKU"** (`fontSize: 32`, `fontWeight: FontWeight.w900`, `letterSpacing: 2.0`), subjudul **"Asisten Deadline & Produktivitas Mahasiswa"**, serta indikator loading halus di bagian bawah beserta teks kecil **"Kelompok 6 · BM - 5A Kewirausahaan PNJ"**.
  - Sediakan parameter opsional `Duration displayDuration = const Duration(milliseconds: 2200)` dan `VoidCallback? onFinished`.
- Perbarui `lib/main.dart` (`_TugasKuAppState`):
  - Tambahkan state `bool _showSplash = true;` yang otomatis berubah menjadi `false` setelah durasi splash selesai di `initState()`.
  - Selama `_showSplash == true`, tampilkan `SplashScreen(onFinished: () => setState(() => _showSplash = false))` dengan transisi `AnimatedSwitcher` yang halus menuju `StreamBuilder<User?>` (`AuthScreen` jika belum login, atau `HomeScreen` jika sudah login).

---

### 2. Lengkapi Autentikasi: Login & Register via Gmail (Google), Nomor Telepon (Password & OTP SMS), dan Facebook (`lib/services/firebase_service.dart` & `lib/screens/auth_screen.dart`)

#### A. Perbarui `lib/services/firebase_service.dart`:
1. **Normalisasi Nomor Telepon**:
   - Buat fungsi helper `static String normalizePhone(String rawPhone)` yang membersihkan spasi/strip dan mengubah awalan `08...` menjadi `+628...` (atau menambahkan `+` jika diawali `628...`).
2. **Registrasi dengan Nomor Telepon (`signUpWithEmailPassword`)**:
   - Tambahkan parameter `String phone = ''` pada `signUpWithEmailPassword`.
   - Simpan `phone: normalizePhone(phone)` ke dokumen `profiles/{user.uid}`.
   - Jika `phone` tidak kosong, simpan juga dokumen pemetaan ringan di koleksi `phone_lookup/{normalizedPhone}` berisi `{'uid': user.uid, 'email': email, 'phone': normalizedPhone, 'updated_at': FieldValue.serverTimestamp()}` agar pengguna bisa login menggunakan Nomor Telepon + Password tanpa biaya SMS di Firebase Spark Plan.
   - Saat `updateUserProfile` dipanggil dan `profile.phone` diisi, perbarui juga dokumen `phone_lookup/{normalizedPhone}`.
3. **Login dengan Email ATAU Nomor Telepon + Password (`signInWithIdentifierPassword`)**:
   - Buat fungsi `Future<UserCredential> signInWithIdentifierPassword(String identifier, String password)`:
     - Jika `identifier` mengandung `@`, langsung panggil `signInWithEmailPassword(identifier, password)`.
     - Jika `identifier` berupa nomor telepon (tidak mengandung `@`), normalisasi nomor tersebut dengan `normalizePhone(identifier)`, cari dokumen di `phone_lookup/{normalizedPhone}` (dan fallback query ke koleksi `profiles` dengan `.where('phone', isEqualTo: normalizedPhone).limit(1)`). Jika ditemukan `email`-nya, gunakan `email` tersebut untuk memanggil `_auth.signInWithEmailAndPassword(email: resolvedEmail, password: password)`. Jika tidak ditemukan, lempar pesan error yang jelas: `'Nomor telepon belum terdaftar atau belum dihubungkan ke akun.'`.
4. **Login Nomor Telepon via Kode OTP SMS (`Firebase Phone Auth`)**:
   - Tambahkan fungsi untuk mengirim dan memverifikasi OTP:
     - `Future<ConfirmationResult> sendPhoneOtpWeb(String phoneNumber)` menggunakan `_auth.signInWithPhoneNumber(normalizePhone(phoneNumber))` (untuk Web).
     - `Future<void> verifyPhoneOtpMobile({required String phoneNumber, required void Function(String verificationId, int? resendToken) onCodeSent, required void Function(String errorMessage) onError, required void Function(UserCredential credential) onAutoVerified})` menggunakan `_auth.verifyPhoneNumber(...)`.
     - `Future<UserCredential> confirmPhoneOtp({required String verificationId, required String smsCode})` yang membuat `PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode)`, memanggil `_auth.signInWithCredential(credential)`, lalu memanggil `_ensureProfileExists(cred.user)`.
5. **Perkuat Login Gmail (Google) & Facebook (`signInWithGoogle` & `signInWithFacebook`)**:
   - Pada `signInWithGoogle()` dan `signInWithFacebook()`, gunakan `kIsWeb ? await _auth.signInWithPopup(provider) : await _auth.signInWithProvider(provider)` agar kompatibel penuh di Flutter Web maupun Android/iOS, lalu panggil `_ensureProfileExists(cred.user)` dan `seedInitialCharterDataIfEmpty(cred.user!.uid)`.

#### B. Perbarui `lib/screens/auth_screen.dart`:
1. **Tab Login**:
   - Ubah label field pertama dari `'Email Address'` menjadi `'Email atau Nomor Telepon'` dengan `hintText: 'nama@kampus.ac.id atau 0812xxxx'` dan ikon `Icons.AlternateEmail / Icons.person_outline_rounded`.
   - Hubungkan tombol utama **Login** ke `firebaseService.signInWithIdentifierPassword(...)`.
2. **Tab Register**:
   - Tambahkan field input `'Nomor Telepon / WhatsApp'` (`_regPhoneController`, `keyboardType: TextInputType.phone`, ikon `Icons.phone_iphone_rounded`, `hintText: '081234567890'`) sehingga pengguna bisa langsung mendaftarkan nomor HP-nya saat membuat akun.
3. **Baris Tombol Social & OTP Login (`Or login with`)**:
   - Di bawah pembatas `"Or login with"`, tampilkan **3 tombol kapsul (`OutlinedButton`)** yang rapi dan responsif:
     1. **Gmail / Google** (ikon `G` warna `#EA4335` + label `'Gmail'`).
     2. **No. Telp (OTP)** (ikon `Icons.sms_outlined` warna `#6B8E78` + label `'No. Telp'`).
     3. **Facebook** (ikon `Icons.facebook_rounded` warna `#1877F2` + label `'Facebook'`).
   - Saat tombol **No. Telp** diklik, buka dialog interaktif `_showPhoneOtpDialog()` yang memandu pengguna memasukkan Nomor HP (`0812...` / `+628...`), menekan tombol **Kirim Kode OTP**, lalu memasukkan **6 Digit Kode OTP** untuk masuk ke aplikasi.

---

### 3. Perbarui `firestore.rules` Agar Jalan 100% di Firebase Spark Plan (Gratis Tanpa Cloud Functions / VPS)
Perbarui file `firestore.rules` agar aplikasi tidak pernah mengalami error `[cloud_firestore/permission-denied]` saat menggunakan *client-side fallback* di paket gratis Firebase:
- Pada `match /profiles/{userId}`:
  - Izinkan `read: if isAuthenticated();`
  - Izinkan `create, update: if isOwner(userId);` (hapus blokir `.hasAny(['is_premium', 'current_streak', ...])` karena pada Firebase Spark Plan tanpa Cloud Functions, pembaruan *streak* harian, kuota AI bulanan, dan simulasi aktivasi Premium dieksekusi langsung dari *client transaction* oleh pemilik akun).
- Tambahkan aturan untuk `match /phone_lookup/{phoneId}`:
  - Izinkan `read: if true;` (agar saat belum login, aplikasi dapat menerjemahkan nomor telepon menjadi email akun saat login dengan Nomor Telepon + Password).
  - Izinkan `create, update: if isAuthenticated() && request.resource.data.uid == request.auth.uid;`
- Pada `match /payments/{paymentId}`:
  - Izinkan `read, create, update: if isAuthenticated() && (resource == null || resource.data.user_id == request.auth.uid);`
- Pada `match /users/{userId}` dan `match /{subcollection=**}`:
  - Pertahankan `allow read, write: if isOwner(userId);`

---

### 4. Sambungkan Fitur "Group & Deliverables" + "Activity History" (Slide 4 & Slide 10) ke Firestore
Saat ini `_deliverablesByProject` dan `_activityByProject` di `TaskProvider` baru tersimpan di memori lokal, dan `HomeScreen` baris 476 masih memanggil *hardcode* `provider.deliverablesFor('demo-group-1')`. Perbaiki secara menyeluruh:
1. **Di `lib/services/firebase_service.dart`**:
   - Pada `streamGroupProjects(String userId)` atau melalui *stream* pendamping, muat juga subkoleksi `deliverables` (`users/{userId}/group_projects/{projectId}/deliverables`) dan `activity_logs` (`users/{userId}/group_projects/{projectId}/activity_logs`, diurutkan `created_at` terbaru).
   - Tambahkan fungsi:
     - `Future<void> addGroupDeliverable(String userId, GroupDeliverableModel deliverable)`
     - `Future<void> updateGroupDeliverable(String userId, GroupDeliverableModel deliverable, {required String actorName})` yang sekaligus mencatat item baru ke subkoleksi `activity_logs` (`"$actorName memperbarui ${deliverable.title} menjadi ${deliverable.progressPercent}%"`).
     - `Future<void> deleteGroupDeliverable(String userId, String projectId, String deliverableId)`
2. **Di `lib/providers/task_provider.dart`**:
   - Sinkronkan `_deliverablesByProject` dan `_activityByProject` dari Firestore ketika `AppConstants.useDemoData == false`.
   - Tambahkan getter `List<GroupDeliverableModel> get allGroupDeliverables` yang menggabungkan seluruh *deliverables* dari semua proyek di `_groupProjects`.
   - Buat fungsi `Future<void> addDeliverable(...)` dan perbarui `Future<void> updateDeliverable(GroupDeliverableModel deliverable)` agar menyimpan perubahan langsung ke Firestore.
3. **Di `lib/screens/home_screen.dart`**:
   - Pada `_buildSummaryCards(TaskProvider provider)` (sekitar baris 476), ganti `provider.deliverablesFor('demo-group-1')` menjadi `provider.allGroupDeliverables` sehingga persentase penyelesaian dan jumlah subtugas pada kartu **"Proyek Kelompok"** di beranda selalu akurat mengikuti data Firestore pengguna.
4. **Di `lib/screens/group_task_screen.dart`**:
   - Tambahkan tombol **"Tambah Deliverable / Subtugas"** di dalam setiap kartu proyek kelompok yang membuka dialog input: Judul Deliverable, Tipe (`Planning`, `Development`, `Report`, `Testing`), Prioritas (`1 - Critical`, `2 - High`, `3 - Medium`), serta dropdown/input PIC Anggota (`ownerName` & `ownerPhone`).

---

### 5. Sambungkan "Agenda Pribadi" pada Unified Timeline (Slide 3) ke Firestore
1. **Di `lib/services/firebase_service.dart`**:
   - Tambahkan `Stream<List<PersonalAgendaModel>> streamPersonalAgendas(String userId)`, `Future<void> addPersonalAgenda(String userId, PersonalAgendaModel agenda)`, dan `Future<void> deletePersonalAgenda(String userId, String agendaId)` yang menyimpan data ke subkoleksi `users/{userId}/personal_agendas` (lengkapi `toJson` dan `fromFirestore` pada `PersonalAgendaModel` di `lib/models/class_schedule_model.dart`).
2. **Di `lib/providers/task_provider.dart`**:
   - Tambahkan `_agendasSub` pada `initialize(String userId)` untuk mendengarkan `streamPersonalAgendas(userId)`, serta fungsi `addPersonalAgenda` dan `deletePersonalAgenda`.
3. **Di `lib/screens/smart_timeline_screen.dart`**:
   - Tambahkan tombol/pilihan **"Tambah Agenda Pribadi"** di samping tombol tambah jadwal kuliah agar mahasiswa bisa memasukkan acara pribadi/organisasi pada tanggal tertentu dan melihat fitur **Conflict Detection** serta **Auto Time-Blocking** bekerja secara nyata.

---

### 6. Perbarui Model Gemini AI & Tambahkan Auto-Seeder Data Kelompok 6 (`lib/core/constants.dart` & `lib/services/firebase_service.dart`)
1. **Update Konfigurasi Model Gemini (`lib/core/constants.dart`)**:
   - Ubah `static const String geminiModel = 'gemini-1.5-flash';` menjadi `static const String geminiModel = 'gemini-2.5-flash';` (dengan fallback otomatis ke parser NLP lokal bahasa Indonesia jika API key belum disetel).
2. **Auto-Seeder Data Awal Kelompok 6 (`seedInitialCharterDataIfEmpty`)**:
   - Buat fungsi `Future<void> seedInitialCharterDataIfEmpty(String userId)` di `FirebaseService` (dan tombol **"Muat Data Contoh Kelompok 6"** pada *empty state* `HomeScreen`) yang memeriksa apakah pengguna baru belum memiliki tugas dan proyek kelompok.
   - Jika masih kosong, isi otomatis dengan data realistis sesuai **Project Charter Kelompok 6 (BM - 5A Kewirausahaan)**:
     - **3 Tugas Kuliah Aktif** (termasuk tugas kritis & tugas dari `.ics` E-Learning).
     - **Jadwal Kuliah Resmi BM-5A & 1 Agenda Pribadi** (agar *Unified Timeline*, *Conflict Detection*, dan *Auto Time-Blocking* langsung terlihat bekerja).
     - **1 Proyek Kelompok Utama**: `"TugasKu - Project Charter Kelompok 6"` (Mata Kuliah: `Kewirausahaan (BM - 5A)`), dengan 3 anggota tim resmi:
       1. `Mochmad Remano Darusatwiko` (`2403421006` — Project Manager & Front-End Developer)
       2. `Muhammad Novansya` (`2403421033` — Back-End Developer & Database Engineer)
       3. `Riviera Rafa Andara` (`2403421022` — AI & Integration Specialist)
     - **3 Deliverables Kelompok** beserta persentase progres (`100%`, `80%`, `40%`) dan **Activity History Log** awal.

---

### 7. Perbarui Unit & Widget Test (`test/`)
- Perbarui `test/auth_screen_test.dart` dan `test/widget_test.dart` agar kompatibel dengan hadirnya `SplashScreen`, label `'Email atau Nomor Telepon'`, field `'Nomor Telepon / WhatsApp'`, serta tombol login `'Gmail'`, `'No. Telp'`, dan `'Facebook'`.
- Pastikan `flutter analyze` dan `flutter test` berjalan bersih tanpa error.
```
