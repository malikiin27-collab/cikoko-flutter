<?php
require __DIR__.'/common.php';mobileRequireMethod('POST');$admin=fxAuth(true);$d=mobileRequestData();
try{
 require_once FX_ROOT.'/login-security.php';ckAuthReady();ensureEmployeeProfileSchema();
 $role=(string)($d['role']??'');if(!in_array($role,['pjlp','pppk'],true))throw new RuntimeException('Jenis pegawai tidak valid.');
 $name=fxText($d,'nama_lengkap',190,true);$username=fxText($d,'username',100,true);$number=fxText($d,'nomor_pegawai',100);$email=fxText($d,'email',150,$role==='pppk');$password=(string)($d['password']??'');$balance=filter_var($d['saldo_cuti']??0,FILTER_VALIDATE_INT);
 if(strlen($password)<12||strlen($password)>128)throw new RuntimeException('Kata sandi awal 12–128 karakter.');
 if($balance===false||$balance<0||$balance>366)throw new RuntimeException('Saldo tidak valid.');if($email!==''&&!filter_var($email,FILTER_VALIDATE_EMAIL))throw new RuntimeException('Email tidak valid.');
 db()->beginTransaction();if(fxOne('SELECT id FROM users WHERE username=?',[$username]))throw new RuntimeException('Username sudah digunakan.');if($email!==''&&fxOne('SELECT user_id FROM employee_profiles WHERE LOWER(email)=?',[strtolower($email)]))throw new RuntimeException('Email sudah digunakan.');
 $folder=strtoupper($role).'-'.date('YmdHis').'-'.bin2hex(random_bytes(4));
 db()->prepare("INSERT INTO users(role,username,password,nama_lengkap,nomor_pegawai,folder_code,saldo_cuti,status) VALUES(?,?,?,?,?,?,?,'active')")->execute([$role,$username,password_hash($password,PASSWORD_DEFAULT),$name,$number,$folder,$balance]);$id=(int)db()->lastInsertId();
 saveEmployeeProfile($id,['email'=>$email,'no_hp'=>'','alamat'=>'','kontak_lain'=>'','akun_spse'=>'','foto_profil'=>'']);
 if($role==='pppk')db()->prepare('INSERT INTO ck_pppk_access(user_id,email,pin_hash) VALUES(?,?,?)')->execute([$id,$email,'']);
 db()->commit();mobileJson(['ok'=>true,'id'=>$id]);
}catch(Throwable $e){fxFailure($e);}
