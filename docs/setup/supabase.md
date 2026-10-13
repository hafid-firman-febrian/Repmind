# Setup Supabase (lokal)

## Sekali saja

1. Pasang Supabase CLI: `brew install supabase/tap/supabase`
2. Nyalakan Docker Desktop: `open -a Docker`, lalu tunggu sampai `docker info` berhasil.
3. Dari root repo, jalankan `supabase start`. Catat `API URL` dan `Publishable key`.
4. Salin config app: `cp env/example.json env/dev.json`, lalu isi:
   - `SUPABASE_URL`:
     - `http://127.0.0.1:54321` untuk simulator iOS.
     - `http://10.0.2.2:54321` untuk emulator Android. Emulator tidak bisa mengakses `127.0.0.1` milik Mac.
   - `SUPABASE_PUBLISHABLE_KEY`: nilai `Publishable key` dari langkah 3.

## Sehari-hari

| Perintah                           | Fungsi                                                           |
| ---------------------------------- | ---------------------------------------------------------------- |
| `supabase start` / `supabase stop` | Menyalakan atau mematikan Supabase lokal                         |
| `supabase migration new <nama>`    | Membuat file migration baru di `supabase/migrations/`            |
| `supabase db reset`                | Menjalankan ulang semua migration dari nol (data lokal terhapus) |
| `supabase test db`                 | Menjalankan test pgTAP di `supabase/tests/`                      |
| `supabase status`                  | Menampilkan ulang URL dan key                                    |

Studio lokal (UI database) tersedia di `http://127.0.0.1:54323`.

## Edge Functions dan Gemini

1. Salin `supabase/functions/.env.example` ke `supabase/functions/.env`, lalu isi `GEMINI_API_KEY` dengan API key dari Google AI Studio. File ini di-gitignore.
2. Jalankan `supabase functions serve`. Perintah ini menyalakan edge runtime dan otomatis membaca `supabase/functions/.env`.
3. Test function: `deno test --allow-all supabase/functions/`. Deno dipasang dengan `brew install deno`.

## Akun demo

`supabase db reset` menjalankan `supabase/seed.sql`, yang membuat akun `demo@repmind.dev` dengan password `repmind-demo`. Profilnya sudah onboarding (Build muscle, Intermediate, 4 hari, dumbbell dan bench) dan belum punya plan. Akun ini hanya ada di lokal.

## Menjalankan app

```bash
flutter run --dart-define-from-file=env/dev.json
```
