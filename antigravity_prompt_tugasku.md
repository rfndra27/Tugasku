# 🚀 Master Prompt Antigravity — Proyek TugasKu (Flutter + Firebase)

Dokumen ini berisi **Master Prompt (Prompt Utama)** dan **Modular Prompts (Prompt Bertahap)** yang dirancang secara terstruktur, spesifik, dan *production-ready* untuk digunakan di **Antigravity** (AI Coding Agent / IDE).

---

## 💡 Cara Terbaik Menggunakan Prompt Ini di Antigravity

Agar hasil generate code dari Antigravity tidak terpotong, bebas *bug*, dan langsung *compile*, kamu bisa memilih salah satu dari 2 cara ini:
1. **Cara All-in-One (Langsung Jadi)**: Salin bagian **1. MASTER PROMPT (ALL-IN-ONE)** di bawah dan tempel langsung ke chat/agent Antigravity.
2. **Cara Bertahap / Step-by-Step (Paling Direkomendasikan untuk Akurasi Tinggi)**: Gunakan **2. MODULAR PROMPTS** secara berurutan (Tahap 1 sampai Tahap 3) agar agent menulis setiap file secara utuh tanpa ada fungsi yang disingkat (`// TODO`).

---

## 1. MASTER PROMPT (ALL-IN-ONE)
*Salin seluruh blok di bawah ini dan tempelkan ke Antigravity:*

```markdown
Act as a Principal Flutter Engineer & Firebase Backend Architect. Build a complete, production-ready, end-to-end Flutter application connected to Firebase called **"TugasKu"** (Asisten Deadline Mahasiswa).

### 1. PRODUCT OVERVIEW & VALUE PROPOSITION
"TugasKu" solves scattered college assignments across e-learning (Moodle/Canvas/Classroom), WhatsApp groups, and personal notes by centralizing them into a single AI-powered mobile app with smart scheduling, gamification, and group task accountability.

### 2. TECH STACK & ARCHITECTURE REQUIREMENTS
- **Frontend**: Flutter (Dart >= 3.3.0), Material 3 design system, `Plus Jakarta Sans` typography (`google_fonts`), clean modular architecture (`core/`, `models/`, `services/`, `providers/`, `screens/`, `widgets/`).
- **State Management**: `provider` (`ChangeNotifier`).
- **Backend & Database**: `firebase_core`, `firebase_auth`, and `cloud_firestore` (Firebase Authentication, Cloud Firestore, Firestore Security Rules, and Cloud Functions).
- **AI Engine**: Google Gemini 1.5 Flash API (`http` JSON mode) with a deterministic local Indonesian NLP/Regex fallback parser so the app works reliably even without an active API key.
- **Key Packages**: `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `provider`, `google_fonts`, `intl`, `confetti`, `url_launcher`, `http`, `flutter_local_notifications`, `shared_preferences`, `uuid`.

---

### 3. FIREBASE DATA MODEL & BACKEND LOGIC
Write the complete Firebase configuration, Firestore data model, Security Rules, indexes, and Cloud Functions required by the application. Use collections/documents for:

1. **Tables**:
   - `profiles/{userId}`: `email`, `full_name`, `university`, `is_premium`, `premium_expiry`, streak fields, and monthly AI quota fields.
   - `users/{userId}/courses/{courseId}`: course name, code, lecturer name, and color.
   - `users/{userId}/tasks/{taskId}`: course reference, title, description, Firestore `Timestamp` deadline, weight, priority, completion state, source, external UID, and group-task flag. Prevent duplicate e-learning tasks with a deterministic document ID or a transaction keyed by `external_uid`.
   - `users/{userId}/tasks/{taskId}/subtasks/{subtaskId}`: title, completion state, assignee, phone number in `628xxx` format, due date, and order index.
   - `users/{userId}/group_projects/{projectId}` and `group_members`: collaborative tasks, invite codes, roles, and WhatsApp numbers.
   - `users/{userId}/class_schedules/{scheduleId}`: course, weekday, start time, end time, and room.
   - `users/{userId}/elearning_configs/{configId}`: iCal URL, platform name, and last sync time.

2. **Cloud Functions and transactional backend logic**:
   - `handleNewUser`: Callable or Auth-triggered Cloud Function to create `profiles/{userId}` after registration.
   - `calculatePriority(deadline, weight)` and a shared Dart/Cloud Functions implementation:
     Automatically calculates `priority_score` based on urgency and grade weight:
     - Overdue (`hours_left <= 0`): `9999.0`
     - Critical (`hours_left <= 24`): `(weight * 10.0) + (1000.0 / (hours_left + 0.5))`
     - Normal (`hours_left > 24`): `(weight * 2.0) + (500.0 / (hours_left / 24.0))`
   - `completeTaskWithStreak`: Callable Cloud Function using a Firestore transaction to update completion, streak, and best streak atomically.
   - `checkAndIncrementAiQuota`: Callable Cloud Function enforcing 5 AI calls/month for Free users and unlimited calls for Premium users. Returns `{allowed, is_premium, usage_count, remaining, message}`.
   - `checkTaskOverload`: Callable Cloud Function or repository query that checks active tasks due within three days and flags overload when `count >= 3` or total weight is at least 35%.

