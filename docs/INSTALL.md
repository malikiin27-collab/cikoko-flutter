# Pemasangan dan pengujian

## 1. Periksa sumber website

Integrasi ditulis berdasarkan `Cikoko (6).zip`, bukan hasil membaca database produksi. Pastikan root website masih memiliki:

- `bootstrap.php`, `login-security.php`, `pppk_kinerja.php`
- `api/mobile/common.php`, `start.php`, `stop.php`, `tracking_v9.php`
- `storage/install/cuti-pdf-engine.php`
- tabel `users`, `employee_profiles`, `settings`, `cuti`, `cuti_detail`, `tracking_sessions`, `laporan`, serta tabel impor lama yang digunakan `ckPppkSeed`.

Untuk laporan harian, helper `ensureShiftPhotoSchema`, `cikokoCaptureRead`, `cikokoAcceptPhoto`, dan `cikokoSealPhoto` harus tersedia. PHP memerlukan ekstensi MySQL/PDO atau mysqli sesuai website, fileinfo, serta GD yang dipakai cap foto.

## 2. Pasang patch melalui cPanel

1. Buat salinan file dan database website sebelum memasang patch.
2. Uji terlebih dahulu pada salinan/staging dengan data uji.
3. Buka document root domain Cikoko (lokasinya mengikuti pengaturan domain cPanel, bukan selalu `public_html`).
4. Salin isi `website_patch/` ke document root. Hasil akhirnya: `<root>/api/flutter/index.php` dan berkas lain pada folder yang sama.
5. Jangan mengganti `config.php`, `bootstrap.php`, `api/mobile/`, atau database dengan file dari website lain. Paket ini sengaja tidak menyertakannya.
6. Atur izin normal file PHP 0644 dan folder 0755 sesuai hosting. Jangan menjadikan folder upload dapat mengeksekusi PHP.
7. Apache/LiteSpeed menggunakan `.htaccess` yang disertakan agar header Authorization diteruskan. Jika server Nginx/FastCGI, teruskan `HTTP_AUTHORIZATION` dalam konfigurasi server; `.htaccess` tidak dibaca Nginx.
8. Buka `/api/flutter/index.php?action=me` tanpa token. Hasil yang benar ialah JSON kesalahan dengan HTTP 401. HTML login/404 berarti patch atau routing belum tepat.

`mobile_api_tokens` dan tabel laporan yang sudah dikelola helper website dibuat jika belum ada. API cuti menambahkan `ck_flutter_requests` untuk mencegah pengajuan terduplikasi saat retry. Tidak ada SQL DROP, TRUNCATE, atau impor data pegawai dalam patch.

## 3. Uji dengan akun staging

```bash
python3 tools/smoke_api.py --base https://alamat-staging-anda
```

Masukkan akun melalui prompt, bukan argumen shell. Ulangi untuk admin, PJLP, PPPK. Script tidak membuat cuti atau laporan; hanya login, membaca, memeriksa pembatasan role, lalu logout.

Uji tulis manual dengan akun uji:

1. Admin membuat pegawai; pastikan muncul di website dan login sesuai peran.
2. Pegawai mengubah kontak/foto; periksa profil di website.
3. Cuti dua hari mengurangi saldo dua hari saat pengajuan. Retry identik tidak membuat duplikat. Admin menolak mengembalikan dua hari; percobaan memproses kembali harus gagal.
4. Admin menyetujui pengajuan lain dengan nomor surat; cetak PDF dan periksa identitas/pejabat.
5. Check-in dan check-out dengan perangkat fisik, kamera, serta GPS nyata.
6. Kirim foto pada slot aktif. Ulangi foto identik dan pastikan tidak terduplikasi; ganti isi nomor foto tersimpan harus ditolak.
7. PPPK menyimpan draf dua periode, melihatnya di website, dan mengirim laporan. Edit paralel di website harus menimbulkan konflik revisi pada aplikasi, bukan menimpa data.
8. Pegawai lain tidak boleh memperoleh foto, cuti, atau laporan akun pertama dengan mengganti ID URL.

## 4. Siapkan Android

Dari root paket:

```bash
python3 tools/prepare_platforms.py
cd flutter_app
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=https://alamat-staging-anda
```

Script membuat platform resmi sesuai SDK lokal dan menambahkan izin internet/lokasi, label aplikasi, serta menonaktifkan cleartext dan backup data aplikasi. Kamera memakai image_picker; aplikasi tidak meminta akses seluruh penyimpanan perangkat.

Foto mulai/selesai dan laporan memakai GPS baru setelah kamera selesai. Jika akurasi melebihi 30 meter atau GPS terlalu lama, server menolak data. Jangan menurunkan aturan ini hanya untuk meloloskan emulator.

Versi ini tidak memiliki layanan tracking background. Informasi keberhasilan tracking pada endpoint lama tidak dipakai sebagai bukti bahwa aplikasi Flutter menjalankan background service.

## 5. iOS opsional

```bash
python3 tools/prepare_platforms.py --platforms android,ios
```

Jalankan sebelum folder Android dibuat. Script menambahkan penjelasan izin lokasi/kamera/galeri pada Info.plist. Konfigurasi signing Xcode, deployment target yang diminta plugin, dan capability Keychain secure storage dilakukan di macOS sesuai dokumentasi plugin. iOS belum diuji pada paket ini; sasaran utama adalah Android.

## 6. Rilis

- Build debug hanya untuk pengujian internal. Signing produksi harus memakai keystore milik pengelola.
- Periksa package/application ID hasil scaffold dan sesuaikan dengan identitas aplikasi yang dikehendaki sebelum rilis pertama.
- Simpan keystore dan kata sandi di tempat terpisah; jangan masukkan ke ZIP/source repository publik.
- `API_BASE_URL` adalah alamat server publik, bukan kredensial; tidak ada kredensial database dalam APK.
- Contoh petunjuk resmi: https://docs.flutter.dev/deployment/android dan https://docs.flutter.dev/cookbook/networking/send-data.

## Rollback

Hapus atau pindahkan folder `api/flutter/` untuk menghentikan aplikasi baru. Endpoint website dan API mobile lama tidak ditimpa oleh patch ini. Data yang sudah dibuat melalui aplikasi tetap berada di tabel website; rollback file tidak membatalkan perubahan data tersebut. Jangan menghapus tabel token bersama karena dapat memutus aplikasi mobile lama.
