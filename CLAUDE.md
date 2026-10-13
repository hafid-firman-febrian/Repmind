# CLAUDE.md

## Project Context

Repmind adalah app fitness Flutter dengan AI coach. Pembedanya dua fitur AI: **AI Workout Generator** (plan mingguan terstruktur dari goal, level, equipment, dan hari per minggu) dan **AI Coach Chat** (streaming, tahu goal dan plan user). Ditambah fitur standar: auth, profil, tracker, dan dashboard.

Ini **proyek portofolio untuk Upwork**. Hasil akhirnya repo GitHub, README, dan video demo. App hanya dijalankan oleh owner (tidak ada rilis ke store atau APK publik). Bahasa UI: Inggris. Satuan: metrik. Light mode saja.

Spec lengkap ada di `docs/superpowers/specs/2026-09-30-repmind-design.md`. **Baca sebelum mengerjakan area yang belum kamu kenal.** Decision log D1–D16 di sana menjelaskan alasan tiap keputusan.

## Tech Stack

- Framework: Flutter (iOS + Android), Dart
- State: Riverpod 3, `Notifier` / `AsyncNotifier` via `@riverpod` (`riverpod_generator`)
- Routing: go_router, dengan redirect lewat fungsi murni `resolveRedirect`
- Backend: Supabase (Auth, Postgres + RLS, Storage, Edge Functions Deno/TypeScript)
- AI: Claude (`claude-opus-5-5`, disimpan di secret `AI_MODEL`), hanya dipanggil dari Edge Functions
- Model: ditulis manual, **tanpa** Freezed atau json_serializable
- Styling: Material 3 dengan token Repmind (`ThemeExtension`), font Barlow dan Barlow Condensed sebagai asset

## Roadmap

Kerjakan satu sub-project sampai skenario demonya jalan, baru lanjut ke berikutnya:

1. Fondasi
2. AI Workout Generator
3. AI Coach Chat
4. Tracker + Dashboard
5. Showcase (README dan video)
6. Opsional: nutrisi, notifikasi, offline

Tiap sub-project punya spec dan plan sendiri di `docs/superpowers/`.

## Key Directories

- `lib/core/` berisi kode yang dipakai lintas feature:
  - `config/`: pembacaan dart-define
  - `supabase/`: provider client
  - `router/`
  - `theme/`: token, `RepmindColors`, `RepmindText`, `RepmindRadius`
  - `errors/`: `AppException`
  - `widgets/`: komponen design system
- `lib/features/<feature>/` punya struktur `presentation/{controllers,states,pages,widgets}`, `application/services`, `domain/models`, dan `data/{data_sources,repositories}`.
- `supabase/` berisi:
  - `migrations/`: satu-satunya cara mengubah schema
  - `functions/`: `_shared/`, `generate-plan/`, `coach-chat/`
  - `tests/`: pgTAP
  - `seed.sql`
- `docs/design/` berisi mockup visual final (target tampilan).
- `docs/setup/` berisi langkah setup Supabase dan Google sign-in.
- `docs/superpowers/` berisi spec dan plan. Folder ini di-gitignore dan hanya ada di mesin owner.
- `env/`: `example.json` di-commit, `dev.json` di-gitignore.

## Commands

- `flutter run --dart-define-from-file=env/dev.json`: jalankan app
- `dart run build_runner watch --delete-conflicting-outputs`: codegen provider Riverpod. Biarkan jalan selama development
- `flutter analyze`: linter
- `flutter test`: tests
- `dart format .`: formatter
- `supabase start` / `supabase stop`: Supabase lokal (butuh Docker)
- `supabase migration new <nama>`: buat file migration baru
- `supabase db reset`: jalankan ulang semua migration dan seed di lokal
- `supabase test db`: test pgTAP (RLS, trigger)
- `supabase functions serve`: jalankan Edge Functions di lokal
- `deno test --allow-all supabase/functions/`: test Edge Functions
- `supabase db push` / `supabase functions deploy <nama>`: kirim ke project cloud. **Tanya dulu sebelum menjalankan.**

