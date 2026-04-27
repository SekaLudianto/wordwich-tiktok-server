# Deploy ke Render.com (gratis, tanpa deposit)

## ⚠️ Catatan penting Free Tier Render

- **Sleep setelah 15 menit idle** → request pertama setelah sleep bisa lambat ~30 detik. Selama TikTok live aktif, koneksi WebSocket akan keep-alive jadi seharusnya tidak sleep. Tapi kalau TikTok-nya disconnect, server bisa sleep.
- **512MB RAM** — cukup untuk 1–2 stream paralel.
- **100GB bandwidth/bulan** — audio streaming akan cepat habis kalau live tiap hari.
- **IP datacenter Render bisa diblok YouTube** ("Sign in to confirm you're not a bot") → siapkan `cookies.txt` (lihat step 4).

## 1. Push ke GitHub

Render butuh repo Git. Dari folder `frontend/server`:

```powershell
git init
git add .
git commit -m "Initial deploy config"
```

Buat repo baru di https://github.com/new (nama bebas, mis. `wordwich-tiktok-server`, **private** disarankan), lalu:

```powershell
git branch -M main
git remote add origin https://github.com/USERNAME/wordwich-tiktok-server.git
git push -u origin main
```

> Pastikan `cookies.txt` & `node_modules` ter-ignore (sudah ada di `.gitignore`).

## 2. Buat Web Service di Render

1. Sign up / login di https://render.com (boleh pakai GitHub OAuth).
2. Klik **New +** → **Blueprint**.
3. Connect GitHub repo `wordwich-tiktok-server`.
4. Render akan baca `render.yaml` otomatis. Klik **Apply**.

> Kalau kamu push folder `wordwich` lengkap (bukan hanya `server`), edit `render.yaml` dan uncomment `rootDir: frontend/server` sebelum push.

## 3. Set environment variables

Di dashboard service Render → tab **Environment**:

| Key | Value |
|---|---|
| `TIKTOK_USERNAME` | `ahmadsyams.live` (username TikTok kamu) |
| `ALLOWED_ORIGINS` | `https://your-frontend.com` (opsional, kalau frontend di domain lain) |
| `YT_COOKIES` | (paste isi `cookies.txt` — lihat step 4) |

Setelah save, Render akan auto-redeploy.

## 4. Cookies YouTube (sangat disarankan)

IP datacenter Render hampir pasti akan kena rate-limit YouTube. Tanpa cookies, `yt-dlp` akan gagal. Cara dapat cookies:

1. Login YouTube di Chrome.
2. Install ekstensi **"Get cookies.txt LOCALLY"**.
3. Buka https://youtube.com → klik ekstensinya → **Export** → simpan `cookies.txt`.
4. Buka file `cookies.txt` di Notepad → **copy seluruh isi**.
5. Di Render dashboard → Environment → tambah env var `YT_COOKIES` → paste isi file (klik tombol expand untuk multi-line).
6. Save → redeploy.

Entrypoint Docker akan otomatis menulis ke `/app/cookies.txt` saat container start.

> Cookies bisa expired. Kalau `yt-dlp` mulai gagal lagi, refresh `cookies.txt` dan update env var-nya.

## 5. Verifikasi

Setelah deploy sukses (lihat tab **Logs** Render):

- Buka `https://wordwich-tiktok.onrender.com/healthz` → JSON status 200.
- Buka `https://wordwich-tiktok.onrender.com/stream/dQw4w9WgXcQ` → audio mengalir.
- Tab **Logs** harus muncul: `✅ Terhubung ke TikTok @<roomId>`.

## 6. Update frontend

Ganti URL backend di kode frontend:

- `ws://localhost:3000` → `wss://wordwich-tiktok.onrender.com`
- `/stream/<id>` → `https://wordwich-tiktok.onrender.com/stream/<id>` (atau biarkan relatif kalau frontend reverse-proxy)

## 7. Cegah sleep (opsional)

Selama TikTok live aktif, koneksi WS akan mencegah sleep. Tapi kalau mau jaga-jaga:

- Daftar https://uptimerobot.com (gratis).
- Tambah HTTP monitor → URL `https://wordwich-tiktok.onrender.com/healthz` → interval 5 menit.

## 8. Update / Redeploy

Tinggal `git push` — Render auto-deploy karena `autoDeploy: true` di `render.yaml`.

```powershell
git add .
git commit -m "update"
git push
```

## Troubleshooting

| Gejala | Solusi |
|---|---|
| Build gagal di step `pip3 install yt-dlp` | Cek log Render. Biasanya retry sekali sukses. |
| `yt-dlp: Sign in to confirm you're not a bot` | Set `YT_COOKIES` (step 4). |
| TikTok disconnect setelah idle | Free tier sleep — pakai UptimeRobot (step 7) atau upgrade ke paid ($7/bulan). |
| OOM (out of memory) | Hindari multiple stream paralel. Atau upgrade plan. |
| WebSocket 403 | Hapus / perbaiki `ALLOWED_ORIGINS`. |
