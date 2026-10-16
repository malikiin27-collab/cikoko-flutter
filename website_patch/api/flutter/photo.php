<?php
require __DIR__.'/common.php';mobileRequireMethod('POST');$u=fxAuth();fxEmployee($u);$path=null;
try{
 ensureShiftPhotoSchema();$d=mobileRequestData();$s=activeTrackingSession((int)$u['id']);if(!$s)throw new RuntimeException('Mulai jam kerja terlebih dahulu.');
 $slot=(int)floor((time()-strtotime($s['checkin_at']))/7200);$index=(int)($d['index']??0);if($slot<0||$slot>3||$index<1||$index>12)throw new RuntimeException('Periode atau nomor foto tidak valid.');
 $lat=mobileNum($d,'lat');$lng=mobileNum($d,'lng');$acc=mobileNum($d,'acc');if(!mobileValidPoint($lat,$lng,$acc)||$acc===null||$acc>30||$acc<=0)throw new RuntimeException('Tunggu GPS lebih akurat (maksimal 30 meter).');
 require_once dirname(__DIR__).'/mobile/tracking_v9.php';trackingRequireCurrentFix($d['fix_epoch']??null);
 $dir=employeeDir($u).'/laporan';$file=uploadSafe('photo',$dir,['image/jpeg'=>'jpg'],10485760);if(!$file)throw new RuntimeException('Foto wajib diambil.');$path=$dir.'/'.$file;
 $label='LAPORAN '.($slot+1).'/4 - FOTO '.$index.'/12';$now=date('Y-m-d H:i:s');cikokoSealPhoto($path,$label,$u,$now,$lat,$lng);
 if(filesize($path)>1048576){$packed=compressUploadedImage($path,$dir,'image/jpeg',950000);unlink($path);$path=$dir.'/'.$packed;}
 $proof=['v'=>1,'uid'=>(int)$u['id'],'label'=>$label,'issued'=>time(),'time'=>$now,'lat'=>$lat,'lng'=>$lng,'acc'=>$acc,'session'=>(int)$s['id'],'nonce'=>bin2hex(random_bytes(8)),'digest'=>hash_file('sha256',$path)];
 $bytes=base64_encode(file_get_contents($path));unlink($path);$path=null;
 mobileJson(['ok'=>true,'image_base64'=>$bytes,'token'=>cikokoCaptureSign($proof),'session_id'=>(int)$s['id'],'slot'=>$slot,'index'=>$index]);
}catch(Throwable $e){if($path&&is_file($path))unlink($path);fxFailure($e);}
