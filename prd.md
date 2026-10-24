# PRD.md — Pengembangan Aplikasi Kru Reguler (Fadhilah/Peningkatan Q4 2026)

## Latar Belakang
Aplikasi kru reguler sudah berjalan, tetapi ada 3 masalah operasional:
1. Printer thermal yang **dimatikan** masih terbaca "terhubung" oleh aplikasi (Bluetooth state Android), sehingga transaksi tunai tiket & bagasi **tetap bisa disimpan** padahal struk tidak tercetak → data masuk tanpa bukti cetak.
2. Kolom **Operan** (tag 33) pada Rekap Transaksi Kru masih diisi manual, padahal saat bus perpal (jalan/rusak di tengah trayek) semua penumpang harus dioper ke kota tujuan masing-masing — nilai operan seharusnya bisa dihitung otomatis dari tiket yang terjual (titik naik–turun) + harga sisa segmen.
3. **Pembatalan bagasi** belum ada. Kontrol pembatalan di aplikasi web (admin PO), aplikasi mobile hanya menerima hasil sync, dan tidak memengaruhi pendapatan setoran kru karena bagasi dibatalkan dikeluarkan dari perhitungan pendapatan.

## Tujuan & Kriteria Sukses

### Fitur 1 — Deteksi Printer Thermal Mati (Tiket & Bagasi)
**Masalah:** `BluetoothPrinterService.checkConnection()` hanya membaca `bluetooth.isConnected` (state socket). Printer mati → Android masih menganggap socket terhubung → `_isConnected = true` → validasi "printer harus nyala" lolos → transaksi tersimpan.

**Rumus:** APP-BLE-01

**Perilaku yang diinginkan:**
- F1.1. Ketika printer nyala tapi Bluetooth dimatikan → app tampil "tidak terhubung" (sudah ada).
- F1.2. Ketika printer **dimatikan** (listrik off) tapi tetap paired/terdaftar → app harus mendeteksi "tidak terhubung/printer mati" maksimal ±5 detik, indicator UI berubah (merah/oranye), dan **transaksi tiket tunai & bagasi tidak bisa disimpan** sampai printer nyala kembali.
- F1.3. Ketika print gagal (write error di tengah process), app harus menandai printer disconnected (bukan toast mengabaikan).

**Solusi teknis:**
- `BluetoothPrinterService`:
  - Tambah `Future<bool> performHealthCheck()`: selain `isConnected`, lakukan **write-test** kecil (bukan cetak struk) ke printer (mis. `bluetooth.writeBytes` per token ESC/POS kosong atau tulis 1 byte terkontrol). Jika exception/timeout → set `_isConnected=false`, hapus `_selectedDevice`, `notifyListeners()`.
  - Ubah `printBytes` return `Future<bool>` dan bungkus `writeBytes` dengan try/catch; kegagalan → update status disconnect + tampilkan dialog error yang JELAS.
  - Timer cek periodik: panggil `performHealthCheck` (bukan hanya `isConnected`) tiap 3–5 detik.
- `View_PenjualanTiket.dart` (tunai) & `View_FormBagasiBus.dart`:
  - Sebelum insert, jalankan `performHealthCheck` → jika gagal → tampilkan dialog "Printer mati / tidak merespons — transaksi tidak dapat disimpan" tanpa insert.
  - Setelah print struk, bila `printBytes` return false → tampilkan dialog peringatan + batalkan insert transaksi tadi (rollback baris lokal yang sudah diinsert) — ATAU (lebih disukai): insert hanya **setelah** print sukses.

**Kriteria sukses:** printer dimatikan → dalam ≤5 detik indikator berubah; tombol simpan tiket tunai & form bagasi diblokir; tidak ada baris transaksi ditinggalkan pada DB lokal saat print gagal.

### Fitur 2 — Kolom Operan Terisi Otomatis (Rekap Transaksi / Setoran Kru)
**Rumus:** APP-OPERAN-02

