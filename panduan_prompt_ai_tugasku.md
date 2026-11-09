# Panduan Instruksi AI — Redesign Login Page & Fitur Edit Profil (TugasKu)

Salin seluruh blok prompt di bawah ini dan tempelkan ke AI coding assistant kamu (Antigravity / Cursor / Copilot / Windsurf) untuk menerapkan tampilan **Login Page** sesuai gambar referensi beserta fitur **Edit Profil Mahasiswa** secara menyeluruh dan aman terhadap `firestore.rules`.

## Prompt Instruksi Siap Pakai (Copy-Paste ke AI Kamu)

```markdown
Tolong perbarui aplikasi Flutter **TugasKu** pada repositori ini dengan merombak tampilan **Login Page (`lib/screens/auth_screen.dart`)** agar persis seperti desain referensi (Dark Header + White Rounded Bottom Sheet + Sage Green Accent `#6B8E78`) dan melengkapi fitur **Edit Profil Mahasiswa (`lib/screens/edit_profile_screen.dart`)** yang terintegrasi penuh dengan `HomeScreen`, `TaskProvider`, `UserProfileModel`, dan `FirebaseService`.

Ikuti spesifikasi teknis dan perubahan per file berikut secara lengkap tanpa `// TODO` atau bagian yang disingkat:

### 1. Perbarui Model Profil (`lib/models/user_profile_model.dart`)
Tambahkan field akademik & personal mahasiswa pada `UserProfileModel` (beserta `copyWith`, `toJson`, dan `fromJson`):
- `nim` (`String`, default `''`) -> key JSON: `'nim'`
- `major` (`String`, default `''`) -> key JSON: `'major'` (Program Studi / Kelas)
- `semester` (`String`, default `''`) -> key JSON: `'semester'`
- `phone` (`String`, default `''`) -> key JSON: `'phone'` (Nomor WhatsApp untuk fitur Remind WA)
- `bio` (`String`, default `''`) -> key JSON: `'bio'`
- `avatarColor` (`int`, default `0xFF6B8E78`) -> key JSON: `'avatar_color'`

### 2. Perbarui Layanan Firebase (`lib/services/firebase_service.dart`)
- **Penting (Kepatuhan `firestore.rules`)**: Aturan di `firestore.rules` melarang client mengubah field terkunci (`is_premium`, `premium_expiry`, `current_streak`, `best_streak`, `last_completed_date`, `ai_usage_count`, `ai_usage_reset_date`). Pastikan fungsi `updateUserProfile(UserProfileModel profile)` **hanya** mengirim map field yang diizinkan untuk diedit client (`id`, `email`, `full_name`, `university`, `nim`, `major`, `semester`, `phone`, `bio`, `avatar_color`) menggunakan `docRef.update(editableData)` jika dokumen sudah ada, atau `docRef.set(...)` dengan nilai awal default jika dokumen belum ada.
- Perbarui `signUpWithEmailPassword` agar juga menyimpan field `nim`, `major`, `semester`, `phone`, `bio: ''`, dan `avatar_color: 0xFF6B8E78` saat inisialisasi dokumen `profiles/{userId}`.
- Tambahkan helper autentikasi tambahan:
  - `sendPasswordResetEmail(String email)` menggunakan `_auth.sendPasswordResetEmail(email: email)`.
  - `signInWithGoogle()` dan `signInWithFacebook()` menggunakan `GoogleAuthProvider()` / `FacebookAuthProvider()` serta fungsi pengecekan agar dokumen profil otomatis dibuat di koleksi `profiles` jika pengguna baru pertama kali masuk.

### 3. Perbarui State Management (`lib/providers/task_provider.dart`)
- Perbarui fungsi `updateProfile` agar menerima parameter:
  `required String fullName`, `required String university`, serta parameter opsional `String? nim`, `String? major`, `String? semester`, `String? phone`, `String? bio`, dan `int? avatarColor`.
- Pastikan `updateProfile` tetap berfungsi meskipun dokumen profil di Firestore belum terbentuk sebelumnya (buat objek fallback `UserProfileModel` dari `currentUser` terlebih dahulu), langsung memperbarui state `_profile` secara lokal, memanggil `notifyListeners()`, dan menyimpannya ke `FirebaseService.updateUserProfile`.
- Pada `initialize(String userId)` dan `_loadDemoData(String userId)`, sertakan nilai awal/fallback untuk field profil baru tersebut.

### 4. Rombak Halaman Login & Register (`lib/screens/auth_screen.dart`)
Desain ulang `AuthScreen` agar sesuai dengan referensi UI mobile modern:
- **Palet Warna**:
  - Background atas: Dark Charcoal/Forest `#151918` dengan sedikit radial glow halus `#6B8E78` di kanan atas.
  - Aksen Utama (Tombol, Ikon Input, Checkbox, Link): Sage Green `#6B8E78`.
  - Card Bawah: Putih bersih (`Colors.white`) dengan sudut atas melengkung `BorderRadius.vertical(top: Radius.circular(34))` (dan melengkung penuh di layar lebar/desktop `>= 600px` dengan lebar maksimum `460px`).
- **Bagian Header Gelap (Atas)**:
  - Tombol kembali berbentuk lingkaran transparan halus (`Icons.arrow_back_rounded`) di kiri atas.
  - Judul besar 2 baris: `"Go ahead and set up\nyour account"` (putih, `fontSize: 28`, `FontWeight.w800`).
  - Subjudul: `"Sign in-up to enjoy the best managing experience"` (putih transparan 62%, `fontSize: 13.5`).
