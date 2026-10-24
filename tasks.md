# TASKS.md — Rencana Implementasi (Flutter Kru Reguler)

> Catatan: dokumen ini disalin ke root repo saat masuk mode implement. Checklist dikerjakan per fase; kotak `[ ]` diubah `[x]` saat selesai. Commit per fase dengan prefix `feat(printer)`, `feat(operan)`, `feat(bagasi-batal)`.

---

## Fase 0 — Scaffolding Dokumen ✅
- [x] Salin `agents.md`, `prd.md`, `tasks.md` ke root repo (dokumen resmi tim). *(selesai — 3 file dibuat 24 Okt 2026)*
- [x] Verifikasi versi DB di `lib/database/database_helper.dart` (baseline versi 3) — catat bahwa migrasi fitur ini akan naik ke versi 4.
  - **Hasil verifikasi (24 Okt 2026):**
    - Versi DB saat ini: `version: 3` (baris 32 `database_helper.dart`)
    - Nama file DB: `bisapp_09032026-1.db` (baris 28)
    - `onUpgrade` **masih kosong** (belum ada penanganan migrasi sama sekali)
    - ⚠️ Konsekuensi: saat Fase 2 & 3 naikkan ke `version: 4`, handler `onUpgrade` wajib diimplementasi dengan `ALTER TABLE ... ADD COLUMN` (`t_bus_perpal`: `id_kota_perpal`, `nama_kota_perpal`; `t_order_bagasi`: `is_batal`, `alasan_batal`, `tgl_batal`) dan harus dibuat idempotent (tahan error "duplicate column name") karena user di lapangan bisa update versi app lebih dari sekali.

---

## Fase 1 — Fitur 1: Deteksi Printer Thermal Mati (APP-BLE-01)

### 1.1 Service bluetooth (`lib/page/bluetooth_service.dart`)
- [ ] Refactor `checkConnection()` → tetap sweep `isConnected`, lalu catat hasil.
- [ ] Tambah method `performHealthCheck()`:
  - [ ] Bungkus write-test kecil dalam try/catch (write byte/kontrol ESC/POS terkontrol, tanpa memuntahkan struk);
  - [ ] Jika throw/timeout (gunakan `Future.timeout` ~3 detik) → set `_isConnected=false`, `_selectedDevice=null`, `notifyListeners()`, emit stream `false`.
- [ ] Ubah `printBytes()` → return `Future<bool>`, try/catch `bluetooth.writeBytes(); on error → tandai disconnect + notifyListeners() + emit stream`.
- [ ] Ubah timer periodik `_startConnectionCheck()` (3 detik) → panggil `performHealthCheck()` (bukan hanya `isConnected`).
- [ ] Pastikan `connect()` dengan device yang benar-benar mati → langsung catch error yang dilempar `bluetooth.connect` (bisa tetap rethrow).

### 1.2 Penjualan tiket (`lib/view/View_PenjualanTiket.dart`)
- [ ] Sebelum insert transaksi TUNAI: ganti hanya `_checkPrinterConnection()` → panggil `printerService.performHealthCheck()`; jika `false` → dialog "Printer mati/tidak merespons" + **jangan insert**.
- [ ] Ubah urutan: insert lokal hanya dieksekusi **setelah** `printBytes` mengembalikan `true`; bila gagal → tidak ada baris tersisa. (Jika urutan kebalik pun, tambahkan rollback `delete` by insertedId.)
- [ ] Update validasi: dialog "Printer Tidak Terhubung" diciptakan dari mekanisme health check yang BARU (revisi logika pada `_checkPrinterConnection()`).

### 1.3 Bagasi (`lib/view/View_FormBagasiBus.dart`)
- [ ] Validasi 4 (printer) di `_buildSubmitButton` → pakai `performHealthCheck()`; double-check pre-insert → `performHealthCheck()`.
- [ ] Bila gagal → dialog spesifik "Printer mati — bagasi tidak dicetak & tidak disimpan".
- [ ] Urutan insert→print→kembalikan juga dicek: jika print gagal → rollback baris bagasi yang baru diinsert.

