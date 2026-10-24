# AGENTS.md — Aplikasi BIS MILA SEJAHTERA (Kru Reguler — Flutter Mobile)

## Gambaran Proyek
- Aplikasi mobile kru bus reguler: penjualan tiket, bagasi, rekap transaksi/setoran kru, lapor perpal, pengecekan bus, manifest.
- Stack: Flutter (Dart), `provider`, SQFlite (DB lokal `bisapp_09032026-1.db`), `blue_thermal_printer` + `esc_pos_utils` (struk thermal 58mm), `http` (REST).
- Backend: Laravel `https://apimila.milaberkah.com/api/...` (Bearer token, SharedPreferences key `token`).
- Aplikasi web/admin PO berada di project Laravel terpisah (tidak di repo ini); mobile hanya konsumen sync via REST.

## Konvensi Kode
- Bahasa: Dart, gaya `flutter_lints`; bahasa Indonesia untuk nama UI/log, nama variable/code campuran EN-ID mengikuti file sekitar.
- Struktur direktori:
  - `lib/page/` — halaman utama (Home, PenjualanTiket, BagasiBus, RekapTransaksi, LaporPerpal, Login, dll.)
  - `lib/view/` — form & tampilan (View_PenjualanTiket, View_FormBagasiBus, View_FormRekapTransaksi, View_FormSetoran, View_HistoryTransaksi, View_HistoryBagasiBus, widgets/)
  - `lib/services/` — akses data (SQFlite service + REST: `penjualan_tiket_service`, `bus_perpal_service`, `data_pusher_service`, dll.)
  - `lib/api/` — helper REST per endpoint (ApiHelper*)
  - `lib/models/`, `lib/utils/`, `lib/handlers/`, `lib/database/database_helper.dart`
- Pola penting yang HARUS diikuti:
  - Service = singleton (`static final _instance` + `factory`), ver: `PenjualanTiketService.instance`.
  - Sync status lokal: kolom `status` `'N'` (belum terkirim) / `'Y'` (terkirim); flag `is_batal` untuk pembatalan (pola dari tiket).
  - Push data offline: `data_pusher_service.dart` (premi → `/api/premihariankru`, setoran multipart → `/api/simpansetorankrumobile`), setelah sukses update `status='Y'`.
  - Toast pakai `Fluttertoast`; dialog via `dialog_utils.dart`; validasi via `validation_utils.dart`.

## Database lokal (SQFlite)
- Versi DB saat ini: 3. Setiap migrasi menaikkan `onUpgrade` versi + `ALTER TABLE ... ADD COLUMN` (tanpa drop data).
- Tabel relevan: `penjualan_tiket` (kolom `kota_berangkat`, `kota_tujuan`, `is_turun`, `is_batal`, `status`, `id_metode_bayar`), `t_order_bagasi` (+ `t_order_bagasi_status` riwayat), `t_bus_perpal`, `t_setoran_kru`, `rute_trayek_urutan`, `list_kota`, `m_tag_transaksi`.

## Tag transaksi penting (di rekap/setoran)
- Pendapatan: 1 Reguler, 2 Online, 3 Bagasi, 71 Tiket Operan.
- Pengeluaran: 13 Uang Makan, 15 Tol, 16 Solar, 17 Cuci, 18 Lain-lain, 22 Perbaikan, 33 **Operan**, 29 Parkir, 30 TPR, 31 Ops Surabaya.
- Kalkulasi wajib: 27/32 Premi Atas/Bawah, 60 Pendapatan Bersih, 61 Disetor, 70 Susukan.
- Rumus premi bersih di `lib/utils/premi_bersih_calculator.dart` (pakai tag 33 & 71 — JANGAN diubah semantiknya tanpa update PRD).

## Aturan Kerja
1. Jangan ubah struktur tabel/endpoint backend tanpa mencatat di `prd.md` & `tasks.md`.
2. Setiap fitur baru: update PRD & task list dulu, lalu implement bertahap; commit per fase.
3. Uji manual di device Android (printer thermal asli) untuk fitur printer; tidak ada test otomatis printer, fitur krusial diuji via checklist di `tasks.md`.
4. Endpoint baru mengikuti pola REST yang ada (`/api/<namamodul>`, params snap: `periode_awal`, `no_pol`, `id_bus`, `rit`, `kode_trayek`).
5. Konsisten bahasa UI: bahasa Indonesia.
