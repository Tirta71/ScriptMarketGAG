# GAG Hub — Modular (Trade + Garden)

Refactor dari `Lua Script/GAGSeller.lua` (single-file). **File asli tidak diubah.**
Satu loadstring untuk dua server: `init.lua` bertindak sebagai **router** yang
mendeteksi `game.PlaceId` lalu memuat app yang sesuai.

## Cara menjalankan (via GitHub)

Cukup jalankan satu URL ini di server mana pun:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/main/GAGSeller/init.lua"))()
```

Router memilih otomatis:
- **Trade World** (PlaceId `129954712878723`) → app `trade/` (seller lengkap).
- **selain itu** → app `garden/` (masih rangka/scaffold).

## Struktur

```
GAGSeller/
  init.lua              ROUTER — cek PlaceId, load trade/ atau garden/. (ini yang di-loadstring)
  README.md

  trade/                App Trade World (fitur seller — sebelumnya di root).
    init.lua            Entry: bangun `ctx`, load semua modul berurutan.
    app.lua             Init akhir: default page, supervisor auto-claim, auto-resume.
    modules/
      services.lua      game:GetService + require deps (RR, DataService, dll).
      registry.lua      Bangun PET/MUT/SKIN options, comboKey, mutDisplay.
      config.lua        CFG default (3 profil x 3 listing) + save/load state JSON.
      booth.lua         ownsBooth, tryClaimNearest, ensureBooth, autoSwitchBoothPortal, tokens.
      webhook.lua       sendWebhook + listener transaksi (notif terjual ke Discord).
      listing.lua       inventory summary, listPass (sekuensial), mainLoop, unlist/unequip.
    ui/
      theme.lua         Palet warna (C) + helper mk/corner/stroke/pad.
      components.lua    Kontrol reusable: toggle, input, dropdown, accordion, button, page/tab.
      window.lua        Jendela utama, sidebar, drag, min/max/close, status, log.
      pages.lua         Halaman: Sell, Profile 1..3, Inventory, Misc.

  garden/               App Garden (SCAFFOLD — fitur menyusul).
    init.lua            GUI placeholder self-contained (siap dipecah jadi modules/ + ui/).
```

## Menambah fitur Garden

`garden/init.lua` sekarang masih satu file placeholder. Saat fiturnya mulai banyak,
ikuti pola `trade/`: pecah jadi `garden/modules/` + `garden/ui/` dengan pola `ctx` yang sama.
Router tidak perlu diubah — cukup isi `garden/`.

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

(Konsep `ctx` ini berlaku untuk app `trade/`; `garden/` akan menyusul pola yang sama.)

Urutan load penting (didefinisikan di `trade/init.lua` → `MODULES`): modul bawah bergantung
pada yang di atasnya. Fungsi yang saling memanggil di-resolve saat runtime (lewat `ctx`),
jadi forward-reference aman.

## Menambah fitur (contoh)

- Tambah toggle baru → edit `ui/pages.lua` di halaman terkait, pakai `ctx.makeToggle`.
- Tambah field config → tambahkan default di `modules/config.lua` (CFG) + blok restore-nya.
- Ubah logika listing → hanya sentuh `modules/listing.lua`.
- Ubah tampilan/warna → `ui/theme.lua`.
