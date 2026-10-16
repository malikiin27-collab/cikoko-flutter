<?php
declare(strict_types=1);
require_once dirname(__DIR__).'/mobile/common.php';
define('FX_ROOT',dirname(__DIR__,2));
// Bearer authentication only. Never trust the browser session for API access.
function fxAuth(bool $admin=false):array {
 $raw=mobileBearerRaw();if($raw==='')mobileJson(['ok'=>false,'message'=>'Silakan masuk kembali.'],401);
 ensureMobileApiSchema();
 $q=db()->prepare("SELECT u.id,u.role,u.status,t.id token_id FROM mobile_api_tokens t JOIN users u ON u.id=t.user_id WHERE t.token_hash=? AND t.revoked_at IS NULL AND t.expires_at>NOW() LIMIT 1");
 $q->execute([hash('sha256',$raw)]);$r=$q->fetch();
 if(!$r||$r['status']!=='active'||!in_array($r['role'],['admin','pjlp','pppk'],true))mobileJson(['ok'=>false,'message'=>'Sesi berakhir atau akun tidak aktif.'],401);
 if($admin&&$r['role']!=='admin')mobileJson(['ok'=>false,'message'=>'Khusus admin.'],403);
 $u=currentEmployee((int)$r['id']);$u['_token_id']=(int)$r['token_id'];return $u;
}
function fxPublic(array $u):array {
 $keys=['id','role','username','nama_lengkap','nomor_pegawai','saldo_cuti','status','no_hp','email','alamat','kontak_lain','akun_spse'];$out=[];
 foreach($keys as $k)$out[$k]=$u[$k]??'';return $out;
}
function fxQuery(string $sql,array $args=[]):array {$q=db()->prepare($sql);$q->execute($args);return $q->fetchAll();}
function fxOne(string $sql,array $args=[]):array {return fxQuery($sql,$args)[0]??[];}
function fxDate(string $s):string {$d=DateTime::createFromFormat('!Y-m-d',$s);if(!$d||$d->format('Y-m-d')!==$s)throw new RuntimeException('Tanggal tidak valid.');return $s;}
function fxMonth(string $s):string {if(!preg_match('/^20\d{2}-(0[1-9]|1[0-2])$/D',$s))throw new RuntimeException('Bulan tidak valid.');return $s;}
function fxText(array $d,string $key,int $max=1500,bool $required=false):string {$v=trim((string)($d[$key]??''));if(($required&&$v==='')||strlen($v)>$max)throw new RuntimeException('Periksa kolom '.$key.'.');return $v;}
function fxEmployee(array $u):void {if(!in_array($u['role'],['pjlp','pppk'],true))mobileJson(['ok'=>false,'message'=>'Khusus pegawai.'],403);}
function fxScope(array $u,string $alias='user_id'):array {return $u['role']==='admin'?['1=1',[]]:[$alias.'=?',[(int)$u['id']]];}
function fxFailure(Throwable $e):void {if(db()->inTransaction())db()->rollBack();error_log('[Flutter API] '.$e->getMessage());mobileJson(['ok'=>false,'message'=>userError($e)],400);}
