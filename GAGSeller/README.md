# GAG Seller — Modular

Versi refactor dari `Lua Script/GAGSeller.lua` (single-file). **File asli tidak diubah.**
Fungsionalitas identik, hanya dipecah jadi modul agar mudah di-maintain.

## Cara menjalankan (via GitHub)

Tidak perlu copy file ke executor. Cukup jalankan:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/main/GAGSeller/init.lua"))()
```

`init.lua` akan otomatis mengambil semua modul lain lewat `game:HttpGet` dari raw GitHub
(lihat konstanta `BASE` di `init.lua` kalau repo dipindah/di-fork).

## Struktur

```
GAGSeller/
  init.lua              Entry point: bangun `ctx`, load semua modul berurutan.
  app.lua               Init akhir: set default page, supervisor auto-claim, auto-resume.
  modules/
    services.lua        game:GetService + require deps (RR, DataService, dll).
    registry.lua        Bangun PET/MUT/SKIN options, comboKey, mutDisplay.
    config.lua          CFG default (3 profil x 3 listing) + save/load state JSON.
    booth.lua           ownsBooth, tryClaimNearest, ensureBooth, autoSwitchBoothPortal, tokens.
    webhook.lua         sendWebhook + listener transaksi (notif terjual ke Discord).
    listing.lua         inventory summary, listPass (sekuensial), mainLoop, unlist/unequip.
  ui/
    theme.lua           Palet warna (C) + helper mk/corner/stroke/pad.
    components.lua      Kontrol reusable: toggle, input, dropdown, accordion, button, page/tab.
    window.lua          Jendela utama, sidebar, drag, min/max/close, status, log.
    pages.lua           Halaman: Sell, Profile 1..3, Inventory, Misc.
```

## Konsep `ctx`

Semua modul berbentuk `return function(ctx) ... end` dan berbagi satu tabel `ctx`.
Tiap modul menambahkan fungsi/field ke `ctx` supaya modul lain memakainya:

- `ctx.Services`, `ctx.LP`, `ctx.deps` — services & module game.
- `ctx.CFG`, `ctx.persistState` — konfigurasi & penyimpanan.
- `ctx.reg` — opsi dropdown (PET/MUT/SKIN).
- `ctx.C`, `ctx.mk`, `ctx.make*` — helper & komponen UI.
- `ctx.ui` — referensi elemen GUI (gui, pages, tabBtns, logBox, dll).
- `ctx.state` — runtime flags (running, listedSet, currentLoopId, logLines).
- `ctx.log`, `ctx.setStatus`, `ctx.alive`, `ctx.elevate` — util global.

Urutan load penting (didefinisikan di `init.lua` → `MODULES`): modul bawah bergantung
pada yang di atasnya. Fungsi yang saling memanggil di-resolve saat runtime (lewat `ctx`),
jadi forward-reference aman.

## Menambah fitur (contoh)

- Tambah toggle baru → edit `ui/pages.lua` di halaman terkait, pakai `ctx.makeToggle`.
- Tambah field config → tambahkan default di `modules/config.lua` (CFG) + blok restore-nya.
- Ubah logika listing → hanya sentuh `modules/listing.lua`.
- Ubah tampilan/warna → `ui/theme.lua`.
