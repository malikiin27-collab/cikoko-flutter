<?php
require __DIR__.'/common.php';mobileRequireMethod('GET');$u=fxAuth(true);
try{
 ensureCikokoAdvancedSchema();$id=(int)($_GET['id']??0);$r=fxOne('SELECT c.*,u.nama_lengkap,u.nomor_pegawai,u.role,d.* FROM cuti c JOIN users u ON u.id=c.user_id LEFT JOIN cuti_detail d ON d.cuti_id=c.id WHERE c.id=?',[$id]);
 if(!$r||$r['status']!=='approved')throw new RuntimeException('Surat hanya tersedia setelah disetujui.');
 require_once FX_ROOT.'/storage/install/cuti-pdf-engine.php';$sign=[];foreach(['nama_atasan','nip_atasan','jabatan_atasan','nama_lurah','nip_lurah','jabatan_lurah'] as $k)$sign[$k]=setting($k,'-');
 $pdf=buildCikokoLeavePdf($r,$sign);if(strncmp($pdf,'%PDF-',5)!==0)throw new RuntimeException('PDF tidak valid.');header('Content-Type: application/pdf');header('Content-Disposition: attachment; filename="Surat-Cuti-Cikoko-'.$id.'.pdf"');echo $pdf;
}catch(Throwable $e){fxFailure($e);}
