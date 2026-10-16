<?php
require __DIR__.'/common.php';mobileRequireMethod('GET');$u=fxAuth();
try{
 $id=(int)($_GET['id']??0);$r=fxOne('SELECT user_id,foto FROM laporan WHERE id=?',[$id]);if(!$r||($u['role']!=='admin'&&(int)$r['user_id']!==(int)$u['id']))mobileJson(['ok'=>false,'message'=>'Tidak ditemukan.'],404);
 $base=realpath(FX_ROOT.'/storage/pegawai');$file=realpath($base.'/'.$r['foto']);if(!$base||!$file||strpos($file,$base.DIRECTORY_SEPARATOR)!==0||!is_file($file))mobileJson(['ok'=>false,'message'=>'Foto tidak ditemukan.'],404);
 $mime=(new finfo(FILEINFO_MIME_TYPE))->file($file);if(!in_array($mime,['image/jpeg','image/png','image/webp'],true))throw new RuntimeException('Format tidak didukung.');header('Content-Type: '.$mime);readfile($file);
}catch(Throwable $e){fxFailure($e);}
