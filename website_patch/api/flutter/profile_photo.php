<?php
require __DIR__.'/common.php';$u=fxAuth();fxEmployee($u);$uid=(int)$u['id'];
try{
 $dir=employeeDir($u).'/profil';
 if(($_SERVER['REQUEST_METHOD']??'GET')==='POST'){
  $file=uploadSafe('photo',$dir,['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'],5242880);if(!$file)throw new RuntimeException('Pilih foto.');$profile=getEmployeeProfile($uid);$profile['foto_profil']=$file;
  try{saveEmployeeProfile($uid,$profile);}catch(Throwable $e){@unlink($dir.'/'.$file);throw $e;}
  mobileJson(['ok'=>true]);
 }
 mobileRequireMethod('GET');$p=getEmployeeProfile($uid);$base=realpath($dir);$file=$base?realpath($base.'/'.basename((string)($p['foto_profil']??''))):false;
 if(!$file||!$base||strpos($file,$base.DIRECTORY_SEPARATOR)!==0||!is_file($file))mobileJson(['ok'=>false,'message'=>'Foto belum tersedia.'],404);
 $mime=(new finfo(FILEINFO_MIME_TYPE))->file($file);if(!in_array($mime,['image/jpeg','image/png','image/webp'],true))throw new RuntimeException('Format tidak valid.');header('Content-Type: '.$mime);readfile($file);
}catch(Throwable $e){fxFailure($e);}
