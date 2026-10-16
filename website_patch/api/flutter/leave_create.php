<?php
if(!defined('FX_ROOT')){http_response_code(404);exit;} 
// Included only after bearer employee authentication and POST enforcement.
$dates=$d['dates']??[];if(!is_array($dates)||!$dates)throw new RuntimeException('Pilih tanggal cuti.');
$dates=array_values(array_unique(array_map('strval',$dates)));sort($dates);if(count($dates)>366)throw new RuntimeException('Terlalu banyak tanggal.');
foreach($dates as $date){fxDate($date);if($date<date('Y-m-d'))throw new RuntimeException('Tanggal cuti tidak boleh sudah lewat.');}
$reason=fxText($d,'reason',1500,true);$address=fxText($d,'leave_address',1500,true);$phone=fxText($d,'phone',40,true);$service=fxText($d,'service_period',100,true);
$position=fxText($d,'position_name',150,true);$key=fxText($d,'request_id',64,true);if(!preg_match('/^[a-zA-Z0-9_-]{16,64}$/D',$key))throw new RuntimeException('ID permintaan tidak valid.');
db()->exec("CREATE TABLE IF NOT EXISTS ck_flutter_requests(user_id INT UNSIGNED NOT NULL,request_id VARCHAR(64) NOT NULL,response_json TEXT NULL,PRIMARY KEY(user_id,request_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
$fingerprint=hash('sha256',json_encode([$dates,$reason,$address,$phone,$service,$position]));
db()->beginTransaction();
// Account lock serializes balance mutations with legacy website submissions.
$locked=fxOne('SELECT saldo_cuti FROM users WHERE id=? FOR UPDATE',[$uid]);
$old=fxOne('SELECT response_json FROM ck_flutter_requests WHERE user_id=? AND request_id=?',[$uid,$key]);if($old){$saved=json_decode($old['response_json'],true);if(($saved['request_fingerprint']??'')!==$fingerprint)throw new RuntimeException('Permintaan sebelumnya sudah tersimpan. Muat ulang daftar sebelum membuat pengajuan baru.');db()->commit();mobileJson($saved);}
$balance=(int)$locked['saldo_cuti'];$days=count($dates);if($days>$balance)throw new RuntimeException('Saldo cuti tidak mencukupi.');
foreach($dates as $date){if(fxOne("SELECT id FROM cuti WHERE user_id=? AND status IN('pending','approved') AND tanggal_mulai<=? AND tanggal_selesai>=?",[$uid,$date,$date]))throw new RuntimeException('Anda sudah mengajukan cuti pada '.$date.'.');}
// Split non-contiguous selection into contiguous ranges understood by existing website.
$ranges=[];foreach($dates as $date){$last=count($ranges)-1;if($last>=0&&date('Y-m-d',strtotime($ranges[$last][1].' +1 day'))===$date){$ranges[$last][1]=$date;$ranges[$last][2]++;}else $ranges[]=[$date,$date,1];}
$ids=[];foreach($ranges as [$start,$end,$count]){
 db()->prepare("INSERT INTO cuti(user_id,jenis_cuti,tanggal_mulai,tanggal_selesai,jumlah_hari,alasan,alamat_cuti,status) VALUES(?,?,?,?,?,?,?,'pending')")->execute([$uid,'Cuti Tahunan',$start,$end,$count,$reason,$address]);$id=(int)db()->lastInsertId();$ids[]=$id;
 db()->prepare('INSERT INTO cuti_detail(cuti_id,letter_city,letter_date_text,position_name,work_unit,employee_id_text,service_period,duration_text,phone,notes_json,submitted_at) VALUES(?,?,?,?,?,?,?,?,?,?,NOW())')->execute([$id,'Jakarta',date('d-m-Y'),$position,'Kelurahan Cikoko',$u['nomor_pegawai']??'',$service,$count.' hari',$phone,json_encode([['year'=>date('Y'),'remaining'=>$balance-$days,'description'=>'Pengajuan Flutter']])]);
}
db()->prepare('UPDATE users SET saldo_cuti=saldo_cuti-? WHERE id=?')->execute([$days,$uid]);
$result=['ok'=>true,'request_fingerprint'=>$fingerprint,'ids'=>$ids,'balance'=>$balance-$days,'message'=>'Pengajuan disimpan. Saldo dicadangkan.'];
db()->prepare('INSERT INTO ck_flutter_requests(user_id,request_id,response_json) VALUES(?,?,?)')->execute([$uid,$key,json_encode($result)]);db()->commit();mobileJson($result);
