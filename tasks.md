# TASKS.md — Rencana Implementasi (Flutter Kru Reguler)

> Catatan: dokumen ini disalin ke root repo saat masuk mode implement. Checklist dikerjakan per fase; kotak `[ ]` diubah `[x]` saat selesai. **Git: tidak melakukan commit/push secara mandiri — commit & push hanya berdasarkan perintah eksplisit dari user (lihat "Aturan Git" di `agents.md`).** Bila user memerintahkan commit, gunakan prefix `feat(printer)`, `feat(operan)`, `feat(bagasi-batal)`.

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

## Fase 1 — Fitur 1: Deteksi Printer Thermal Mati (APP-BLE-01) — ✅ SELESAI (26 Okt 2026): deep liveness probe lolos QA round 2 & round 3, disetujui user

### Hasil QA Round 1 (26 Okt 2026 — log real-device RPP02N)
- ✅ Yang berjalan baik: printer nyala → connect sukses, simpan tiket, cetak OK, indikator health check ikut berubah.
- ❌ Yang GAGAL: printer dimatikan → health check tetap `true` → transaksi tetap tersimpan & muncul "✅ Tiket berhasil dicetak!" palsu (Broken pipe spam di logcat).
- **Akar masalah ditemukan di source plugin `blue_thermal_printer 1.2.3` (Android)**:
  1. `isConnected` → `result.success(THREAD != null)` = state CACHE (bukan kondisi printer) → printer mati tetap `true`;
  2. `writeBytes` → `ConnectedThread.write()` MENELAN IOException (Broken pipe, hanya terlihat di logcat) TANPA melempar ulang → Dart selalu menerima `true`;
  3. One-byte write-test juga hanya masuk buffer RFCOMM — tidak membuktikan printer hidup.
- **Kesimpulan**: satu-satunya operasi plugin yang benar-benar menguji printer hidup adalah `connect()` — `socket.connect()` nyata; printer mati → `result.error("connect_error")` → Dart melempar exception.

### Rework `bluetooth_service.dart` (round 2 — metode deep liveness probe)

### 1.1 Service bluetooth (`lib/page/bluetooth_service.dart`) — ✅ [REWORK round 2: deep liveness probe]
- [x] Refactor `checkConnection()` → tetap ada (cached) untuk kompatibilitas pemanggil lama (main.dart/manifest/HistoryPembayaran); TIDAK dipakai validasi transaksi.
- [x] Tambah method `performHealthCheck()` (round 2):
  - [x] Lapis 1: state socket & device terpilih;
  - [x] Lapis 2: **deep probe** `_reconnectProbe(device)` = `disconnect()` + `connect(device)` dengan timeout 6 detik. Printer mati → `connect_error` → mark disconnected (+notifyListeners + stream false). Write-test byte NUL dihapus (terbukti palsu di Android);
  - [x] Guard `_healthCheckInProgress` mencegah probe beruntun.
- [x] Ubah `printBytes()` → return `Future<bool>`:
  - [x] kirim `writeBytes` dengan timeout 20 detik (res != true → mark disconnected);
  - [x] **verifikasi PASCA-cetak**: tunggu estimasi drain (bytes.len ÷ 1200 B/ms… konservatif 9600 bps, min 0.8 s, max 15 s) supaya struk tak terpotong, lalu deep probe → gagal → mark disconnected + return false (pemanggil rollback);
  - [x] guard `_printInProgress` menahan timer probe saat sesi cetak berjalan.
- [x] Ubah timer periodik `_startConnectionCheck()` (5 detik) → panggil `performHealthCheck()`; `_selectedDevice` DIPERTAHANKAN saat mati agar otomatis reconnect ketika printer kembali menyala.
- [x] `connect()` service: set `_printerHealthy` + jalankan timer; catch tetap rethrow.

### 1.2 Penjualan tiket (`lib/view/View_PenjualanTiket.dart`)
- [x] Sebelum insert transaksi TUNAI: `_checkPrinterConnection()` kini memanggil `printerService.performHealthCheck()`; jika `false` → dialog "Printer Tidak Terhubung" muncul / tombol Simpan diblokir, tidak ada insert.
- [x] Urutan simpan→cetak→rollback:
  - `_kirimValue()` kini return `Future<int?>` (id hasil insert, `null` bila gagal/diblok);
  - `printTicket()` kini return `Future<bool>` (`false` bila printer tidak merespons/`printBytes` gagal/bytes kosong/dialog dibatalkan);
  - Tombol Simpan: insert → print → bila `printTicket() == false` → `_hapusTransaksiGagalCetak(insertedId)` menghapus baris `penjualan_tiket` yang baru dibuat + SnackBar "Transaksi dibatalkan: struk tidak tercetak" + form TIDAK direset (bisa dicetak ulang).
- [x] Validasi dialog "Printer Tidak Terhubung" tetap dipakai, tapi kini diisi dari health check BARU (deteksi printer mati nyata).