### 1.4 QA manual (checklist)
- [ ] Uji: printer nyala → simpan tiket tunai OK, struk keluar.
- [ ] Uji: printer nyala → matikan printer (listrik) → max ±5 detik indikator app jadi merah/off.
- [ ] Uji: printer mati → coba simpan tiket tunai & bagasi → DIBLOKIR, tidak ada baris di sqflite.
- [ ] Uji: nyala kan printer kembali → simpan kembali sukses.
- [ ] Uji: tiket non-tunai (Faspay) tidak terdampak (boleh disimpan tanpa printer).

---

## Fase 2 — Fitur 2: Operan Otomatis dari Lapor Perpal (APP-OPERAN-02)

### 2.1 Migrasi DB & model
- [ ] `database_helper.dart`: versi 4 (`onUpgrade`) → `t_bus_perpal` tambah kolom `id_kota_perpal` (nullable), `nama_kota_perpal` (nullable).
- [ ] Perbarui fungsi `insertBusPerpal` (lib/services/bus_perpal_service.dart) menerima & menyimpan kedua kolom.
- [ ] Model `t_bus_perpal` sesuai (cari model terkait di `lib/models/` atau struktur map di service).

### 2.2 Form Lapor Perpal (`lib/page/LaporPerpal.dart`)
- [ ] Tambah dropdown "Kota Oper" — sumber list: `databaseHelper.getRuteTrayekUrutan(rit)` (urut sesuai rit).
- [ ] Wajib dipilih bila kategori = bus perpal/operasi; jika kategori lain opsional.
- [ ] Sertakan `id_kota_perpal` & `nama_kota_perpal` di payload POST `/api/laporkondisibus` (`lib/api/ApiHelperSaveLaporPerpal.dart`) + disimpan lokal via `insertBusPerpal`.

### 2.3 Kalkulator operan baru (`lib/utils/operan_calculator.dart`)
- [ ] Buat utility kelas `OperanCalculator` dengan method:
  - `Future<Map<String, double>> hitungOperanAuto({required int rit, required int idKotaPerpal})`
  - Logic:
    1. Ambil semua `penjualan_tiket` hari ini (rit aktif, `is_batal=0`, `id_metode_bayar='1'`);
    2. Filter tiket yang titik naiknya `no_urut ≤ no_urut(kotaPerpal)` DAN kota tujuan `no_urut > no_urut(kotaPerpal)`;
    3. Untuk tiap tiket: `harga_segmen = harga_kantor(kotaPerpal → kotaTujuan)` (dari `rute_trayek_urutan`, dikalikan `jumlah_tiket`);
    4. Return `{'totalOperan': ..., 'jumlahTiketOperan': ...}`.

### 2.4 Integrasi ke rekap & setoran
- [ ] `lib/handlers/rekap_transaksi_handler.dart` → loadLastRekapData: bila perpal hari ini ada → panggil `OperanCalculator` → hasil diset sebagai sumber tag 33 & tag 71 (bukan hanya SUM `kategori operan`).
- [ ] `lib/view/View_FormRekapTransaksi.dart`: nilai tag 33 diberi suffix/label kecil "(Auto)" saat terisi otomatis; masih bisa di-edit manual.
- [ ] Pastikan `premi_bersih_calculator.dart` tidak perlu diubah semantiknya — hanya sumber nilai yang berubah.
- [ ] Jika dengan setoran tag 33, duplikat dengan nilai yang disusun via tag 71 pada pendapatan — pastikan formula premi (pendapatanKotor - operan) tetap konsisten (verifikasi dengan uji angka).

### 2.5 QA manual (checklist)
- [ ] Buat lopor perpal rit 1 (Jember–Yogya) kota oper = Probolinggo; jual tiket Jember→Yogya 3 kursi.
- [ ] Buka Rekap → kolom Operan terisi = 3 × harga(Probolinggo→Yogya).
- [ ] Edit manual kolom operan → terganti dengan angka manual & disimpan t_setoran_kru tag 33.
- [ ] Rit tanpa perpal → kolom operan kosong (manual).

