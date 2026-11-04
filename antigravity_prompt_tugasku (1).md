# 🚀 Master Prompt Antigravity — Proyek TugasKu (Sesuai Project Charter Kelompok 6)

Dokumen ini telah **diperbarui secara menyeluruh** agar **100% sesuai dengan isi presentasi `PROJECT CHAPTER KELOMPOK 6.pdf` (BM - 5A Kewirausahaan)**—mulai dari fitur spesifik (*Integrasi i-Cal `.ics`*, *Unified Timeline + Conflict Detection*, *Auto Time Blocking*, *Gemini AI Smart Text Input*, *Group & Deliverables + Activity History*), desain **Dark Mode UI** seperti pada mockup Slide 10 (*"Hi, Remanu"*, kartu ringkasan *Tugas Hari Ini* & *Proyek Kelompok*), hingga opsi arsitektur Web/Mobile.

---

## 💡 Pilih Prompt Sesuai Target Build Kamu di Antigravity

Di dalam dokumen ini saya sediakan **3 jenis Master Prompt** yang bisa langsung kamu *copy-paste* ke Antigravity:
1. **PROMPT A — Web App & Mobile Cross-Platform (Flutter Web/Mobile + Supabase / Firebase)**: Membangun aplikasi **TugasKu** lengkap dengan desain **Dark UI** persis seperti screenshot Slide 10 pada PPT, mencakup semua fitur Project Charter + fitur lanjutan (Streak, Konfeti, Remind WA, Kuota Freemium).
2. **PROMPT B — Modern Full-Stack Web App (Next.js / React + Tailwind CSS + Supabase)**: Jika yang kamu maksud *"pembuatan web-nya"* adalah aplikasi berbasis Web murni (berjalan di browser desktop & HP dengan sangat cepat dan mudah di-deploy ke Vercel/Cloud VPS `cepatcloud.id`).
3. **PROMPT C — Interactive Product Landing Page + Web Showcase Project Charter**: Jika kamu juga butuh halaman depan (*Landing Page*) web promosi **TugasKu** yang menampilkan fitur, demo aplikasi, profil tim Kelompok 6 (Remano, Novansya, Riviera), timeline 4 minggu, dan tabel anggaran Rp754.000.

---

## 1. PROMPT A: MASTER PROMPT APLIKASI TUGASKU (FLUTTER WEB & MOBILE — SESUAI PROJECT CHARTER + DARK UI SLIDE 10)

*Salin seluruh blok di bawah ini dan tempelkan ke Antigravity:*

```markdown
Act as a Principal Flutter Engineer & Full-Stack Cloud Architect. Build a complete, production-ready, responsive Cross-Platform Web & Mobile application using **Flutter** called **"TugasKu"** (Asisten Deadline & Produktivitas Mahasiswa), strictly following the specifications from **Project Charter Kelompok 6 (BM - 5A Kewirausahaan)**.

---

### 1. IDENTITAS PROYEK & DESAIN UI/UX (MENGACU PADA MOCKUP SLIDE 1 & SLIDE 10)
- **Nama Aplikasi**: TugasKu (Logo perisai buku & centang merah-emas, dengan aksen gradien ungu-biru `#7C3AED` ke `#2563EB` dan Dark Mode Surface).
- **Tema Utama (Dark Mode First - Sesuai Screenshot Slide 10)**:
  - Background utama: Deep Dark `#0F0F12` / `#121216`
  - Surface / Card: Dark Elevated `#1C1C22` dengan border tipis `#2A2A35` dan radius `16px`
  - Aksen Primer: Vibrant Purple `#8B5CF6` & Amber/Orange `#F59E0B` (untuk highlight bar bawah kartu & indikator streak)
  - Teks Primer: `#FFFFFF`, Teks Sekunder: `#9CA3AF`
  - Font: `Plus Jakarta Sans` atau `Inter`
- **Header Dashboard (Persis Slide 10)**:
  - Kiri: Avatar inisial bulat berwarna coklat/amber (`R`), diikuti sapaan **"Hi, [Nama User]"** (contoh: *"Hi, Remanu"*) dan subteks status streak & tanggal: *"Mulai streakmu hari ini · Senin, 26 Okt"* beserta badge api `🔥 X Hari`.
  - Kanan: Tombol ikon lonceng notifikasi bulat dengan border halus.