3. **Firestore Security Rules**:
   - Require authentication for private data.
   - Allow users to read and write only their own profile, subcollections, tasks, schedules, and configurations.
   - Validate immutable ownership fields, allowed enum values, and Premium-only operations in rules or Cloud Functions.

---

### 4. CORE FEATURES & BUSINESS LOGIC TO IMPLEMENT IN FLUTTER

1. **✨ AI Features (`AiService`)**:
   - **Smart Task Input**: User pastes a raw lecturer/WhatsApp message (e.g., *"Kumpul laporan praktikum Jumat jam 10, bobot 20%"*). The AI extracts JSON `{title, course_name, deadline, weight_percentage, description}` and pre-fills the task creation form. Include an Indonesian NLP regex fallback parser for days (`senin`-`minggu`), times (`jam XX`), and weights (`XX%`).
   - **Pecah Tugas (Task Breakdown)**: Takes a large task title, course, and deadline, and generates 4–5 actionable subtasks saved directly to `public.subtasks`.
   - **Asisten AI Chat**: Conversational assistant where students ask *"tugas apa hari ini?"* or *"mana yang harus dicicil duluan?"*. Injects the user's active tasks from Cloud Firestore into the system prompt so answers are 100% grounded in the user's real deadlines and weights.
   - All AI actions must call `check_and_increment_ai_quota` first and trigger the Premium Paywall if the Free quota (5x/month) is exhausted.

2. **📋 Smart Task Management (`HomeScreen`, `TaskCardWidget`, `NotificationService`)**:
   - **Auto-Sorting**: Tasks are sorted by `priority_score` descending.
   - **Swipe Gestures (`Dismissible`)**:
     - **Swipe Right (Green background)**: Marks task completed, triggers confetti blast (`ConfettiWidget`), and increments daily streak.
     - **Swipe Left (Red background)**: Shows confirmation dialog and deletes the task.
   - **Overload Warning Banner**: Displays a prominent red alert card at the top of the dashboard when `isOverloaded == true`, with a quick action button to jump to the Smart Schedule Timeline.
   - **Tiered Local Notifications**: Automatically schedules 3 local notifications per task: **H-3 days**, **H-1 day**, and **3 hours before deadline**.

3. **🎓 E-Learning Calendar Sync (`ICalSyncService` & `ElearningSyncDialog`)**:
   - User pastes an iCal (`.ics`) export URL from Moodle/Canvas/Google Classroom.
   - Parses `VEVENT` blocks (`UID`, `SUMMARY`, `DESCRIPTION`, `DTEND`/`DUE`).
   - **Deduplication & Auto-Update**: Matches against `external_uid`. Inserts new tasks if not found; updates `deadline` and recalculates priority if the lecturer shifted the deadline in e-learning.

4. **🗓️ Smart Schedule & Auto Study-Gap Filler (`SmartScheduleService` & `SmartTimelineScreen`)**:
   - Displays a unified daily timeline combining regular `class_schedules` and `task_deadlines`.
   - **Auto Gap-Filler Algorithm**: Scans consecutive classes on the selected day. Whenever an empty gap between two classes is `>= 60 minutes`, automatically inserts a recommended **"⚡ Jam Belajar Celah"** block (with 15-minute buffer after class and before the next class) assigned to the user's highest-priority active task.

5. **👥 Group Tasks & WhatsApp Nudge (`GroupTaskScreen` & `WhatsAppService`)**:
   - Displays overall group progress bar and member-assigned subtasks.
   - Enforces Free tier limit (max 3 group members) vs Premium (unlimited members).
   - **"Remind WA" Button**: Next to any uncompleted member subtask, clicking `Remind WA` normalizes the Indonesian phone number (`08xx` -> `628xx`) and launches `https://wa.me/<phone>?text=<encoded_message>` via `url_launcher` with a friendly pre-filled Indonesian reminder containing the member's name, subtask title, course name, and formatted deadline.

6. **🔥 Gamification & 💰 Freemium Paywall (`PremiumScreen`)**:
   - AppBar displays a live `🔥 X Hari` streak counter badge.
   - Full Confetti overlay (`confetti` package) triggered on task completion and 100% subtask completion.
   - **Pricing & Tiering**:
     - **Gratis**: Basic task management, AI 5x/month, Group max 3 members.
     - **Premium (Rp10.000/bulan)**: Unlimited AI, unlimited group members, full AI Assistant access, and workload statistics.

