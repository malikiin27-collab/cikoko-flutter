<?php
if(!defined('FX_ROOT')){http_response_code(404);exit;} 
$id=(int)($d['id']??0);$decision=(string)($d['decision']??'');$note=fxText($d,'note');
if(!in_array($decision,['approve','reject'],true))throw new RuntimeException('Keputusan tidak valid.');
$number=$decision==='approve'?fxText($d,'decision_number',100,true):'';$date=fxDate((string)($d['decision_date']??date('Y-m-d')));
if($decision==='reject'&&$note==='')throw new RuntimeException('Alasan penolakan wajib diisi.');
db()->beginTransaction();$c=fxOne('SELECT * FROM cuti WHERE id=? FOR UPDATE',[$id]);if(!$c)throw new RuntimeException('Pengajuan tidak ditemukan.');if($c['status']!=='pending')throw new RuntimeException('Pengajuan sudah diproses. Muat ulang daftar.');
$status=$decision==='approve'?'approved':'rejected';
db()->prepare('UPDATE cuti SET status=?,catatan_admin=?,saldo_dikembalikan=?,updated_at=NOW() WHERE id=?')->execute([$status,$note,$decision==='reject'?1:0,$id]);
if($decision==='reject')db()->prepare('UPDATE users SET saldo_cuti=saldo_cuti+? WHERE id=?')->execute([(int)$c['jumlah_hari'],(int)$c['user_id']]);
db()->prepare('UPDATE cuti_detail SET supervisor_status=?,leader_status=?,supervisor_reason=?,leader_reason=?,decision_number=?,decision_date=?,verified_at=NOW(),verified_by=? WHERE cuti_id=?')->execute([$status,$status,$note,$note,$number,$date,$uid,$id]);db()->commit();audit($uid,'Verifikasi cuti melalui Flutter ID '.$id);mobileJson(['ok'=>true]);
