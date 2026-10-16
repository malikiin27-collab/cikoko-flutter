# Cikoko Flutter Native — sumber aplikasi dan patch API

Paket kode aplikasi native Flutter untuk **Admin, PJLP, dan PPPK Cikoko**, dengan tampilan compact berdasarkan tiga mockup di `docs/mockups/`. Menu aplikasi menggunakan widget Flutter, bukan WebView.

**Status:** source code + patch API. Belum APK rilis, belum dipasang ke website, dan belum diuji langsung dengan database/server produksi. Sintaks Dart/PHP telah diperiksa dengan parser. Flutter SDK, Android SDK, dan PHP CLI tidak tersedia di lingkungan pembuatan; `flutter analyze`, widget test, build APK, dan pengujian PHP/MySQL wajib dijalankan sebelum digunakan. Workflow CI dan pengujian disertakan.

## Dasar integrasi

Sumber yang diperiksa adalah **Cikoko (6).zip**, arsip website bertanggal Oktober 2026. `BASE_URL` pada arsip menunjuk ke `https://cikoko.datawebs.my.id`. Tidak ada password, konfigurasi database, isi database pegawai, maupun token produksi yang disalin ke paket ini.

API baru berada di `api/flutter/` dan memanfaatkan bootstrap, login, penyimpanan, serta tabel website yang sama. API mobile lama tidak ditimpa. Login menggunakan `ckAuthVerify`; admin/PJLP memakai username, PPPK memakai email sesuai aturan website tersebut. PIN tidak ditambahkan sebagai syarat login baru.

Jika website aktif telah menerima patch setelah arsip ini dibuat, cocokkan dengan kode terbaru sebelum pemasangan. Khusus modul QR/TTD dan akses PPPK se-Kecamatan Pancoran, arsip ini tidak menyediakan API yang sesuai dengan mockup; fitur tersebut belum dinyatakan selesai.

## Isi paket

| Lokasi | Isi |
|---|---|
| `flutter_app/lib/` | UI native, klien API, autentikasi, formulir, kamera/GPS, PDF |
| `flutter_app/test/` | Uji transport API dan navigasi tiga role |
| `website_patch/api/flutter/` | Patch PHP tambahan untuk website Cikoko |
| `tools/prepare_platforms.py` | Membuat scaffold Android/iOS resmi dari Flutter SDK lokal |
| `tools/smoke_api.py` | Uji baca dan pembatasan role sesudah API dipasang |
| `.github/workflows/validate.yml` | Lint PHP, analyze/test Flutter, build APK debug |
| `docs/INSTALL.md` | Langkah cPanel dan build aplikasi |
| `docs/API.md` | Kontrak endpoint dan data |
| `docs/FEATURES.md` | Pemetaan mockup, fitur tersedia, dan batas implementasi |
| `docs/VALIDATION.md` | Hasil pemeriksaan dan pengujian yang masih perlu dilakukan |

## Jalankan aplikasi

Siapkan Flutter stable **3.35.7 atau versi kompatibel yang lebih baru**, Python 3, Android SDK, dan Java sesuai Flutter. Paket dependensi masih berupa rentang versi; `pubspec.lock` baru dibuat saat `flutter pub get` berhasil. Simpan lockfile tersebut dalam repository aplikasi.

Dari folder paket:

```bash
python3 tools/prepare_platforms.py
cd flutter_app
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=https://cikoko.datawebs.my.id
```

Windows: gunakan `python` jika perintah `python3` tidak tersedia. Jalankan script pembentukan platform hanya sekali. Source Dart tidak ditimpa script.

API harus dipasang dahulu agar login berhasil. Tidak ada akun demo/password bawaan atau data contoh tersembunyi pada aplikasi.

## Build APK

```bash
flutter build apk --debug --dart-define=API_BASE_URL=https://cikoko.datawebs.my.id
```

Hasil debug: `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`. Untuk distribusi resmi, konfigurasikan keystore dan signing rilis sendiri sebelum `flutter build apk --release`. Jangan menganggap APK dengan signing debug sebagai rilis resmi.

## Perilaku penting

- Role ditentukan server; pegawai tidak bisa mengubah `user_id` untuk membaca atau mengedit pegawai lain.
- Token disimpan melalui secure storage; server menyimpan hash token. Token baru berlaku 7 hari dan logout mencabut token saat server terjangkau.
- Cuti memakai saldo website: dicadangkan saat pengajuan, dikembalikan sekali ketika ditolak. Persetujuan tidak memotong saldo lagi.
- Klik beberapa tanggal menghitung hari pilihan, bukan jarak antara tanggal pertama dan terakhir. Tanggal terpisah dipecah menjadi beberapa rentang pengajuan agar tabel website tetap kompatibel.
- Check-in/check-out tetap meminta kamera dan GPS maksimal ±30 meter. Waktu resmi diambil dari server.
- Foto laporan mengikuti aturan website: empat periode dua jam, maksimal 12 foto per periode, foto tersimpan terkunci. Mockup formulir bebas disesuaikan dengan aturan ini.
- PPPK bulanan menggunakan indikator administratif/lapangan, dua periode, progres, foto, serta pemeriksaan revisi agar perubahan di website tidak tertimpa diam-diam.
- PDF rekap dibuat native secara landscape. Surat cuti resmi admin menggunakan engine PDF website. Rekap bulanan native belum menggantikan format laporan resmi lengkap dengan foto dan QR/TTD.

Detail batas fitur dan pengujian ada di dokumen terkait; paket ini tidak mengklaim seluruh tombol konsep sudah setara dengan modul website terbaru.