---

### 5. DELIVERABLE RULES
- Write **complete, full implementation code** for every single file—never leave placeholders, `// TODO`, or truncated methods.
- Ensure all imports, models, providers, and UI screens are properly wired in `lib/main.dart`.
- Provide Firebase configuration files, `firestore.rules`, `firestore.indexes.json`, Cloud Functions where required, `pubspec.yaml`, and all Dart files under `lib/`.
```

---

## 2. MODULAR PROMPTS (TAHAP DEMI TAHAP)
*Jika kamu ingin memandu Antigravity secara bertahap agar setiap modul dikerjakan sangat detail, gunakan 3 prompt berurutan di bawah ini:*

### Tahap 1: Setup Firebase, Firestore & Core Models
```markdown
Kita sedang membangun aplikasi Flutter + Firebase bernama "TugasKu" (Asisten Deadline Mahasiswa).
Pada Tahap 1 ini, tolong buatkan secara lengkap tanpa ada kode yang disingkat:
1. Konfigurasi Firebase, `firestore.rules`, dan `firestore.indexes.json`. Gunakan koleksi `profiles`, `users/{userId}/courses`, `tasks`, `subtasks`, `group_projects`, `group_members`, `class_schedules`, dan `elearning_configs`, dengan isolasi data berdasarkan `request.auth.uid`.
2. `functions/` atau Cloud Functions yang diperlukan untuk pembuatan profil otomatis, kalkulasi prioritas, penyelesaian tugas dengan streak, kuota AI (Gratis 5x/bulan vs Premium unlimited), dan deteksi overload.
3. File `pubspec.yaml` beserta `lib/core/constants.dart`, `lib/core/theme.dart` (Material 3 + Plus Jakarta Sans), dan `lib/core/priority_calculator.dart`.
4. Seluruh data model di `lib/models/` (`task_model.dart`, `subtask_model.dart`, `group_task_model.dart`, `class_schedule_model.dart`, `user_profile_model.dart`) lengkap dengan `fromJson`, `toJson`, dan `copyWith`, menggunakan `Timestamp`/`DateTime` secara konsisten.
```

### Tahap 2: Services & State Management (AI, iCal, Jadwal Pintar, WA, Notifikasi)
```markdown
Sekarang lanjut ke Tahap 2 untuk aplikasi "TugasKu". Tolong buatkan seluruh layer Service dan Provider secara utuh (tanpa placeholder):
1. `lib/services/firebase_service.dart`: Menangani CRUD tugas & subtask dengan Cloud Firestore, pengambilan jadwal kuliah, pemanggilan callable Cloud Functions untuk streak, kuota AI, dan deteksi overload.
2. `lib/services/ai_service.dart`:
   - `parseLecturerMessage(String rawText)`: Ekstraksi pesan dosen/WA menjadi JSON `{title, course_name, deadline, weight_percentage, description}` menggunakan Gemini 1.5 Flash API + fallback parser Regex bahasa Indonesia.
   - `breakdownTask(...)`: Memecah tugas besar menjadi 4-5 langkah kecil (subtasks).
   - `askAssistant(...)`: Menjawab pertanyaan mahasiswa ("tugas apa hari ini?") berdasarkan data tugas aktif mereka.
   - Wajib memanggil pengecekan kuota AI melalui callable Cloud Function terlebih dahulu.