**Sumber data:**
- Lapor Perpal: `t_bus_perpal` + field baru (F2.1): pilih **kota perpal** (dropdown dari kota urutan trayek `rute_trayek_urutan(rit)`) di form LaporPerpal, tersimpan pada migrasi DB (kolom `id_kota_perpal`, `nama_kota_perpal`).
- Penumpang titik naik–turun: `penjualan_tiket` (`kota_berangkat`, `kota_tujuan`, `jumlah_tiket`, `kategori_tiket`, `is_turun`, `is_batal`, `id_metode_bayar`, `tanggal_transaksi`) — sub menu Penjualan Tiket → Transaksi.
- Harga antar kota: `rute_trayek_urutan` / `list_kota` (jarak, harga_kantor per segmen kota urutan trayek).

**Perilaku:**
- F2.1. Form Lapor Perpal terdapat dropdown "Kota Oper (titik perpal)". Disimpan lokal & dikirim ke endpoint `/api/laporkondisibus` (field tambahan `id_kota_perpal`).
- F2.2. Saat kru membuka Rekap Transaksi → pendapatan/pengeluaran, jika ada data perpal tercatat hari ini (rit aktif):
  - Sistem menghitung otomatis nilai **Operan (tag 33)**:
    `operan = Σ (tiket yang titik naiknya ≤ kota_perpal && kota tujuannya > kota_perpal) × harga_kantor(kota_perpal → kota_tujuan masing-masing)`.
  - Contoh: Jember→Yogya perpal di Probolinggo → semua penumpang dioper → setiap tiket dinilai harga Probolinggo→Yogya (dari tabel urutan kota) × jumlah_tiket.
  - Nilai tag 71 (Tiket Operan) juga dihitung (sudah ada; dipastikan hanya tiket yang teroper).
- F2.3. Nilai auto diisi dengan mekanisme kontrol: terlihat label "Auto" dan tetap dapat di-edit manual; ketika kosong/perpal belum diisi → kolom operan manual seperti biasa.

**Kriteria sukses:** setelah mengisi Lapor Perpal + pilih kota oper, buka Rekap → kolom Operan terisi angka yang sesuai rumus; dapat diubah manual; premi bersih tetap konsisten (tidak double count).

### Fitur 3 — Pembatalan Bagasi (Kontrol Web; Mobile Sync)
**Rumus:** WEB-BAGASI-03 & APP-BAGASI-03

**Perilaku aplikasi web (spec only — project Laravel terpisah):**
- F3.1. Modul Penjualan → Sub menu Bagasi: daftar order bagasi + tombol **"Batal"** (hanya role tertentu/permission admin) + alasan pembatalan.
- F3.2. Backend: tombol Batal → endpoint baru `POST /api/orderbagasibatal` (atau update status) → `t_order_bagasi.is_batal=1`, record `t_order_bagasi_status` status `BATAL`; log user & waktu batal.
- F3.3. Endpoint untuk sync: `GET /api/tampilorderbagasibatal?periode_awal=&periode_akhir=&no_pol=&id_bus=&rit=` mengikuti pola `tampilpenjualantiketbatal` → return daftar id_order yang dibatalkan.

**Perilaku aplikasi mobile:**
- F3.4. Menambah kolom `is_batal` pada `t_order_bagasi` (migrasi versi DB).
- F3.5. Menu Bagasi (History) ada tombol **Sync** (mirip tombol Sync pembatalan tiket di transaksi) → panggil endpoint GET batal → update lokal `is_batal=1`.
- F3.6. **Semua perhitungan pendapatan bagasi** (`getSumJumlahPendapatanBagasi`, dll.) mengecualikan `is_batal=1`.
- F3.7. Bagasi yang dibatalkan TIDAK dihapus, hanya ditandai BATAL (riwayat tetap), tidak berpengaruh pada premi, hanya pendapatan kotor/mengurangi perhitungan.

**Kriteria sukses:** admin web membatalkan bagasi → kru buka app → tap Sync → status bagasi jadi BATAL; angka pendapatan bagasi pada rekap tidak memasukkan bagasi batal; tidak ada data bagasi hilang.

## Batasan (Non-goals)
- Tidak mengubah mekanisme pembayaran Faspay/non-tunai (hanya validasi printer untuk tunai & bagasi).
- Pembatalan tiket & bagasi dari **sisi mobile** tidak diizinkan (hanya menerima sync dari web).
- Tidak mengubah struktur `t_setoran_kru` (operan tetap sebagai tag transaksi 33).
- Aplikasi web hanya dirancang di level spesifikasi & API contract di dokumen ini (implementasi dilakukan di project web).