---

## How I Want You to Work

### Before Coding

- Baca `CLAUDE.md`, spec, dan plan sub-project yang sedang dikerjakan
- Kalau tidak yakin, tanya. Jangan berasumsi
- Untuk pekerjaan yang kompleks, susun rencana dan konfirmasi dulu

### While Coding

- Kode lengkap dan bisa jalan, tanpa placeholder atau TODO
- Sederhana dan mudah dibaca, bukan "pintar"
- Ikuti pola yang sudah ada di codebase
- Kerjakan per layer: data → domain → application → presentation. Verifikasi tiap layer sebelum lanjut

### After Coding

- Jalankan `flutter analyze` dan `flutter test` setelah **tiap layer**, bukan hanya di akhir. Untuk migration, jalankan `supabase test db`. Untuk function, jalankan `deno test`
- Ringkas apa yang berubah dan kenapa

### Git

- `main` berisi versi stabil, `dev` tempat integrasi
- Satu branch fitur per sub-project dibuat dari `dev` (misalnya `feat/workout-generator`), lalu di-merge ke `dev` secara lokal dengan `git merge --no-ff`
- `dev` di-merge ke `main` secara lokal dengan `git merge --no-ff` setelah satu sub-project selesai dan skenario demonya berjalan
- Conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`
- **Jangan tambahkan `Co-Authored-By` atau atribusi Claude apa pun** di pesan commit maupun deskripsi PR
- Jangan pernah meng-commit atau mem-push isi `docs/superpowers/`
- Jangan push atau membuat PR tanpa diminta

---

## Aturan Keras

Aturan di bawah **tidak akan tertangkap `flutter analyze`**. Kalau dilanggar, kodenya terlihat benar padahal salah.

### 1. App tidak pernah memanggil AI secara langsung

Tidak ada API key AI, prompt, atau SDK LLM di kode Flutter. Semua AI lewat Edge Functions. `ANTHROPIC_API_KEY` hanya ada di Supabase secrets, tidak di `env/`, tidak di repo, dan tidak di dart-define.

### 2. Setiap tabel wajib punya RLS dan test pgTAP

`alter table … enable row level security` dan policy-nya ditulis di migration yang sama dengan `create table`. Tiap tabel baru punya test pgTAP yang membuktikan user A tidak bisa membaca atau mengubah data user B. Tabel tanpa RLS bisa dibaca siapa pun yang memegang publishable key (dulu disebut anon key).

### 3. Schema hanya berubah lewat migration

Buat file dengan `supabase migration new`. Jangan ubah schema lewat dashboard. Jangan mengedit migration yang sudah di-push ke cloud. Kalau perlu perubahan, buat migration baru.

### 4. Edge Function memakai JWT user, bukan service role

Buat Supabase client di function dengan meneruskan header `Authorization` dari request, supaya RLS tetap berlaku. Service role hanya boleh dipakai kalau memang tidak ada cara lain, dan alasannya ditulis di komentar.

### 5. Output AI tidak pernah dipercaya mentah

JSON dari Claude divalidasi dengan zod sebelum disimpan: ID latihan harus ada di katalog, dan jumlah hari harus sama dengan `days_per_week`. Simpan plan lewat satu Postgres function (satu transaksi), jangan lewat beberapa insert terpisah.

### 6. UI tidak menyentuh Supabase secara langsung

Widget → controller → service/repository → Supabase. Repository diakses lewat provider, supaya bisa di-override dengan versi palsu di test.

### 7. Exception pihak ketiga berhenti di repository

`AuthException`, `PostgrestException`, `StorageException`, `SocketException`, dan error dari Google Sign-In diubah menjadi `sealed class AppException` (`lib/core/errors/`) di repository. UI hanya mengenal `AppException`.

### 8. Enum ke database lewat `dbValue`, bukan `values.byName`

Nilai di Postgres memakai snake_case (`'lose_weight'`), sedangkan enum Dart memakai camelCase (`loseWeight`). `FitnessGoal.values.byName(json['goal'])` akan melempar error saat runtime. Pakai field `dbValue` dan fungsi `fromDb`.

### 9. `Notifier` / `AsyncNotifier`, bukan `StateNotifier`

`StateNotifier` ada di `package:flutter_riverpod/legacy.dart`. Jangan dipakai, dan jangan impor `legacy.dart`.

### 10. Business logic di services atau fungsi murni

Aturannya tidak diletakkan di widget atau repository. Contohnya `resolveRedirect`, perhitungan BMI, dan validasi onboarding. Controller hanya menyambungkan service ke UI.

### 11. Tidak ada nilai visual yang di-hardcode di widget

Warna, ukuran font, dan radius diambil dari theme (`Theme.of(context)`, `RepmindColors`, `RepmindText`, `RepmindRadius`). Tidak boleh ada `Color(0xFF…)` atau `TextStyle(fontSize: …)` langsung di widget, karena satu perubahan token harus berlaku di seluruh app.

---

## Model Dart (manual)

```dart
class Profile {
  const Profile({required this.id, required this.goal, required this.daysPerWeek});

