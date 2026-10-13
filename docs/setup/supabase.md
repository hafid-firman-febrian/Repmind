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

## Menjalankan app

```bash
flutter run --dart-define-from-file=env/dev.json
```
