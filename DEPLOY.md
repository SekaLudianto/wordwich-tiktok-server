# Deploy ke Fly.io

Server ini dirancang untuk dideploy 24/7 di Fly.io (Docker, region Singapore).

## 1. Prasyarat

- Akun Fly.io (sign-up di https://fly.io — butuh kartu kredit, tidak ditagih jika di bawah free allowance).
- Fly CLI (`flyctl`).

### Install Fly CLI di Windows (PowerShell)

```powershell
iwr https://fly.io/install.ps1 -useb | iex
```

Lalu restart terminal dan login:

```powershell
fly auth login
```

## 2. Launch (sekali saja)

Dari folder `frontend/server`:

```powershell
fly launch --no-deploy --copy-config --name wordwich-tiktok --region sin
```

- `--copy-config` = pakai `fly.toml` yang sudah ada di folder ini.
- Ganti `wordwich-tiktok` jika nama sudah dipakai orang.
- Jangan setujui Postgres/Redis (tekan `N`).

## 3. Set secrets

Wajib:

```powershell
fly secrets set TIKTOK_USERNAME=usernamekamu
```

Opsional — batasi origin frontend:

```powershell
fly secrets set ALLOWED_ORIGINS="https://your-frontend.vercel.app"
```

Opsional tapi **sangat disarankan** — cookies YouTube biar yt-dlp tidak diblok IP datacenter:

1. Login YouTube di Chrome, install extension "Get cookies.txt LOCALLY".
2. Export cookies dari youtube.com → simpan sebagai `cookies.txt` (jangan commit ke git).
3. Inject ke Fly:
   ```powershell
   fly secrets set YT_COOKIES="$(Get-Content cookies.txt -Raw)"
   ```
   Entrypoint Docker akan menulisnya ke `/app/cookies.txt` saat startup.

## 4. Deploy

```powershell
fly deploy
```

Tunggu sampai build & rollout selesai.

## 5. Verifikasi

```powershell
fly logs
fly status
```

Buka browser:

- `https://wordwich-tiktok.fly.dev/healthz` → harus 200 OK + JSON status.
- `https://wordwich-tiktok.fly.dev/stream/dQw4w9WgXcQ` → audio mengalir (kalau yt-dlp & cookies OK).

## 6. Update frontend

Di kode frontend, ganti URL backend:

- WebSocket: `ws://localhost:3000` → `wss://wordwich-tiktok.fly.dev`
- Stream: `/stream/<id>` → `https://wordwich-tiktok.fly.dev/stream/<id>` (atau biarkan relatif kalau frontend di domain yang sama).

## 7. Troubleshooting

| Gejala | Solusi |
|---|---|
| `yt-dlp ERROR: Sign in to confirm you're not a bot` | Set `YT_COOKIES` (lihat step 3). Refresh cookies tiap beberapa minggu. |
| OOM / out of memory | Naikkan memory di `fly.toml` jadi `1024mb`, lalu `fly deploy`. |
| TikTok disconnect terus | Cek `fly logs`. Pastikan `min_machines_running = 1` di `fly.toml`. Free allowance Fly = 3 shared VM. |
| WebSocket 403 | `ALLOWED_ORIGINS` salah. Hapus secret atau set ke `*` untuk testing: `fly secrets unset ALLOWED_ORIGINS`. |
| Mau ganti TikTok username | `fly secrets set TIKTOK_USERNAME=usernamebaru` lalu `fly apps restart wordwich-tiktok`. |

## 8. Update / Redeploy

Setiap push perubahan:

```powershell
fly deploy
```
