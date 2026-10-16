<?php
require __DIR__.'/common.php';mobileRequireMethod('POST');$u=fxAuth();fxEmployee($u);ensureShiftPhotoSchema();$ajax=true;$err='';$msg='';$active=activeTrackingSession((int)$u['id']);
function mwV4Period(array $session): int {
 $elapsed=time()-strtotime((string)$session['checkin_at']);
 if($elapsed<0||$elapsed>=28800)throw new RuntimeException('Waktu pengiriman sesi telah berakhir.');
 return min(3,(int)floor($elapsed/7200));
}
function mwV4Limit($raw): int { $v=trim((string)$raw);if(!preg_match('/^([0-9]+)\s*([kmgt]?)b?$/i',$v,$m))return 0;return (int)$m[1]*(1024**(array(''=>0,'k'=>1,'m'=>2,'g'=>3,'t'=>4)[strtolower($m[2])])); }
if($_SERVER['REQUEST_METHOD']==='POST'){
 $written=array();$committed=false;$pdo=null;
 try{
  $postLimit=mwV4Limit(ini_get('post_max_size'));
  if($postLimit>0&&(int)($_SERVER['CONTENT_LENGTH']??0)>$postLimit)throw new RuntimeException('Ukuran unggahan melebihi batas server. Simpan lebih sedikit foto dalam sekali pengiriman.');
  
  if(!$active)throw new RuntimeException('Mulai bertugas terlebih dahulu.');
  $slot=mwV4Period($active);
  if((int)($_POST['session_id']??0)!==(int)$active['id']||(int)($_POST['report_slot']??-1)!==$slot)throw new RuntimeException('Periode atau sesi telah berubah. Muat ulang halaman sebelum mengambil foto baru.');
  $ket=trim((string)($_POST['keterangan']??''));
  if($ket===''||strlen($ket)>2000)throw new RuntimeException('Isi uraian kegiatan, maksimal 500 karakter.');
  $files=$_FILES['foto']??array();$selected=array();if(!is_array($files['name']??null))throw new RuntimeException('Data foto tidak dapat dibaca.');
  foreach(($files['name']??array()) as $index=>$name){
   if($name===''&&($files['error'][$index]??UPLOAD_ERR_NO_FILE)===UPLOAD_ERR_NO_FILE)continue;
   if(!preg_match('/^(?:[1-9]|1[0-2])$/D',(string)$index))throw new RuntimeException('Nomor foto tidak valid.');
   if(($files['error'][$index]??UPLOAD_ERR_NO_FILE)!==UPLOAD_ERR_OK)throw new RuntimeException('Foto '.$index.' gagal diunggah.');
   $selected[]=(int)$index;
  }
  if(!$selected)throw new RuntimeException('Ambil minimal satu foto sebelum menyimpan.');
  sort($selected);$pdo=db();$pdo->beginTransaction();
  // Semua pengiriman untuk sesi yang sama diserialkan. Foto tersimpan tidak pernah di-update.
  $lock=$pdo->prepare("SELECT id,checkin_at FROM tracking_sessions WHERE id=? AND user_id=? AND status='active' FOR UPDATE");
  $lock->execute(array((int)$active['id'],(int)$u['id']));$locked=$lock->fetch();
  if(!$locked||mwV4Period($locked)!==$slot)throw new RuntimeException('Sesi/periode telah berubah selama pengiriman. Foto belum disimpan.');
  $q=$pdo->prepare('SELECT photo_index,photo_sha256 FROM laporan WHERE user_id=? AND report_session_id=? AND report_slot=?');
  $q->execute(array((int)$u['id'],(int)$active['id'],$slot));$existing=array();
  foreach($q->fetchAll() as $row)$existing[(int)$row['photo_index']]=(string)$row['photo_sha256'];
  $dir=employeeDir($u).'/laporan';$when=date('Y-m-d H:i:s');$saved=0;$hashes=array_values($existing);
  $ins=$pdo->prepare('INSERT INTO laporan (user_id,latitude,longitude,accuracy,foto,keterangan,waktu_lokasi,report_session_id,report_slot,photo_index,photo_sha256) VALUES(?,?,?,?,?,?,?,?,?,?,?)');
  foreach($selected as $index){
   $label='LAPORAN '.($slot+1).'/4 - FOTO '.$index.'/12';
   $token=(string)($_POST['photo_stamp_tokens'][$index]??'');
   if($token==='')throw new RuntimeException('Foto '.$index.' belum memiliki cap waktu. Ambil kembali.');
   $proof=cikokoCaptureRead($token,(int)$u['id'],$label,true);
   if((int)($proof['session']??0)!==(int)$active['id'])throw new RuntimeException('Foto berasal dari sesi kerja berbeda.');
   $periodStart=strtotime((string)$locked['checkin_at'])+$slot*7200;
   if((int)($proof['issued']??0)<$periodStart||(int)($proof['issued']??0)>=$periodStart+7200)throw new RuntimeException('Foto harus diambil pada periode dua jam yang sedang berjalan.');
   $raw=hash_file('sha256',(string)$files['tmp_name'][$index]);
   if(!is_string($raw)||!hash_equals((string)$proof['digest'],$raw))throw new RuntimeException('Foto berubah setelah cap waktu dibuat.');
   if(isset($existing[$index])){
    if(hash_equals($existing[$index],$raw))continue; // Aman untuk retry setelah respons jaringan hilang.
    throw new RuntimeException('Foto '.$index.' sudah tersimpan dan terkunci.');
   }
   if(in_array($raw,$hashes,true))throw new RuntimeException('Foto yang sama tidak boleh digunakan pada dua nomor.');
   foreach(array('lat','lng','acc') as $key)if(!isset($proof[$key])||!is_numeric($proof[$key]))throw new RuntimeException('Bukti GPS tidak valid.');
   $lat=(float)$proof['lat'];$lng=(float)$proof['lng'];$acc=(float)$proof['acc'];
   if($lat<-90||$lat>90||$lng<-180||$lng>180||$acc<0||$acc>2000)throw new RuntimeException('Koordinat GPS di luar batas.');
   $_FILES['mw_v4_one']=array('name'=>$files['name'][$index],'type'=>$files['type'][$index]??'','tmp_name'=>$files['tmp_name'][$index],'size'=>$files['size'][$index]??0,'error'=>$files['error'][$index]);
   $file=uploadSafe('mw_v4_one',$dir,array('image/jpeg'=>'jpg'),12582912);
   if(!$file)throw new RuntimeException('Foto '.$index.' gagal disimpan.');
   $path=$dir.'/'.$file;$written[]=$path;
   $hash=cikokoAcceptPhoto($path,$label,$u,$when,$lat,$lng,$token);$hashes[]=$hash;
   $ins->execute(array((int)$u['id'],$lat,$lng,$acc,$u['folder_code'].'/laporan/'.$file,$ket,$when,(int)$active['id'],$slot,$index,$hash));$saved++;
  }
  unset($_FILES['mw_v4_one']);$pdo->commit();$committed=true;
  $msg=$saved>0?$saved.' foto berhasil disimpan. Foto tersimpan terkunci; slot lainnya dapat dilengkapi selama periode ini.':'Foto ini sudah tersimpan sebelumnya. Tidak ada duplikasi.';
  try{audit((int)$u['id'],'Menyimpan '.$saved.' foto periode '.($slot+1).' (kuota 12)');}catch(Throwable $auditError){error_log('Cikoko report audit unavailable');}
 }catch(Throwable $e){if($pdo&&$pdo->inTransaction())$pdo->rollBack();if(!$committed)foreach($written as $path)@unlink($path);$err=userError($e);}
 if($ajax){header('Content-Type: application/json; charset=utf-8');if($err!=='')http_response_code(400);echo json_encode(array('ok'=>$err==='','message'=>$err!==''?$err:$msg));exit;}
}