- **Summary Cards Row (2 Kolom Bersebelahan Persis Slide 10)**:
  - **Kartu 1 ("Tugas Hari Ini")**: Ikon jam/timer di kanan atas, angka besar jumlah tugas hari ini (misal `0` atau `4`), dan garis aksen kuning/amber di bagian bawah kartu.
  - **Kartu 2 ("Proyek Kelompok")**: Ikon grup di kanan atas, angka besar jumlah proyek kelompok aktif, serta badge kecil di bagian bawah: `📈 X subtugas` dengan teks warna oranye/merah.
- **Responsive Web & Mobile Layout**:
  - Jika dibuka di layar **Mobile (< 768px)**: Menggunakan `BottomNavigationBar` (Dashboard, Unified Timeline, Group & Deliverables, AI Assistant).
  - Jika dibuka di layar **Web Desktop (>= 768px)**: Menggunakan `NavigationRail` / Sidebar kiri dengan layout grid proporsional.

---

### 2. RUANG LINGKUP FITUR UTAMA (SESUAI SLIDE 2, 3, & 4 PROJECT CHARTER)

#### A. FITUR 1: INTEGRASI i-CAL (`.ics` SCHEDULE & AUTO-SYNC)
- Mahasiswa dapat menempelkan URL ekspor kalender `.ics` dari E-Learning kampus (Moodle / Canvas / Google Classroom) atau mengunggah file `.ics` secara lokal.
- **Local & Cloud `.ics` Parser**:
  - Mem-parsing blok `BEGIN:VEVENT` hingga `END:VEVENT` (mengekstrak `UID`, `SUMMARY`, `DESCRIPTION`, `DTSTART`, `DTEND`/`DUE`, dan `LOCATION`).
  - **Deduplikasi Cerdas**: Menggunakan `external_uid` agar tugas/jadwal yang sama tidak pernah dobel saat disinkronkan ulang.
  - **Auto-Update**: Jika dosen mengubah jam/tanggal deadline di E-Learning, sistem otomatis memperbarui deadline di database dan menghitung ulang prioritasnya.

#### B. FITUR 2: UNIFIED TIMELINE & DETEKSI KONFLIK
- Menyatukan **Jadwal Kuliah Resmi**, **Agenda Pribadi**, dan **Deadline Tugas** dalam satu garis waktu visual (*Unified Timeline*) harian & bulanan (seperti tampilan kalender + jadwal per jam di Slide 3).
- **Conflict Detection (Deteksi Bentrok Otomatis)**:
  - Sistem memeriksa apakah ada jadwal kuliah, agenda pribadi, atau tenggat waktu yang saling tumpang tindih (*overlapping time ranges*).
  - Jika terdeteksi bentrok, tampilkan badge peringatan merah **"⚠️ Konflik Jadwal Terdeteksi"** pada item timeline beserta saran penyesuaian waktu.
- **Pengelompokan Prioritas Otomatis**:
  - Setiap tugas dihitung skor prioritasnya secara otomatis dari kombinasi **Sisa Waktu Deadline** dan **Bobot Nilai (%)**:
    `Skor = (Bobot * 10) + (1000 / (Sisa_Jam + 0.5))`
  - Dilengkapi **Overload Warning Banner** jika terdapat `>= 3 tugas` atau total bobot `>= 35%` dalam 3 hari ke depan.
  - Mendukung gestur **Swipe Kanan = Selesai (memicu animasi Konfeti 🎉 & tambah Streak)** dan **Swipe Kiri = Hapus**.
  - Pengingat bertingkat otomatis: **H-3**, **H-1**, dan **3 jam sebelum deadline**.

#### C. FITUR 3: AUTO TIME BLOCKING (REKOMENDASI WINDOW BELAJAR AI)
- Algoritma menganalisis celah waktu kosong (*free time gaps*) di antara jadwal kuliah resmi dan agenda pribadi pengguna pada hari tersebut.
- Jika terdapat celah kosong `>= 60 menit`, sistem secara otomatis menghasilkan blok rekomendasi **"⚡ Auto Time Block: Window Belajar"** di dalam Unified Timeline.
- Rekomendasi belajar ini secara cerdas memilih tugas yang memiliki **skor prioritas tertinggi / bobot terbesar** yang belum selesai, lengkap dengan estimasi durasi belajar (misal 45–90 menit) dan preferensi waktu produktif mahasiswa.

