<?php
declare(strict_types=1);
require __DIR__.'/common.php';
$action=(string)($_GET['action']??'me');$method=$_SERVER['REQUEST_METHOD']??'GET';$d=mobileRequestData();
try {
 if($action==='login'){
  mobileRequireMethod('POST');require_once FX_ROOT.'/login-security.php';
  $u=ckAuthVerify(fxText($d,'username',190,true),(string)($d['password']??''));
  if(!in_array($u['role'],['admin','pjlp','pppk'],true))throw new RuntimeException('Peran tidak didukung.');
  $t=mobileIssueToken((int)$u['id'],'','Flutter Cikoko','1.0.0',7);
  mobileJson(['ok'=>true,'token'=>$t['token'],'expires_at'=>$t['expires_at'],'user'=>fxPublic(currentEmployee((int)$u['id']))]);
 }
 $u=fxAuth();$uid=(int)$u['id'];$admin=$u['role']==='admin';
 ensureCikokoAdvancedSchema();ensureShiftPhotoSchema();
 if($action==='me'){mobileRequireMethod('GET');mobileJson(['ok'=>true,'user'=>fxPublic($u),'server_time'=>date(DATE_ATOM)]);}
 if($action==='logout'){mobileRequireMethod('POST');db()->prepare('UPDATE mobile_api_tokens SET revoked_at=NOW() WHERE id=?')->execute([$u['_token_id']]);mobileJson(['ok'=>true]);}
 $read=['dashboard','employees','leaves','attendance','reports','settings','monthly'];
 if(in_array($action,$read,true)){
  mobileRequireMethod('GET');$month=fxMonth((string)($_GET['month']??date('Y-m')));[$scope,$args]=fxScope($u,'t.user_id');
  if($action==='dashboard'){
   $all=$admin?"SELECT COUNT(*) n FROM users WHERE role IN ('pjlp','pppk') AND status='active'":"SELECT saldo_cuti n FROM users WHERE id=".$uid;
   $stats=['pegawai'=>fxOne($all)['n']??0,'cuti'=>fxOne("SELECT COUNT(*) n FROM cuti t WHERE $scope AND t.status='pending'",$args)['n']??0,'laporan'=>fxOne("SELECT COUNT(*) n FROM laporan t WHERE $scope AND DATE_FORMAT(t.waktu_lokasi,'%Y-%m')=?",array_merge($args,[$month]))['n']??0,'hadir'=>fxOne("SELECT COUNT(DISTINCT t.user_id) n FROM tracking_sessions t WHERE $scope AND DATE(t.checkin_at)=CURDATE()",$args)['n']??0];
   mobileJson(['ok'=>true,'stats'=>$stats,'user'=>fxPublic($u),'active'=>$admin?null:(activeTrackingSession($uid)?:null)]);
  }
  if($action==='employees'){
   if(!$admin)mobileJson(['ok'=>false,'message'=>'Khusus admin.'],403);
   $q='%'.substr((string)($_GET['q']??''),0,100).'%';$role=(string)($_GET['role']??'');$sql="SELECT id,role,nama_lengkap,nomor_pegawai,status,saldo_cuti,username FROM users WHERE role IN('pjlp','pppk') AND (nama_lengkap LIKE ? OR nomor_pegawai LIKE ?)";$p=[$q,$q];if(in_array($role,['pjlp','pppk'],true)){$sql.=' AND role=?';$p[]=$role;}
   mobileJson(['ok'=>true,'items'=>fxQuery($sql.' ORDER BY nama_lengkap',$p)]);
  }
  if($action==='leaves')mobileJson(['ok'=>true,'balance'=>(int)($u['saldo_cuti']??0),'items'=>fxQuery("SELECT t.*,v.nama_lengkap,v.role,d.decision_number,d.phone,d.service_period FROM cuti t JOIN users v ON v.id=t.user_id LEFT JOIN cuti_detail d ON d.cuti_id=t.id WHERE $scope AND DATE_FORMAT(t.tanggal_mulai,'%Y-%m')=? ORDER BY t.id DESC",array_merge($args,[$month]))]);
  if($action==='attendance')mobileJson(['ok'=>true,'active'=>$admin?null:(activeTrackingSession($uid)?:null),'items'=>fxQuery("SELECT t.id,t.user_id,v.nama_lengkap,v.role,t.checkin_at,t.checkout_at,t.status,t.checkin_lat,t.checkin_lng,t.checkout_lat,t.checkout_lng,TIMESTAMPDIFF(MINUTE,t.checkin_at,COALESCE(t.checkout_at,NOW())) duration_minutes FROM tracking_sessions t JOIN users v ON v.id=t.user_id WHERE $scope AND DATE_FORMAT(t.checkin_at,'%Y-%m')=? ORDER BY t.id DESC",array_merge($args,[$month]))]);
  if($action==='reports'){
   $active=$admin?null:activeTrackingSession($uid);$slot=$active?(int)floor((time()-strtotime($active['checkin_at']))/7200):-1;
   $counts=$active?cikokoShiftPhotoCounts($uid,(int)$active['id']):[0,0,0,0];
   mobileJson(['ok'=>true,'active'=>$active?:null,'slot'=>$slot,'counts'=>$counts,'items'=>fxQuery("SELECT t.id,t.user_id,v.nama_lengkap,v.role,t.keterangan,t.waktu_lokasi,t.report_slot,t.photo_index,t.latitude,t.longitude FROM laporan t JOIN users v ON v.id=t.user_id WHERE $scope AND DATE_FORMAT(t.waktu_lokasi,'%Y-%m')=? ORDER BY t.id DESC",array_merge($args,[$month]))]);
  }
  if($action==='monthly'){
   require_once FX_ROOT.'/pppk_kinerja.php';ckPppkSchema();
   if($admin){mobileJson(['ok'=>true,'items'=>fxQuery('SELECT k.id,k.user_id,u.nama_lengkap,k.month_key,k.status,k.report_type,k.payload,k.revision FROM ck_pppk_kinerja k JOIN users u ON u.id=k.user_id WHERE k.month_key=? ORDER BY u.nama_lengkap',[$month])]);}
   if($u['role']!=='pppk')mobileJson(['ok'=>false,'message'=>'Khusus PPPK.'],403);
   $row=ckPppkGet($uid,$month);$data=$row?$row['data']:ckPppkSeed($uid,$month);$type=$row['report_type']??($_GET['type']??'lapangan');if(!in_array($type,['admin','lapangan'],true))$type='lapangan';
   mobileJson(['ok'=>true,'row'=>$row,'data'=>$data,'type'=>$type,'indicators'=>ckPppkIndicators($type)]);
  }
  if($action==='settings'){
   if(!$admin)mobileJson(['ok'=>false,'message'=>'Khusus admin.'],403);$out=[];foreach(['nama_lurah','nip_lurah','jabatan_lurah','nama_atasan','nip_atasan','jabatan_atasan','alamat','telepon','letter_title_pjlp','letter_title_pppk','letter_to'] as $key)$out[$key]=setting($key);mobileJson(['ok'=>true,'settings'=>$out]);
  }
 }
 mobileRequireMethod('POST');
 if($action==='leave_create'){fxEmployee($u);require __DIR__.'/leave_create.php';}
 if($action==='leave_review'){if(!$admin)mobileJson(['ok'=>false,'message'=>'Khusus admin.'],403);require __DIR__.'/leave_review.php';}
 if($action==='profile'){
  fxEmployee($u);$p=getEmployeeProfile($uid);
  foreach(['no_hp','email','alamat','kontak_lain','akun_spse'] as $key)if(array_key_exists($key,$d))$p[$key]=fxText($d,$key,$key==='alamat'?1500:($key==='no_hp'?40:($key==='kontak_lain'?80:150)));
  if($p['email']!==''&&!filter_var($p['email'],FILTER_VALIDATE_EMAIL))throw new RuntimeException('Email tidak valid.');
  foreach(['no_hp','kontak_lain'] as $key)if($p[$key]!==''&&!preg_match('/^[0-9+().\-\s\/]+$/D',$p[$key]))throw new RuntimeException('Nomor kontak tidak valid.');
  if($u['role']==='pppk'){if($p['email']==='')throw new RuntimeException('Email login PPPK wajib diisi.');if(fxOne('SELECT user_id FROM employee_profiles WHERE LOWER(email)=? AND user_id<>?',[strtolower($p['email']),$uid]))throw new RuntimeException('Email sudah digunakan.');}
  saveEmployeeProfile($uid,$p);audit($uid,'Memperbarui profil melalui Flutter');mobileJson(['ok'=>true,'user'=>fxPublic(currentEmployee($uid))]);
 }
 if($action==='password'){
  $old=(string)($d['current_password']??'');$new=(string)($d['new_password']??'');if(!password_verify($old,$u['password']))throw new RuntimeException('Kata sandi saat ini tidak sesuai.');if(strlen($new)<12||strlen($new)>128)throw new RuntimeException('Kata sandi baru 12–128 karakter.');
  ensureRememberLoginSchema();db()->beginTransaction();db()->prepare('UPDATE users SET password=? WHERE id=?')->execute([password_hash($new,PASSWORD_DEFAULT),$uid]);db()->prepare('UPDATE mobile_api_tokens SET revoked_at=NOW() WHERE user_id=?')->execute([$uid]);db()->prepare('DELETE FROM remember_login_tokens WHERE user_id=?')->execute([$uid]);db()->commit();mobileJson(['ok'=>true,'message'=>'Kata sandi diganti. Masuk kembali.']);
 }
 if($action==='employee_save'){
  if(!$admin)mobileJson(['ok'=>false,'message'=>'Khusus admin.'],403);
  $id=(int)($d['id']??0);$name=fxText($d,'nama_lengkap',190,true);$number=fxText($d,'nomor_pegawai',100);$status=(string)($d['status']??'active');if(!in_array($status,['active','inactive'],true))throw new RuntimeException('Status tidak valid.');
  $balance=filter_var($d['saldo_cuti']??null,FILTER_VALIDATE_INT);if($balance===false||$balance<0||$balance>366)throw new RuntimeException('Saldo tidak valid.');
  if(!fxOne("SELECT id FROM users WHERE id=? AND role IN('pjlp','pppk')",[$id]))throw new RuntimeException('Pegawai tidak ditemukan.');
  db()->prepare('UPDATE users SET nama_lengkap=?,nomor_pegawai=?,status=?,saldo_cuti=? WHERE id=?')->execute([$name,$number,$status,$balance,$id]);audit($uid,'Edit pegawai melalui Flutter ID '.$id);mobileJson(['ok'=>true]);
 }
 if($action==='settings_save'){
  if(!$admin)mobileJson(['ok'=>false,'message'=>'Khusus admin.'],403);
  db()->beginTransaction();foreach(['nama_lurah','nip_lurah','jabatan_lurah','nama_atasan','nip_atasan','jabatan_atasan','alamat','telepon','letter_title_pjlp','letter_title_pppk','letter_to'] as $key){if(array_key_exists($key,$d))db()->prepare('INSERT INTO settings(setting_key,setting_value) VALUES(?,?) ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value)')->execute([$key,fxText($d,$key)]);}db()->commit();audit($uid,'Pengaturan pejabat via Flutter');mobileJson(['ok'=>true]);
 }
 mobileJson(['ok'=>false,'message'=>'Endpoint tidak ditemukan.'],404);
}catch(Throwable $e){fxFailure($e);}
