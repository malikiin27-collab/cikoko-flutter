# API Flutter Cikoko v1

Base: `https://cikoko.datawebs.my.id/api/`. JSON menggunakan UTF-8. Semua endpoint kecuali login memerlukan `Authorization: Bearer <token>`. Token tidak dikirim melalui query string. Semua perubahan menggunakan POST; GET hanya membaca.

Respons normal: `{"ok":true,...}`. Respons gagal: `{"ok":false,"message":"..."}`. HTTP 401 = token tidak ada/kedaluwarsa/akun tidak aktif; 403 = role tidak sesuai; 400 = validasi; 404 = endpoint/berkas tidak ditemukan.

## Router `flutter/index.php?action=...`

| Action | Metode | Akses | Masukan/hasil utama |
|---|---|---|---|
| login | POST JSON | Publik | username, password → token, expires_at, user |
| me | GET | Semua role | user (daftar kolom aman), server_time |
| logout | POST JSON | Semua role | Cabut token saat ini |
| dashboard | GET | Semua role | month opsional YYYY-MM → stats, user, active |
| employees | GET | Admin | q, role opsional → items; bukan seluruh record password |
| employee_save | POST JSON | Admin | id, nama_lengkap, nomor_pegawai, saldo_cuti, status |
| leaves | GET | Semua role | month → items; pegawai hanya miliknya; balance |
| leave_create | POST JSON | Pegawai | request_id, dates[], reason, leave_address, phone, position_name, service_period |
| leave_review | POST JSON | Admin | id, decision (approve/reject), note, decision_number, decision_date |
| attendance | GET | Semua role | month → items, active; pegawai hanya miliknya |
| reports | GET | Semua role | month → items, active, slot (0–3), counts |
| monthly | GET | PPPK/Admin | month, type (admin/lapangan) → row/data/indicators atau items admin |
| profile | POST JSON | Pegawai | no_hp, email, alamat, kontak_lain, akun_spse |
| password | POST JSON | Semua role | current_password, new_password → revoke seluruh token mobile + remember token |
| settings | GET | Admin | settings sesuai whitelist |
| settings_save | POST JSON | Admin | whitelist pejabat, alamat, telepon, judul/tujuan surat |

`request_id` cuti 16–64 karakter alfanumerik/underscore/hyphen. Identitas yang sama dengan isi yang sama boleh diulang; isi yang berbeda setelah permintaan tersimpan ditolak. Transaksi dan row lock melindungi saldo. Pengajuan gagal sebelum commit tidak menyimpan penanda keberhasilan.

## Endpoint terpisah

| Path | Metode | Akses | Keterangan |
|---|---|---|---|
| flutter/employee_create.php | POST JSON | Admin | role, nama_lengkap, nomor_pegawai, username, email, password, saldo_cuti |
| flutter/photo.php | POST multipart | Pegawai | photo JPEG, index 1–12, lat/lng/acc/fix_epoch → image_base64 bercap, token bukti, session_id, slot, index |
| flutter/report_save.php | POST multipart | Pegawai | session_id, report_slot, keterangan, foto[index], photo_stamp_tokens[index] |
| flutter/monthly_save.php | POST multipart | PPPK | month_key, report_type, revision, member_jabatan, signed_date, action=draft/submit, progress_1[code], progress_2[code], photo_1_code, photo_2_code |
| flutter/media.php?id=... | GET biner | Pemilik/Admin | Gambar laporan; server mengecek kepemilikan dan containment path |
| flutter/profile_photo.php | GET biner / POST multipart | Pegawai | Foto profil sendiri / upload field photo maksimal 5 MB |
| flutter/cuti_pdf.php?id=... | GET PDF | Admin | Surat cuti approved dari engine website |
| mobile/start.php | POST multipart | PJLP/PPPK | Endpoint lama: photo, lat/lng/acc/fix_epoch, device_info |
| mobile/stop.php | POST multipart | PJLP/PPPK | Endpoint lama: photo, lat/lng/acc/fix_epoch |

Tidak ada endpoint yang menerima role atau user_id dari pegawai sebagai sumber otorisasi. `id` pengajuan/pegawai pada endpoint admin hanya diterima setelah pemeriksaan role admin.

## Foto harian

Flutter mengambil JPEG dari kamera dan GPS baru, lalu mengirimnya ke `photo.php`. Server menentukan waktu/slot, membubuhkan cap foto, dan menandatangani hash foto. Flutter mengirim ulang byte foto hasil server tanpa mengubahnya. `report_save.php` memakai aturan sumber website untuk memeriksa hash, slot, masa berlaku bukti, sesi aktif, nomor foto, serta duplikasi.

Untuk foto lebih besar dari 1 MB, foto bercap dipadatkan sebelum hash ditandatangani agar fungsi upload website tidak mengubah byte setelah penandatanganan. Foto yang waktunya sudah habis harus diambil ulang; tidak ada pemalsuan jam perangkat untuk melewati slot.

## Penyimpanan bersama website

- Login: `users`, `ck_pppk_access`, limiter login existing, `mobile_api_tokens`.
- Profil: `employee_profiles`; perubahan terlihat di website.
- Cuti: `cuti`, `cuti_detail`, `users.saldo_cuti`; satu tabel tambahan `ck_flutter_requests` untuk idempotensi.
- Jam kerja: `tracking_sessions`, `tracking_points` melalui API lama.
- Dokumentasi: `laporan` dan folder pegawai existing.
- PPPK: `ck_pppk_kinerja` dan helper seed legacy existing.
- Pengaturan: `settings`; kunci dibatasi whitelist.

## Catatan kapasitas

Daftar dipilih per bulan; data pegawai difilter berdasarkan nama/jenis. Belum ada pagination cursor. Untuk jumlah pegawai atau dokumentasi yang sangat besar, tambahkan paging pada API dan UI sebelum memperluas penggunaan. Aplikasi tidak menyimpan cache data personal offline. Foto formulir yang belum terkirim hilang saat halaman/aplikasi ditutup.