#### D. FITUR 4: SMART TEKS INPUT (GEMINI AI-PARSER & PECAH TUGAS)
- **Smart Task Input (AI-Parser)**:
  - Mahasiswa cukup menempelkan teks pengumuman acak dari grup WhatsApp atau email dosen (contoh: *"Kumpul laporan praktikum sistem basis data Jumat jam 10 pagi, bobot 20% ya"*).
  - Menggunakan **Google Gemini API (`gemini-1.5-flash` JSON schema mode)** + **Local Indonesian NLP Fallback Parser** untuk mengurai teks menjadi data terstruktur:
    1. `title` (Judul Tugas)
    2. `description` (Deskripsi / Instruksi)
    3. `deadline` (Tenggat Tanggal & Jam)
    4. `course_tag` (Tag Mata Kuliah)
    5. `weight_percentage` (Bobot Nilai %)
- **Pecah Tugas (AI Task Breakdown)**:
  - Memecah tugas besar menjadi 4–5 langkah kecil (*subtasks* / *deliverables*) yang langsung bisa dicentang satu per satu.
- **Asisten AI Kontekstual**:
  - Chat asisten tempat mahasiswa bertanya *"tugas apa hari ini?"* atau *"kapan waktu belajar terbaik minggu ini?"*, dijawab berdasarkan data riil pengguna.

#### E. FITUR 5: GROUP AND DELIVERABLES (KOLABORASI KELOMPOK, LOG AKTIVITAS & REMIND WA)
- Ruang khusus untuk proyek/tugas kelompok (seperti tabel monitoring di Slide 4):
  - **Monitoring Deliverable per Anggota**: Tabel/daftar yang menampilkan `Nama Deliverable/Subtugas`, `Progress Bar`, `Tipe` (Planning/Development/Report), `Status` (Completed/In Progress/Pending), `Priority` (1-Critical, 2-High, 3-Medium), dan `Owner/PIC` (Nama anggota & Nomor WA).
  - **Progress Bar Transparan & Donut Chart Persentase**: Menampilkan persentase penyelesaian tim secara *real-time* (misal `72% Completed`).
  - **History Aktivitas Tugas (Activity Log)**: Mencatat riwayat transparan setiap kali anggota menyelesaikan subtugas, mengubah status, atau menambahkan deliverable (contoh: *"Riviera menyelesaikan 'Integrasi Gemini AI' · 10 menit lalu"*).
  - **Tombol "Remind WA"**: Tombol sekali klik di samping anggota yang belum menyelesaikan bagiannya, langsung membuka WhatsApp (`https://wa.me/628xxx?text=...`) dengan pesan pengingat sopan & otomatis berisi nama tugas, mata kuliah, dan tenggat waktu.

#### F. FITUR 6: MODEL FREEMIUM & KUOTA
- **Gratis**: Fitur dasar, kuota AI 5x/bulan, kelompok maksimal 3 anggota.
- **Premium (Rp10.000/bulan)**: AI tanpa batas, anggota kelompok tanpa batas, statistik beban kerja penuh, dan Asisten AI 24/7.

---

### 3. ARSITEKTUR BACKEND & DATABASE (SUPABASE / FIREBASE READY)
Gunakan **Supabase (PostgreSQL + Realtime + Auth + RLS)** (atau abstraksi repository yang mendukung sinkronisasi instan seperti yang dijelaskan pada arsitektur Cloud di Project Charter):
- Buat file `supabase/schema.sql` lengkap dengan tabel:
  1. `profiles` (id, full_name, email, university, is_premium, current_streak, best_streak, ai_usage_count)
  2. `tasks` (id, user_id, title, description, course_tag, deadline, weight_percentage, priority_score, is_completed, source, external_uid, is_group_task)
  3. `deliverables` / `subtasks` (id, task_id, title, type, status, priority_level, progress_percent, owner_name, owner_phone, is_completed)
  4. `group_activity_logs` (id, task_id, actor_name, action_description, created_at)
  5. `schedules` (id, user_id, title, category ['kuliah' | 'pribadi'], day_of_week, start_time, end_time, room, external_uid)
- Sertakan **Data Dummy Awal (Seed Data)** atas nama **"Remanu"** dan tim **Kelompok 6 (Mochmad Remano Darusatwiko, Muhammad Novansya, Riviera Rafa Andara)** agar saat aplikasi dijalankan pertama kali di Web/Mobile, dashboard, jadwal, dan proyek kelompok langsung tampil hidup dan interaktif tanpa layar kosong.

---

