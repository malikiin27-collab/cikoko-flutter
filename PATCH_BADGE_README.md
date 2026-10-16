# Patch konflik Badge Flutter

Memperbaiki empat error analyzer pada screenshot: ambiguous_import dan invocation_of_non_function pada leave.dart serta profile.dart.

Widget lokal Badge diubah menjadi StatusBadge beserta constructor dan kedua pemanggilnya. Tidak ada perubahan logika cuti atau profil.

## Pasang di GitHub

1. Ekstrak ZIP ini.
2. Buka root repository cikoko-flutter yang berisi folder flutter_app, tools, dan website_patch.
3. Upload folder flutter_app dari patch ke root repository, sehingga ketiga file menggantikan path yang sama:
   - flutter_app/lib/ui.dart
   - flutter_app/lib/leave.dart
   - flutter_app/lib/profile.dart
4. Commit perubahan. Jangan unggah file ZIP mentah dan jangan buat folder Cikoko-Patch-Badge di dalam repository.
5. Buka Actions dan lihat run baru yang dipicu oleh commit. Rerun run lama hanya membangun commit lama, sehingga tidak menerapkan patch.

Patch ini ditujukan untuk source Cikoko-Flutter-Native-v1 tanpa edit manual lain pada tiga file tersebut. Jika file sudah diedit sendiri, terapkan penggantian nama Badge ke StatusBadge pada deklarasi, constructor, dan kedua pemanggil tersebut saja agar perubahan lain tidak tertimpa.

Validasi: semua kemunculan simbol lokal Badge pada tiga file telah diganti dan sintaks Dart lolos pemeriksaan parser. Flutter analyze/test/build belum dijalankan di lingkungan pembuat patch; hasil akhirnya perlu dilihat pada run GitHub Actions baru.