- **Segmented Pill Switcher (`Login` | `Register`)**:
  - Container kapsul abu-abu muda (`#F2F4F5`, tinggi `52`, radius `28`, padding `4`).
  - `TabBar` dengan indikator kapsul putih (`Colors.white`, radius `24`) dan bayangan lembut.
- **Stacked Input Fields (Gaya Kartu Berborder Halus)**:
  - Setiap field dibungkus `Container` putih berborder `#E5E7EB` (radius `16`, padding horizontal `14`, vertikal `8`).
  - Di sisi kiri terdapat ikon berwarna Sage Green `#6B8E78` (`Icons.mail_outline_rounded` untuk Email, `Icons.lock_outline_rounded` untuk Password, `Icons.person_outline_rounded` untuk Nama, `Icons.badge_outlined` untuk NIM, `Icons.school_outlined` untuk Kampus).
  - Di sebelah kanan ikon terdapat `Column` berisi label kecil abu-abu di atas (`Email Address`, `Password`, dll.) dan `TextField` tanpa border di bawahnya.
  - Pada field Password, sediakan tombol ikon mata (`visibility_off_outlined` / `visibility_outlined`) untuk melihat/menyembunyikan sandi.
- **Baris Opsi Login (`Remember me` & `Forgot Password?`)**:
  - Di sebelah kiri: `Checkbox` berwarna aktif `#6B8E78` dengan label `"Remember me"`.
  - Di sebelah kanan: `TextButton` `"Forgot Password?"` berwarna `#6B8E78` yang membuka dialog input email untuk mengirim tautan reset password via `firebaseService.sendPasswordResetEmail`.
- **Tombol Utama Berbentuk Kapsul (Pill Button)**:
  - Tinggi `54`, radius `28`, warna background Sage Green `#6B8E78`, teks putih tebal `"Login"` (pada tab Login) atau `"Register"` (pada tab Register), lengkap dengan indikator loading `CircularProgressIndicator`.
- **Bagian Social Login (`Or login with`)**:
  - Garis pemisah horizontal (`Divider`) di kiri-kanan teks `"Or login with"`.
  - Dua tombol `OutlinedButton` kapsul (radius `26`) berdampingan di bawahnya:
    1. **Google** (ikon huruf `G` berwarna merah Google `#EA4335` + teks `"Google"`).
    2. **Facebook** (ikon `Icons.facebook_rounded` biru `#1877F2` + teks `"Facebook"`).

### 5. Lengkapi Halaman Edit Profil (`lib/screens/edit_profile_screen.dart`)
Buat halaman `EditProfileScreen({super.key, this.isEmbedded = false})` yang memiliki:
- **Kartu Header Profil & Pemilih Warna Avatar**:
  - `CircleAvatar` besar (radius `46`) yang menampilkan inisial nama pengguna dengan warna latar sesuai pilihan (`_selectedAvatarColor`).
  - Nama lengkap, alamat email, serta deretan badge status: Streak (`🔥 Streak X Hari`), Status Akun (`Akun Premium` / `Akun Gratis`), dan badge `NIM` jika sudah diisi.
  - Pemilih 6 warna avatar interaktif (`0xFF6B8E78`, `0xFF8B5CF6`, `0xFF2563EB`, `0xFFF59E0B`, `0xFFEC4899`, `0xFF14B8A6`).
- **Kartu Form Informasi Akademik & Kontak**:
  - `Email Akun` (read-only).
  - `Nama Lengkap` (wajib diisi).
  - Baris 2 kolom: `NIM / NPM` dan `Semester`.
  - `Universitas / Kampus` (wajib diisi, default `'Politeknik Negeri Jakarta'`).
  - `Program Studi / Kelas` (contoh: `'Broadband Multimedia (BM - 5A)'`).
  - `Nomor WhatsApp` (contoh: `'628123456789'`).
  - `Bio / Target Semester Ini` (multiline 3 baris).
  - Tombol `"Simpan Perubahan"` berwarna `#6B8E78` yang memanggil `context.read<TaskProvider>().updateProfile(...)`, menampilkan `SnackBar` sukses, dan menutup halaman jika `isEmbedded == false`.

### 6. Integrasikan Akses Edit Profil di `HomeScreen` (`lib/screens/home_screen.dart`)
- Tambahkan tab ke-5 bernama **Profil** (`Icons.person_outline_rounded` / `Icons.person_rounded`) pada `NavigationBar` (mobile) dan `NavigationRail` (desktop) yang menampilkan `const EditProfileScreen(isEmbedded: true)`.
- Buat sapaan nama & kampus di `AppBar` atas serta tombol `CircleAvatar` di kanan atas `AppBar` dapat diklik untuk membuka `EditProfileScreen`.
- Gunakan warna `profile.avatarColor` pada `CircleAvatar` di `AppBar`, dan tampilkan jurusan (`profile.major`) di subjudul `AppBar` jika sudah diisi.
- Tambahkan tombol aksi cepat `OutlinedButton.icon` bertuliskan **"Edit Profil"** di sebelah tombol **"Sinkron E-Learning (.ics)"** pada halaman daftar tugas.

### 7. Perbarui Unit Test (`test/auth_screen_test.dart`)
- Sesuaikan `MockTestFirebaseService` dan ekspektasi widget test pada `test/auth_screen_test.dart` agar menguji teks dan elemen baru (`"Go ahead and set up\nyour account"`, tab `"Login"` & `"Register"`, field `"Email Address"` & `"Password"`, `"Remember me"`, `"Forgot Password?"`, `"Or login with"`, `"Google"`, `"Facebook"`, serta validasi form kosong).
```