### 4. INSTRUKSI OUTPUT KODE
- Tulis seluruh kode secara **LENGKAP dan UTUH** tanpa ada bagian yang disingkat (`// TODO` atau `...`).
- Pastikan aplikasi dapat langsung dijalankan di **Flutter Web (`flutter run -d chrome`)** maupun Android/iOS.
```

---

## 2. PROMPT B: KHUSUS JIKA INGIN DIBUAT SEBAGAI MODERN WEB APP (NEXT.JS / REACT + TAILWIND + SUPABASE)

*Jika di Antigravity kamu ingin membangun versi **Website Murni (HTML/React/Next.js + Tailwind CSS)** agar langsung bisa dibuka di browser tanpa install SDK Flutter, salin prompt di bawah ini:*

```markdown
Act as a Senior Full-Stack Web Developer. Build a complete, responsive, production-ready Web Application for **"TugasKu"** (Asisten Deadline & Produktivitas Mahasiswa) using **React / Next.js (App Router), TypeScript, Tailwind CSS, Lucide Icons, Canvas Confetti, and Supabase** (with interactive local state fallback pre-loaded with seed data).

### 1. VISUAL DESIGN & UI (STRICTLY MATCHING PROJECT CHARTER SLIDE 1, 3, 4, & 10)
- **Dark Theme Dashboard (Slide 10 Mockup)**:
  - Background: `#0D0D11`, Cards: `#18181F` with `#272732` border, Accent Gradient: Purple `#7C3AED` to Blue `#2563EB`, Highlight Accent: Amber `#F59E0B`.
  - Top Greeting Bar: Avatar circle `R`, Title **"Hi, Remanu"**, Subtitle **"Mulai streakmu hari ini · Senin, 26 Okt"**, Streak badge `🔥 5 Hari`, and Notification bell button.
  - Top Summary Cards:
    1. **Tugas Hari Ini**: Shows count, clock icon, and bottom amber highlight bar.
    2. **Proyek Kelompok**: Shows active group project count, group icon, and `📈 X subtugas` indicator.
- **Navigation**: Responsive Left Sidebar on Desktop and Bottom Navigation Bar on Mobile with 5 menus:
  1. **Dashboard & Tugas** (Prioritas Otomatis, Overload Alert, Swipe/Click Complete with Confetti)
  2. **Unified Timeline & Auto Time-Blocking** (Kalender + Garis Waktu Kuliah, Agenda Pribadi, Deteksi Konflik, & Rekomendasi Window Belajar AI)
  3. **Smart AI Parser (Gemini)** (Tempel pengumuman WA/Email -> Ekstrak Judul, Deskripsi, Tenggat, Bobot %, & Tag Matkul + Fitur Pecah Tugas)
  4. **Group & Deliverables** (Tabel monitoring deliverable per anggota seperti Slide 4: Name, Progress Bar, Type, Status, Priority `1-Critical` / `2-High` / `3-Medium`, Owner, Donut Chart 72%, History Aktivitas, & tombol **Remind WA**)
  5. **i-Cal (`.ics`) Sync & Info Proyek** (Upload file `.ics` atau tempel URL kalender E-Learning Moodle/Classroom + Info Tim Kelompok 6 & Paket Premium Rp10.000/bln).

### 2. CORE FUNCTIONAL REQUIREMENTS TO IMPLEMENT
1. **i-Cal (`.ics`) Parser & Sync**:
   - Provide both a URL input and a real `.ics` file upload/sample loader that parses `VEVENT` entries, deduplicates by `UID`, and populates the Unified Timeline and Tasks list automatically.
2. **Unified Timeline + Conflict Detection + Auto Time Blocking**:
   - Render a visual daily/weekly time-grid (07:00 to 21:00).
   - Highlight overlapping events in red as **"⚠️ Konflik Jadwal"**.
   - Automatically detect empty gaps `>= 60 mins` between classes and insert green/purple dashed cards: **"⚡ Auto Time Block: Window Belajar [Nama Tugas Prioritas]"**.
3. **Gemini AI Smart Text Input**:
   - Textarea where users paste messy WhatsApp announcements from lecturers.
   - Integrate Gemini API (`gemini-1.5-flash`) + instant built-in Indonesian NLP regex parser fallback that extracts Title, Course Tag, Deadline, Grade Weight (%), and generates 4 subtasks.
4. **Group & Deliverables Workspace (Matching Slide 4 Visual)**:
   - Interactive table & cards showing deliverables assigned to team members (**Mochmad Remano Darusatwiko**, **Muhammad Novansya**, **Riviera Rafa Andara**).
   - Interactive status & progress sliders, real-time Donut Chart showing overall completion percentage, transparent **Activity History Log**, and a working **"Remind WA"** button that opens `https://wa.me/628xxx?text=...` with a formatted Indonesian reminder.