  final String id;
  final FitnessGoal? goal;
  final int? daysPerWeek;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        goal: FitnessGoal.fromDb(json['goal'] as String?),
        daysPerWeek: json['days_per_week'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'goal': goal?.dbValue,
        'days_per_week': daysPerWeek,
      };
}

enum FitnessGoal {
  loseWeight('lose_weight'),
  buildMuscle('build_muscle'),
  stayFit('stay_fit');

  const FitnessGoal(this.dbValue);
  final String dbValue;

  static FitnessGoal? fromDb(String? value) =>
      value == null ? null : values.firstWhere((goal) => goal.dbValue == value);
}
```

- Field `final` dan `const` constructor. Key JSON memakai snake_case, sesuai kolom database.
- `toJson` hanya berisi kolom yang boleh ditulis oleh app (tanpa `id`, `created_at`, `updated_at`).
- `copyWith` hanya ditambahkan ke model yang diedit di UI.
- `numeric` dari Postgres bisa datang sebagai `int` atau `double`, jadi baca dengan `(json['weight_kg'] as num?)?.toDouble()`.
- State yang punya beberapa kondisi memakai `sealed class`.

---

## Design System: Terkunci

Visual **Repmind** sudah disetujui owner. Target tampilannya ada di `docs/design/visual-direction.png`, dan detailnya di spec §6. **Jangan ubah token, font, atau perilaku navbar tanpa bertanya.**

- **Warna dan perannya:**
  - lime `#D4FF3A`: latihan dan aksi (kartu hero, tombol utama, hari selesai). Hanya sebagai isian, tidak pernah sebagai teks atau ikon di atas surface terang
  - limeInk `#4D7000`: teks dan ikon keluarga lime di atas surface terang
  - violet `#6C4DFF`: semua yang dibuat AI. violetTint `#EFEBFF`, violetLine `#DCD4FF`
  - orange `#FF6B1A`: progres (streak, statistik). orangeMark `#F25A0F` untuk bar chart
  - background `#F6F7F5`, surface `#FFFFFF`, surfaceSunken `#EEF0EC`, line `#E3E5E1`
  - ink `#1B1E24`, muted `#6B6F78`, chartMuted `#8E929A`, danger `#C8281C`
