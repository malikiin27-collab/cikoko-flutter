<?php
require __DIR__.'/common.php';mobileRequireMethod('POST');$u=fxAuth();if($u['role']!=='pppk')mobileJson(['ok'=>false,'message'=>'Khusus PPPK.'],403);require_once FX_ROOT.'/pppk_kinerja.php';
$err='';$msg=!empty($_GET['saved'])?'Laporan berhasil disimpan.':(!empty($_GET['sent'])?'Laporan berhasil dikirim ke admin.':'');$uid=(int)$u['id'];$month=(string)($_POST['month_key']??$_GET['month']??date('Y-m'));if(!preg_match('/^20[0-9]{2}-(0[1-9]|1[0-2])$/',$month))$month=date('Y-m');
$row=null;$data=[];$available=false;
try{ckPppkSchema();$available=true;$row=ckPppkGet($uid,$month);$data=$row?$row['data']:ckPppkSeed($uid,$month);}catch(Throwable $e){error_log('[PPPK schema] '.$e->getMessage());$err='Layanan laporan sementara belum tersedia. Silakan hubungi pengelola layanan.';}
$type=(string)($_POST['report_type']??$_GET['type']??$data['report_type']??'lapangan');if(!in_array($type,['admin','lapangan'],true))$type='lapangan';
if($_SERVER['REQUEST_METHOD']==='POST'&&$available){
 $newFiles=[];$committed=false;$db=db();
 try{
  if(empty($_POST)&&((int)($_SERVER['CONTENT_LENGTH']??0)>0))throw new RuntimeException('Total unggahan melebihi batas server. Pilih foto lebih kecil atau unggah bertahap.');
  if($month>date('Y-m'))throw new RuntimeException('Bulan laporan tidak boleh melebihi bulan berjalan.');$action=(string)($_POST['action_button']??$_POST['action']??'draft');if(!in_array($action,['draft','submit'],true))throw new RuntimeException('Pilih Simpan Draf atau Kirim ke Admin.');
  $db->beginTransaction();
  // Serialize requests for this employee, including the first save of a month.
  $s=$db->prepare("SELECT id FROM users WHERE id=? AND role='pppk' AND status='active' FOR UPDATE");$s->execute([$uid]);if(!$s->fetch())throw new RuntimeException('Akun PPPK tidak aktif.');
  $current=ckPppkGet($uid,$month);$revision=$current?(int)$current['revision']:0;if((int)($_POST['revision']??-1)!==$revision)throw new RuntimeException('Laporan telah berubah di tab lain. Muat ulang halaman sebelum menyimpan kembali.');
  $old=$current?$current['data']:ckPppkSeed($uid,$month);if($current&&$current['report_type']!==$type)throw new RuntimeException('Jenis laporan bulan ini sudah ditetapkan. Gunakan jenis yang tersimpan agar foto tidak hilang.');
  $job=trim((string)($_POST['member_jabatan']??''));if($job===''||strlen($job)>300)throw new RuntimeException('Isi jabatan pegawai dengan benar.');
  $date=(string)($_POST['signed_date']??date('Y-m-d'));$dt=DateTime::createFromFormat('!Y-m-d',$date);if(!$dt||$dt->format('Y-m-d')!==$date)throw new RuntimeException('Tanggal laporan tidak valid.');
  $prepared=[];$hasEvidence=false;$dir=employeeDir($u).'/pppk/'.$month;if(!is_dir($dir)&&!mkdir($dir,0755,true)&&!is_dir($dir))throw new RuntimeException('Folder laporan tidak dapat dibuat.');
  foreach(ckPppkIndicators($type) as $code=>$label){$item=$old['items'][$code]??[];$item['indicator_code']=$code;$item['indicator']=$label;
   foreach([1,2] as $slot){$field='photo_'.$slot.'_'.$code;$path=(string)($item['photo_'.$slot.'_path']??'');if(!empty($_FILES[$field]['name'])){if(!@getimagesize($_FILES[$field]['tmp_name']))throw new RuntimeException('Berkas harus berupa foto JPEG, PNG, atau WebP yang valid.');$f=uploadSafe($field,$dir,['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp']);if(!$f)throw new RuntimeException('Foto gagal disimpan.');$newFiles[]=$dir.'/'.$f;$path='storage/pegawai/'.$u['folder_code'].'/pppk/'.$month.'/'.$f;}
    $progress=(string)($_POST['progress_'.$slot][$code]??ckLegacy_progress_status_from_caption($code,(string)($item['photo_'.$slot.'_caption']??'')));if(!in_array($progress,['','done','not_done'],true))throw new RuntimeException('Pilih keterangan progres yang valid.');$caption=ckLegacy_progress_caption($code,$progress,$slot);if(strlen($caption)>6000)throw new RuntimeException('Keterangan foto terlalu panjang.');if($path!==''&&$caption==='')throw new RuntimeException('Isi keterangan untuk foto '.$label.' periode '.$slot.'.');$item['photo_'.$slot.'_path']=$path;$item['photo_'.$slot.'_caption']=$caption;if($path!==''&&$caption!=='')$hasEvidence=true;
   }$prepared[$code]=$item;
  }
  if($action==='submit'&&!$hasEvidence)throw new RuntimeException('Tambahkan minimal satu foto kegiatan beserta keterangannya sebelum mengirim. Foto periode lain dapat dilengkapi kemudian.');
  $payload=['report_type'=>$type,'month_key'=>$month,'member_name'=>$u['nama_lengkap'],'member_nip'=>$u['nomor_pegawai']??'','member_jabatan'=>$job,'member_unit'=>'Kelurahan Cikoko','leader_name'=>setting('nama_lurah'),'leader_nip'=>setting('nip_lurah'),'leader_jabatan'=>setting('jabatan_lurah','Lurah Kelurahan Cikoko'),'signed_date'=>$date,'items'=>$prepared];$json=json_encode($payload,JSON_UNESCAPED_UNICODE);if(!is_string($json)||$json==='')throw new RuntimeException('Data laporan tidak dapat dikodekan.');$status=$action==='submit'?'submitted':'draft';
  if($current){$s=$db->prepare('UPDATE ck_pppk_kinerja SET report_type=?,status=?,revision=revision+1,payload=?,submitted_at=? WHERE id=? AND user_id=? AND revision=?');$s->execute([$type,$status,$json,$action==='submit'?date('Y-m-d H:i:s'):null,(int)$current['id'],$uid,$revision]);if($s->rowCount()!==1)throw new RuntimeException('Laporan berubah, mohon muat ulang halaman.');}
  else{$s=$db->prepare('INSERT INTO ck_pppk_kinerja(user_id,month_key,report_type,status,revision,payload,submitted_at) VALUES(?,?,?,?,1,?,?)');$s->execute([$uid,$month,$type,$status,$json,$action==='submit'?date('Y-m-d H:i:s'):null]);}
  $db->commit();$committed=true;audit($uid,($action==='submit'?'Mengirim':'Menyimpan draf').' laporan kinerja PPPK '.$month);$redirectParams=['month'=>$month];$redirectParams[$action==='submit'?'sent':'saved']=1;mobileJson(['ok'=>true,'message'=>'Laporan tersimpan.']);
 }catch(Throwable $e){if($db->inTransaction())$db->rollBack();if(!$committed)foreach($newFiles as $f)if(is_file($f))@unlink($f);error_log('[PPPK save] '.$e->getMessage());$err=userError($e);}
}

mobileJson(['ok'=>false,'message'=>$err?:'Laporan belum tersimpan.'],400);
