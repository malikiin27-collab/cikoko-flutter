# Pemetaan mockup ke implementasi

Semua angka/nama contoh dari mockup diganti data server. Tidak ada mode yang diam-diam menganggap penyimpanan berhasil saat server gagal.

## Admin

| Mockup | Implementasi paket |
|---|---|
| Beranda compact | Ringkasan pegawai aktif, hadir hari ini, cuti pending, jumlah foto bulan berjalan; akses cepat |
| Data pegawai | Cari nama/NIP, filter PJLP/PPPK, tambah akun, detail, edit nama/nomor/status/saldo, PDF |
| Cuti | Filter bulan, detail lengkap, setujui dengan nomor surat, tolak dengan alasan, rekap PDF dan surat resmi |
| Jam kerja | Daftar waktu mulai–selesai, koordinat, total durasi, rekap landscape |
| Pusat laporan | Dokumentasi harian semua pegawai dan laporan bulanan PPPK, tanggal cetak, pratinjau/share/cetak PDF |
| Pengaturan | Nama/NIP/jabatan lurah dan atasan, identitas kelurahan, format surat, kata sandi admin |
| Hak akses | Mengikuti role server; tidak ada editor hak akses granular baru |
| QR, foto/TTD pejabat | Belum diimplementasikan; memerlukan pemetaan patch website terbaru |
| PPPK Kecamatan Pancoran | Belum diimplementasikan. Sumber website memakai koneksi lintas-unit dengan verifikasi admin pusat; aplikasi ini hanya lingkup Cikoko |

## PJLP

| Mockup | Implementasi paket |
|---|---|
| Beranda | Ringkasan pribadi dan sesi aktif |
| Jam kerja | Kamera + GPS untuk check-in/check-out, riwayat dan total waktu |
| Laporan saya | Riwayat foto, detail gambar, filter bulan, rekap PDF |
| Buat laporan | Satu foto per kiriman untuk nomor 1–12 pada periode kerja aktif; dapat diulang untuk melengkapi periode |
| Cuti | Multi-tanggal, perhitungan saldo, identitas pekerjaan/alamat/kontak, riwayat dan catatan admin |
| Profil | Kontak, email, alamat, SPSE, foto profil, biodata PDF, ubah kata sandi |
| Draf laporan harian offline | Belum tersedia. Foto yang belum dikirim hanya berada dalam memori formulir |
| Dokumen pribadi | Belum ada pengelolaan dokumen pribadi pada API ini |

## PPPK Cikoko

Fitur pribadi sama dengan PJLP. Menu Kinerja menambahkan formulir bulanan yang mengikuti website:

- Jenis administratif atau lapangan, bulan laporan, jabatan, tanggal laporan.
- Indikator baku dari `ckPppkIndicators`.
- Bukti dan progres periode 1 serta periode 2.
- Draf tersimpan di server, kirim ke admin, revision conflict untuk perubahan paralel.
- Foto lama dipertahankan jika tidak diganti.

Mockup input hasil bebas (jumlah/satuan seperti “12 berkas”) tidak dibuat sebagai tabel baru. Sumber website memakai indikator dan foto; memasukkan data bebas itu tanpa pemetaan akan membuat aplikasi tidak selaras dengan website.

## Perbedaan penting yang disengaja

1. **Surat cuti:** pegawai melihat status; surat resmi dicetak admin setelah disetujui, sesuai sumber website.
2. **Saldo:** sumber website mencadangkan saldo saat pengajuan, bukan baru setelah persetujuan. UI mengikuti aturan server tersebut.
3. **Tanggal terpisah:** 19 dan 21 Oktober dihitung dua hari, disimpan menjadi dua rentang pengajuan pada tabel website. Tidak mengikutkan tanggal 20.
4. **Bentrok:** paket mencegah duplikasi tanggal pada pegawai yang sama. Pembatasan satu tanggal untuk semua pegawai lintas kanal belum diterapkan karena arsip website tidak mempunyai aturan tersebut; menambahkan hanya pada aplikasi akan membuat perilaku web dan aplikasi berbeda.
5. **Jam kerja:** total adalah selisih waktu tercatat, bukan perhitungan lembur/upah dan tidak otomatis mengurangi istirahat.
6. **Lokasi:** koordinat awal/akhir tersedia; nama lokasi tidak direkayasa melalui reverse geocoding. Tidak ada tracking background kontinu pada versi ini.
7. **PDF native:** rekap data landscape tanpa tanda tangan digital atau klaim verifikasi. PDF PPPK native masih ringkasan indikator/keterangan, belum menyertakan semua foto dan QR/TTD format resmi. Surat cuti memanggil engine PDF website yang sudah ada.
8. **Notifikasi:** belum ada push notification atau lonceng berisi pesan contoh. Ringkasan diperbarui saat halaman dibuka/ditarik.
9. **Cakupan data:** layar bulanan memakai `ck_pppk_kinerja` Cikoko. Arsip lintas unit/legacy yang hanya tersedia dari koneksi database pusat tidak digabung sebagai data baru.

## Pengembangan berikutnya yang membutuhkan sumber website terbaru

Pemetaan QR/TTD, cetak kinerja resmi terakhir, akses/lock PPPK Pancoran, aturan bentrok lintas pegawai, dan aturan cuti dari patch terbaru harus diambil dari ZIP website aktif. Jangan menebak nama tabel atau menghapus pemeriksaan akses admin pusat untuk membuat fitur tersebut terlihat berjalan.