- **Teks di atas warna:** `ink` di atas lime dan orange, putih di atas violet.
- **Isian lime** diberi garis tepi 1px `ink` 8% (`RepmindColors.limeEdge`) supaya batasnya terlihat.
- **Jenis latihan** (Upper, Lower, Core, Full body) tidak punya warna sendiri, dan dibedakan lewat teks.
- **Navbar (`RepmindNavBar`):**
  - Mengambang, putih semi-transparan dengan blur (`BackdropFilter`), dan hanya berisi ikon.
  - Tab aktif berupa kotak 44px di dalam bar: Home dan Plan lime, Coach violet, Progress orange.
  - Baru dipasang di sub-project 2.
- **Font:** Barlow Condensed untuk judul dan angka, Barlow untuk teks, disertakan sebagai asset (tanpa `google_fonts`). Teks untuk style `headline`, `title`, `section`, dan `label` ditulis uppercase. Skala tipografi ada di spec §6.2.
- **Radius:** 16 untuk kartu hero, 14 untuk kartu, 12 untuk baris list, tombol, dan field, 8 untuk badge dan chip, 20 untuk navbar, dan 14 untuk tab aktif.
- **Ikon sparkle violet** (`Icons.auto_awesome_rounded`) menandai semua yang dibuat AI.

---

## Do Not

- **Jangan bangun fitur di luar scope sub-project yang sedang dikerjakan.** Di luar scope global (spec §2 dan §7.9): konfirmasi email, lupa password, hapus akun, dark mode, i18n, satuan imperial, rate limiting, App Check, dan rilis ke store.
- **Jangan buat feature di luar roadmap.** Feature yang direncanakan: `auth`, `onboarding`, `profile`, `home`, `plan`, `coach`, `tracker`, `progress`.
- **Jangan pasang package di luar daftar Dependencies.**
- **Jangan commit secret.** `env/dev.json` dan API key tidak boleh masuk git.
- **Jangan tinggalkan placeholder, TODO, atau kode yang dikomentari-mati.**
- **Jangan bekerja di luar scope task.**
- Jangan berasumsi. Tanya kalau tidak jelas.

---

## Dependencies

Pasang lewat `flutter pub add` (atau `flutter pub add --dev`). Jangan menulis angka versi secara manual.

| Sub-project | App | Dev |
| --- | --- | --- |
| 1 | `flutter_riverpod`, `riverpod_annotation`, `go_router`, `supabase_flutter`, `google_sign_in`, `image_picker` | `build_runner`, `riverpod_generator`, `mocktail` |
| 3 | `flutter_markdown_plus` | |
| 4 | `fl_chart` | |

Edge Functions: `@anthropic-ai/sdk`, `zod`, `@supabase/supabase-js` (import dengan prefix `npm:` / `jsr:`).

**Jangan pasang tanpa diminta:** `freezed`, `json_serializable`, `flutter_dotenv`, `google_fonts`, `dio`, `get_it`, `provider`, `flutter_bloc`, `hive`, dan SDK LLM apa pun di sisi Flutter.

---

## Code Style

- File: snake_case. Class: PascalCase.
- Konstanta ditulis sebagai `static const` di dalam class (`RepmindRadius.card`), bukan dengan prefix `k`.
- Nama model tanpa suffix: `Profile`, bukan `ProfileModel`. Nama file tetap `profile_model.dart`.
- Nama provider dibuat otomatis oleh `@riverpod`. Jangan menulisnya manual.
- Copy UI dalam bahasa Inggris. Dokumen di `docs/` dalam bahasa Indonesia, dengan istilah teknis tetap bahasa Inggris.
- Nama variabel deskriptif.

### Komentar

**Kode sumber ditulis tanpa komentar**, termasuk doc comment `///`. Aturan ini berlaku untuk Dart, SQL migration dan test pgTAP, TypeScript di Edge Functions, Kotlin/Swift, dan script. Nama yang jelas dan fungsi kecil menggantikan komentar. Kalau ada keputusan yang alasannya tidak terbaca dari kode, tulis alasannya di spec, plan, atau pesan commit.

File konfigurasi (`.gitignore`, YAML, TOML, xcconfig) boleh berisi komentar singkat, misalnya instruksi setup.