---

## Fase 3 — Fitur 3: Pembatalan Bagasi (WEB-BAGASI-03 / APP-BAGASI-03)

### 3.1 Spec & API contract (dokumen untuk tim web)
- [ ] Tambah di prd.md/tolong buat `docs/api/bagasi-batal.md`:
  - `POST /api/orderbagasibatal` — body `{ id_order, alasan_batal, id_user_admin }` → set `is_batal=1`, log `t_order_bagasi_status (BATAL)`;
  - `GET /api/tampilorderbagasibatal` — query `periode_awal, periode_akhir, no_pol, id_bus, rit` → `[{ id_order, tgl_order, alasan_batal, tgl_batal, ..., }]`;
  - UI web (modul Penjualan → Bagasi): tombol "Batal" per baris + konfirmasi alasan; role/permission khusus.

### 3.2 Migrasi DB & service mobile
- [ ] `database_helper.dart` versi 4 → `t_order_bagasi` tambah `is_batal` (int, default 0), `alasan_batal` (nullable), `tgl_batal` (nullable).
- [ ] `lib/services/` → tambah method di service bagasi (atau `penjualan_tiket_service` pola):
  - `syncBatalBagasiData({token, noPol, idBus, rit})` — panggil `GET /api/tampilorderbagasibatal`, match by `id_order`, set `is_batal=1` lokal.
  - Update semua fungsi pendapatan bagasi (`databaseHelper.getSumJumlahPendapatanBagasi`, tag 3 rekap) → `WHERE is_batal=0`.
  - `View_HistoryBagasiBus.dart` › status UI `"BATAL"` (sudah ada) → warna merah + alasan.

### 3.3 UI mobile (sync only)
- [ ] `View_HistoryBagasiBus.dart` / `View_HistoryBagasiBus.view`: tombol **Sync** (mirip tombol Sync pembatalan tiket di transaksi) + loading progres.
- [ ] Tidak ada tombol/negasi membatalakan bagasi dari mobile.
- [ ] Chip/label status BATAL tampil di riwayat.

### 3.4 QA manual (checklist)
- [ ] Web → batal bagasi X → app → Sync → bagasi X status BATAL.
- [ ] Bagasi X tidak dihitung di pendapatan bagasi (Rekap tidak memuat).
- [ ] Setoran/premi (tag 60/61/27/32) TIDAK berubah dari pembatalan bagasi yang sudah masuk rekap.
- [ ] Sync gagal/offline → tidak ada bagasi berubah status.

---

## Fase 4 — Rangkuman & Integrasi
- [ ] Uji gabungan: perpal → operan auto → simpan rekap → printer OK.
- [ ] Regression: transaksi non-tunai, push data (`data_pusher_service`), premi harian.
- [ ] Versi bump aplikasi ke 1.0.1+48 di `pubspec.yaml`.
- [ ] Update README.md (bagian changelog singkat).

## Risiko & Mitigasi
| Risiko | Mitigasi |
|---|---|
| Write-test bluetooth bisa "mencetak" karakter liar di kertas | Gunakan byte CTL (mis. ESC @ init / throwaway line feed dengan jumlah minimal) → diuji ke printer target sebelum rilis |
| Kegagalan print di tengah transaksi menyisakan baris DB | Insert setelah print sukses, atau transaksi rollback |
| Operan double count (tag 33 vs 71) | Uji premi bersih pada kombinasi rit; satukan rumus di OperanCalculator |
| DB versi naik membuat device lama gagal upgrade | Hanya `ALTER TABLE ADD COLUMN`, uji upgrade dari DB versi 3 asli |
| Web (bagasi batal) belum dirilis saat mobile update | Sync endpoint 404 → ditoleransi (lempar pesan "server belum mendukung pembatalan bagasi") |