### 3. DELIVERABLE RULES
- Write clean, modular, complete code with zero placeholders or `// TODO` comments.
- Pre-populate realistic university tasks, schedules, and Kelompok 6 deliverables so every tab is immediately interactive and visually impressive.
```

---

## 3. PROMPT C: JIKA INGIN MEMBUAT WEB SHOWCASE + INTERACTIVE PROTOTYPE PROJECT CHARTER KELOMPOK 6

*Jika tujuan pembuatan web kamu adalah untuk **dipresentasikan di depan dosen/kelas Kewirausahaan (BM - 5A)**—yang menggabungkan Landing Page Project Charter Kelompok 6 + Simulasi Aplikasi TugasKu langsung di dalamnya—gunakan prompt ini:*

```markdown
Build an interactive, modern single-page Web Application & Project Showcase for **"TUGASKU - PROJECT CHARTER KELOMPOK 6 (BM - 5A Kewirausahaan)"** using HTML5, Tailwind CSS, and Vanilla JavaScript (or React).

The website must have two seamless modes accessible from the top navbar:
1. **"📱 Live App Demo (TugasKu Web App)"** — A fully interactive web version of the TugasKu app featuring:
   - Dark Mode Dashboard matching our UI mockup ("Hi, Remanu", "Tugas Hari Ini", "Proyek Kelompok", Streak counter, Confetti on task completion).
   - **Smart Teks Input (Gemini AI-Parser)**: Paste a WhatsApp lecturer message and watch it automatically parse into a structured task (Title, Description, Deadline, Course Tag, Weight %) and break down into subtasks.
   - **Integrasi i-Cal (.ics) & Unified Timeline**: Visual schedule combining official classes, personal agenda, automatic **Conflict Detection**, and **Auto Time Blocking** (recommended study windows in empty gaps between classes).
   - **Group & Deliverables Monitor**: Interactive table with Progress Bars, Type (Planning/Development), Status, Priority (1-Critical, 2-High, 3-Medium), Owner, 72% Donut Chart, Activity History Log, and a working **"Remind WA"** button.

2. **"📊 Project Charter & Business Plan (Kelompok 6)"** — A sleek presentation section showcasing our entrepreneurship charter:
   - **Hero & Scope Arsitektur**: 1. Front-End (Flutter Mobile-First), 2. Back-End (Firebase/Supabase Realtime + Local `.ics` Parser), 3. Server (Scalable Cloud VPS / GCP).
   - **Timeline 1 Month (Week 1 to Week 4 Interactive Roadmap)**:
     - Week 1: Requirement Analysis & Wireframing, Project Planning.
     - Week 2: UI/UX Design & Prototypes, Flutter App Architecture, Gemini API Task Parser, Initial AI Integration.
     - Week 3: UI/UX Design Finalization, Auth & Database Setup, Auto Time-Blocking AI, iCal Integration, Initial Feature Testing.
     - Week 4: Final Design Review, System Integration, Group Collaboration Features, End-to-End Testing & Bug Fixing, Beta Testing & Optimization, App Store & Play Store Release v1.0.
   - **Team Project (Kelompok 6)**:
     - **Mochmad Remano Darusatwiko (2403421006)** — Project Manager & Front-End Developer (Arsitektur Flutter, implementasi UI/UX, koordinasi jadwal & tugas tim).
     - **Muhammad Novansya (2403421033)** — Back-End Developer & Database Engineer (Manajemen Database, autentikasi, API, dan persiapan infrastruktur server produksi).
     - **Riviera Rafa Andara (2403421022)** — AI & Integration Specialist (Pengembangan parser `.ics`, integrasi Gemini AI, serta logika perhitungan progress kelompok).
   - **Budget & Rencana Anggaran Go-Live (Total Rp754.000)**:
     - Google Play Console: Registrasi developer Android ($25 USD / ~Rp400.000)
     - Cloud Hosting / Web API (`cepatcloud.id`): Server API & Cloud Storage (Rp200.000/tahun atau Rp20.000–Rp50.000/bulan)
     - Gemini AI API (Google AI Studio): Smart Task Input Pay-As-You-Go / Flash-Lite (Rp54.000/1M Token)
     - Database Cloud (Firebase/Supabase): Penyimpanan Apps Database (Rp100.000/bulan)
     - **Total Biaya**: **Rp754.000**

Design it with a premium purple-to-blue gradient theme (`#6D28D9` to `#1E40AF`) combined with the dark mobile mockup theme (`#121216`). Make every button, tab, parser, and table 100% functional!
```