3. `lib/services/ical_service.dart`: Mengunduh dan mem-parsing URL kalender `.ics` e-learning (Moodle/Canvas), mencegah tugas dobel lewat `external_uid`, dan meng-update deadline otomatis jika berubah.
4. `lib/services/smart_schedule_service.dart`: Menggabungkan jadwal kuliah dan deadline tugas dalam 1 timeline harian, serta otomatis mengisi celah kosong antarkuliah (>= 60 menit) dengan blok rekomendasi "⚡ Jam Belajar Celah" untuk mencicil tugas prioritas tertinggi.
5. `lib/services/whatsapp_service.dart`: Fungsi tombol "Remind WA" yang menormalisasi nomor HP ke `628xxx` dan membuka `wa.me` dengan template pesan pengingat kelompok yang ramah.
6. `lib/services/notification_service.dart`: Penjadwalan pengingat bertingkat H-3, H-1, dan 3 jam sebelum deadline.
7. `lib/providers/task_provider.dart`: State management `ChangeNotifier` yang menghubungkan semua service di atas ke UI dan memantau perubahan Firestore secara realtime.
```

### Tahap 3: Seluruh UI, Autentikasi, Premium & Integrasi Final
```markdown
Lanjut ke Tahap 3 untuk aplikasi "TugasKu". Buatkan komponen widget dan halaman utama berikut dengan desain modern, bersih, dan ramah mahasiswa:
1. `lib/widgets/confetti_overlay.dart`: Widget overlay konfeti (`confetti` package) yang meledak saat tugas selesai.
2. `lib/widgets/overload_banner_widget.dart` & `StreakCounterWidget`: Banner peringatan merah saat tugas menumpuk (>=3 tugas atau bobot >=35% dalam 3 hari) dan badge api streak `🔥 X Hari` di AppBar.
3. `lib/widgets/task_card.dart`: Kartu tugas interaktif dengan `Dismissible` (Geser kanan = Selesai + Konfeti + Streak, Geser kiri = Hapus dengan konfirmasi), indikator urgensi warna, badge bobot nilai (%), dan progress bar subtask.
4. `lib/screens/home_screen.dart`: Layar utama dengan Bottom Navigation Bar (Tugas, Jadwal Pintar, Asisten AI), filter chips (Semua, Mendesak, Kelompok, Selesai), tombol sinkronisasi e-learning, dan FAB "Input Pintar AI ✨".
5. `lib/screens/smart_task_input_dialog.dart`: Modal dialog tempat mahasiswa menempel pesan dosen dari WA, klik "Analisis dengan AI ✨", lalu form judul, matkul, bobot, dan tanggal terisi otomatis.
 
Setelah komponen dashboard selesai, lanjutkan Tahap 3 untuk melengkapi seluruh layar aplikasi "TugasKu":
1. `lib/screens/task_detail_screen.dart`: Menampilkan rincian tugas, progress bar, daftar checklist subtask, tombol "Pecah Tugas ✨" dengan AI, tambah subtask manual, dan tombol pintas Remind WA jika tugas kelompok.
2. `lib/screens/smart_timeline_screen.dart`: Layar Jadwal Pintar dengan pemilih hari yang menampilkan urutan jadwal kuliah, deadline hari tersebut, serta blok hijau rekomendasi "⚡ Jam Belajar Celah" di sela waktu kosong antarkuliah.
3. `lib/screens/group_task_screen.dart`: Layar kolaborasi tugas kelompok yang menampilkan progres tim, daftar bagian tiap anggota, badge status (Selesai / Sedang Dikerjakan), pembatasan 3 anggota untuk akun Gratis, dan tombol hijau "Remind WA".
4. `lib/screens/ai_chat_screen.dart`: Layar chat Asisten AI lengkap dengan indikator sisa kuota bulanan (`Sisa Kuota: X/5` atau `AI Unlimited`), *quick suggestion chips* ("Tugas apa hari ini?", "Tugas mana yang paling mendesak?"), dan balon percakapan.
5. `lib/screens/elearning_sync_dialog.dart`: Dialog input link `.ics` kalender e-learning dengan laporan jumlah tugas baru dan tugas yang diperbarui.
6. `lib/screens/premium_screen.dart`: Bottom sheet / layar Paywall membandingkan paket Gratis vs Premium (Rp10.000/bulan) beserta simulasi aktivasi langganan melalui Cloud Functions dan Cloud Firestore.
7. `lib/screens/auth_screen.dart`: Login dan register menggunakan Firebase Authentication dengan pembuatan profil mahasiswa di Firestore.
8. `lib/main.dart`: Entry point utama yang menginisialisasi Firebase, Firebase Authentication, NotificationService, MultiProvider, dan menjalankan `TugasKuApp`.
9. Pastikan seluruh service, provider, Cloud Functions, Security Rules, loading state, error state, empty state, dan navigasi terintegrasi serta aplikasi berhasil compile.
```

---

## 🛠️ Prompt Tambahan untuk Debugging / Polish di Antigravity
Jika setelah kode di-generate kamu ingin menambahkan autentikasi login/register atau payment gateway, gunakan prompt lanjutan ini:

* **Prompt Tambah Layar Login & Register Firebase**:
  > *"Tolong tambahkan `lib/screens/auth_screen.dart` untuk Login dan Register mahasiswa menggunakan Firebase Authentication email & password, simpan Nama Lengkap dan Nama Kampus ke `profiles/{userId}` di Cloud Firestore saat registrasi, lalu arahkan otomatis ke `HomeScreen` jika user sudah login."*

* **Prompt Integrasi Pembayaran QRIS / Midtrans Rp10.000/bulan**:
  > *"Tolong buatkan Firebase Callable Cloud Function untuk membuat transaksi pembayaran langganan TugasKu Premium sebesar Rp10.000 menggunakan QRIS/Midtrans Snap, validasi webhook di server, lalu ubah `is_premium = true` dan `premium_expiry` di `profiles/{userId}` Cloud Firestore. Jangan menyimpan secret key di aplikasi Flutter."*
