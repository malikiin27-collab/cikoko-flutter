# Perbaikan dependency GitHub Actions (16 Oktober 2026)

Perubahan hanya ada pada `flutter_app/pubspec.yaml`.

- `archive`: `>=4.0.9 <4.1.0` agar cocok dengan `pdf: ^3.11.3`.
- `dependency_overrides.image: 4.10.2` untuk menghindari `image` 4.11.0 yang menggunakan `ZLibDecoder.decodeLazy` dari archive lebih baru.

Setelah upload ke GitHub, jalankan GitHub Actions kembali. Jika pengujian masih gagal, kirim log terbaru.

Catatan: Build APK dan pengujian `flutter pub get` belum dapat dijalankan di lingkungan pembuatan ZIP ini.
