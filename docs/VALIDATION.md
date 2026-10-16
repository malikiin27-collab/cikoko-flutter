# Validasi paket

## Sudah dilakukan di lingkungan pembuatan

- Membaca source autentikasi, helper database/profil, API mobile, cuti pegawai/admin, laporan harian, PPPK bulanan, dan engine pemanggil PDF dari arsip website Cikoko.
- Memeriksa sintaks semua source Dart dan PHP menggunakan grammar Tree-sitter. Ini pemeriksaan sintaks, bukan type checking Dart atau eksekusi PHP.
- Memeriksa sintaks Python untuk script setup platform dan smoke test.
- Memeriksa kecocokan nama endpoint yang dipanggil aplikasi dengan router/API patch atau endpoint mobile existing.
- Memeriksa bahwa ZIP hanya membawa source aplikasi, API tambahan, panduan dan mockup; tidak membawa config.php, database pegawai, APK lama, kredensial, atau folder storage sumber website.
- API harian dan bulanan diadaptasi dari kode source agar aturan periode foto, hash, indikator, dan revisi tidak hilang.

## Belum dijalankan

- `flutter pub get`, `flutter analyze`, `flutter test`, dan build APK.
- PHP CLI lint / eksekusi PHP / transaksi MySQL pada server staging.
- Pengujian visual hasil render Flutter di emulator atau perangkat.
- Pengujian kamera, GPS, permission, lifecycle Android, timeout/retry pada perangkat fisik.
- Koneksi atau login ke website produksi.
- iOS build/signing.

Flutter/PHP CLI tidak tersedia dalam lingkungan pembuatan. Karena itu paket tidak dilabeli “siap produksi” atau “APK berhasil dibuild”. Workflow `.github/workflows/validate.yml` dan pengujian Dart telah disertakan untuk menjalankan pemeriksaan tersebut pada lingkungan yang memiliki SDK.

## Test yang disediakan

`flutter_app/test/api_test.dart`:

- bearer dikirim sebagai header, tidak masuk URL;
- mutasi menggunakan POST;
- HTTP 401 memicu invalidasi sesi;
- respons `ok:false` tidak ditampilkan sebagai berhasil;
- konversi hasil array kosong PHP dan angka SQL.

`flutter_app/test/navigation_test.dart`:

- kelima tujuan navigasi benar untuk admin/PJLP/PPPK;
- dashboard compact diuji pada ukuran layar 390×844;
- tidak ada exception layout pada dashboard dalam test tersebut.

Test tersebut **disediakan tetapi belum dieksekusi**. Setelah `flutter pub get`, jalankan analyze dan test; perbaiki bila ada perubahan API plugin pada versi yang terpasang. Simpan `pubspec.lock` hasil validasi.

## Gate sebelum produksi

Lulus CI + seluruh uji staging pada INSTALL.md; lakukan uji dua perangkat untuk saldo cuti, retry, dan konflik revisi. Pastikan versi website aktif sesuai source yang dipakai. Minta ZIP terbaru untuk memetakan patch QR/TTD serta akses PPPK Pancoran sebelum fitur tersebut dianggap bagian dari rilis.