### 1.3 Bagasi (`lib/view/View_FormBagasiBus.dart`)
- [x] Validasi 4 (printer) di `_buildSubmitButton` → pakai `performHealthCheck()`; double-check pre-insert → `performHealthCheck()`.
- [x] Bila gagal → SnackBar spesifik "Printer belum terhubung".
- [x] Urutan insert→print→rollback:
  - `_submitForm()` kini return `Future<String?>` (`id_order`);
  - setelah `printer.printBytes(bytes)`, hasil dicek: bila `false` → `_hapusBagasiGagalCetak(id_order)` menghapus baris `t_order_bagasi` + toast "Bagasi dibatalkan: tiket tidak tercetak" + `_refreshData()`.
- [x] Helper baru `_hapusBagasiGagalCetak()` (delete by `id_order`).

### 1.4 QA manual round 2 (✅ SELESAI — diuji di device Android, printer RPP02N, 26 Okt 2026: disetujui user)
- [x] Uji: printer nyala → simpan tiket tunai OK, struk keluar (akan lebih lambat ±2–8 s karena probe pasca-cetak → wajar).
- [x] Uji: printer nyala → matikan printer (listrik) → dalam ≤10 detik indikator app jadi merah/off (probe periodik tiap 5 s).
- [x] Uji: printer mati → coba simpan tiket tunai & bagasi → DIBLOKIR ("Printer Tidak Terhubung"), tidak ada baris di sqflite.
- [x] Uji: printer mati → simpan sempat jalan sebelum deteksi → probe pasca-cetak gagal → transaksi/bagasi di-ROLLBACK + toast "Struk TIDAK tercetak".
- [x] Uji: nyala kan printer kembali → status otomatis kembali "terhubung" oleh probe periodik (tanpa Set Printer ulang), simpan sukses.
- [x] Uji: tiket non-tunai (Faspay) tidak terdampak (boleh disimpan tanpa printer).
- [x] Uji: kondisi normal — pastikan TIDAK ada struk terpotong (drain konservatif 9600 bps).

### Hasil QA Round 2 (26 Okt 2026 — log real-device RPP02N, tiket Yogyakarta)
- ✅ **FITUR INTI BEKERJA**: tiket ke-2 (Rp 170.000) saat printer mati → `health check: false` → **tidak ada `_kirimValue` di log** → transaksi TIDAK tersimpan (validasi pre-save memblokir).
- ✅ Probe pasca-cetak & rollback ok pada struk pertama (7769 bytes, drain 6474 ms, verifikasi jalan).
- ❌ **BUG: probe saling berlomba (race)** — probe pasca-cetak `printBytes` bersinggungan dengan probe timer 5 s → dua `connect()` paralel ke device yang sama → salah satu gagal `read failed, socket might closed or timeout (ret:-1)` → printer yang **HIDUP** sempat salah tandai mati (false positive), lalu probe kedua sukses.
- ❌ **BUG: `setState() called after dispose(): _PenjualanFormState`** di `View_PenjualanTiket.dart` — halaman ditutup saat flow cetak masih berjalan.

### 🔁 Round 3 — perbaikan atas QA Round 2 (26 Okt 2026)
- [x] `bluetooth_service.dart`: **serialisasi probe** — semua probe (UI, timer, pasca-cetak) mengantri di `_probeBusy`; tidak ada lagi 2 `connect()` paralel. `_healthCheckInProgress` diganti `_probeBusy` di dalam `_serialLivenessProbe()` (retry ×2, jeda 600 ms — race biasanya pulih; printer benar-benar mati gagal 2×). Probe pasca-cetak & `performHealthCheck()` sama-sama lewat jalur ini.
- [x] `connect()` service juga menunggu `_probeBusy` selesai (koneksi manual tidak berbenturan dengan probe).
- [x] Timer periodik skip tick bila `_probeBusy` (tidak menumpuk backlog probe saat printer mati).
- [x] `View_PenjualanTiket.dart`: guard `if (!mounted) return` di seluruh flow tombol Simpan (setelah `_checkPrinterConnection`, `pilihPrinter`, `_kirimValue`, `printTicket`, `_hapusTransaksiGagalCetak`), di `_onPrinterConnectionChanged`, `_checkPrinterConnection`, dan setState printTicket gagal.
- [x] `View_FormBagasiBus.dart`: guard `mounted` di flow tombol Simpan (double-check printer, `_submitForm`, `getTicketBagasi`/`printBytes`, finally `_isSubmitting`), `_refreshData`, `_checkPrinterConnection`.
- [x] QA ulang round 3: skenario race (cetak struk panjang sementara probe timer jalan) tidak boleh lagi muncul "⚠️ Printer terdeteksi mati" palsu di log saat printer hidup.
- [x] QA ulang round 3: navigasi keluar form tiket saat cetak jalan → tidak ada lagi `setState() called after dispose()`.
- [x] QA ulang round 3: klok skenario penuh QA round 2 (7 butir di atas) sambil perhatikan log.

### ✅ STATUS FASE 1: SELESAI — QA round 2 & round 3 lolos, disetujui user (26 Okt 2026)

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
