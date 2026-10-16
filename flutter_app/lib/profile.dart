import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'api.dart';import 'ui.dart';import 'export.dart';
class ProfilePage extends StatefulWidget{
 final Api api;final Future<void> Function() onLogout;const ProfilePage({super.key,required this.api,required this.onLogout});
 @override State<ProfilePage> createState()=>_ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage>{
 int version=0;
 Future<void> changePhoto()async{try{final photo=await ImagePicker().pickImage(source:ImageSource.gallery,maxWidth:1280,imageQuality:85);if(photo==null)return;await widget.api.request('flutter/profile_photo.php',data:FormData.fromMap({'photo':await MultipartFile.fromFile(photo.path,filename:'profile.jpg')}));if(mounted)setState(()=>version++);}catch(e){if(mounted)showFailure(context,e);}}
 @override Widget build(BuildContext context)=>Remote(key:ValueKey(version),load:()=>widget.api.call('me'),builder:(d){final u=Map<String,dynamic>.from(d['user'] as Map);return ListView(padding:const EdgeInsets.all(16),physics:const AlwaysScrollableScrollPhysics(),children:[Panel(child:Column(children:[InkWell(onTap:changePhoto,child:FutureBuilder<Uint8List>(future:widget.api.bytes('flutter/profile_photo.php',{}),builder:(c,s)=>CircleAvatar(radius:32,backgroundImage:s.hasData?MemoryImage(s.data!):null,child:s.hasData?null:const Icon(Icons.add_a_photo)))),const SizedBox(height:10),Text('${u['nama_lengkap']}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:20)),Text('${label(u['role'])} • Kelurahan Cikoko'),const SizedBox(height:6),Badge(u['status']),const Divider(),info('Nomor pegawai',u['nomor_pegawai']),info('Email',u['email']),info('Telepon',u['no_hp']),info('Alamat',u['alamat']),info('Saldo cuti','${u['saldo_cuti']} hari')])),OutlinedButton.icon(onPressed:()async{await openPage(context,ProfileForm(api:widget.api,user:u));if(mounted)setState(()=>version++);},icon:const Icon(Icons.edit),label:const Text('Edit profil')),heading('Dokumen & akun'),Panel(child:Column(children:[ListTile(leading:const Icon(Icons.print),title:const Text('Cetak biodata'),trailing:const Icon(Icons.chevron_right),onTap:()=>exportTable(context,'Biodata ${u['nama_lengkap']}',[for(final k in ['nama_lengkap','nomor_pegawai','role','email','no_hp','alamat']){'kolom':k,'nilai':u[k]}],['kolom','nilai'],['Data','Keterangan'])),ListTile(leading:const Icon(Icons.lock_outline),title:const Text('Ubah kata sandi'),trailing:const Icon(Icons.chevron_right),onTap:()=>openPage(context,PasswordForm(api:widget.api,onChanged:widget.onLogout))),ListTile(leading:const Icon(Icons.help_outline),title:const Text('Bantuan'),onTap:()=>showDialog<void>(context:context,builder:(c)=>AlertDialog(title:const Text('Bantuan Cikoko'),content:const Text('Hubungi pengelola kelurahan untuk perubahan NIP, status akun, saldo cuti, atau akses laporan. Untuk memuat ulang data, tarik daftar ke bawah.'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Tutup'))])))])),const Notice('Identitas kepegawaian dan saldo cuti dikelola admin.'),OutlinedButton(onPressed:widget.onLogout,child:const Text('Keluar'))]);});
}
class ProfileForm extends StatefulWidget{
 final Api api;final Json user;const ProfileForm({super.key,required this.api,required this.user});
 @override State<ProfileForm> createState()=>_ProfileFormState();
}
class _ProfileFormState extends State<ProfileForm>{
 final form=GlobalKey<FormState>();late Map<String,TextEditingController> fields;bool busy=false;String? error;
 @override void initState(){super.initState();fields={for(final k in ['no_hp','email','alamat','kontak_lain','akun_spse'])k:TextEditingController(text:'${widget.user[k]??''}')};}
 @override void dispose(){for(final c in fields.values){c.dispose();}super.dispose();}
 Future<void> save()async{if(!form.currentState!.validate())return;setState(()=>busy=true);try{await widget.api.call('profile',data:fields.map((k,v)=>MapEntry(k,v.text)));if(mounted)Navigator.pop(context);}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Edit Profil')),body:Form(key:form,child:ListView(padding:const EdgeInsets.all(16),children:[if(error!=null)Notice(error!,error:true),field(fields['no_hp']!,'Telepon',keyboard:TextInputType.phone),field(fields['email']!,'Email',keyboard:TextInputType.emailAddress),field(fields['alamat']!,'Alamat',lines:3),field(fields['kontak_lain']!,'Kontak lain',keyboard:TextInputType.phone),field(fields['akun_spse']!,'Akun SPSE'),const Notice('Untuk PPPK, perubahan email juga memengaruhi identitas login. Pastikan email benar dan belum dipakai pegawai lain.'),FilledButton(onPressed:busy?null:save,child:Text(busy?'Menyimpan…':'Simpan profil'))])));
}
class PasswordForm extends StatefulWidget{
 final Api api;final Future<void> Function() onChanged;const PasswordForm({super.key,required this.api,required this.onChanged});
 @override State<PasswordForm> createState()=>_PasswordFormState();
}
class _PasswordFormState extends State<PasswordForm>{
 final old=TextEditingController(),newPass=TextEditingController(),confirm=TextEditingController();bool busy=false;String? error;
 @override void dispose(){old.dispose();newPass.dispose();confirm.dispose();super.dispose();}
 Future<void> save()async{if(newPass.text!=confirm.text||newPass.text.length<12){setState(()=>error='Kata sandi minimal 12 karakter dan konfirmasi harus sama.');return;}setState(()=>busy=true);try{await widget.api.call('password',data:{'current_password':old.text,'new_password':newPass.text});if(mounted)Navigator.pop(context);await widget.onChanged();}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Ubah Kata Sandi')),body:ListView(padding:const EdgeInsets.all(16),children:[if(error!=null)Notice(error!,error:true),field(old,'Kata sandi saat ini',secret:true),field(newPass,'Kata sandi baru',secret:true),field(confirm,'Ulangi kata sandi baru',secret:true),const Notice('Semua token aplikasi dan login otomatis dicabut setelah kata sandi diganti.'),FilledButton(onPressed:busy?null:save,child:const Text('Simpan dan masuk ulang'))]));
}
class SettingsPage extends StatefulWidget{
 final Api api;final Future<void> Function() onLogout;const SettingsPage({super.key,required this.api,required this.onLogout});
 @override State<SettingsPage> createState()=>_SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage>{
 final fields=<String,TextEditingController>{};bool loaded=false,busy=false;String? error;
 @override void initState(){super.initState();load();}
 @override void dispose(){for(final c in fields.values){c.dispose();}super.dispose();}
 Future<void> load()async{try{final r=await widget.api.call('settings');if(!mounted)return;final s=r['settings'] as Map;for(final k in s.keys){fields['$k']=TextEditingController(text:'${s[k]}');}setState(()=>loaded=true);}catch(e){if(mounted)setState(()=>error=e.toString());}}
 Future<void> save()async{setState(()=>busy=true);try{await widget.api.call('settings_save',data:fields.map((k,v)=>MapEntry(k,v.text)));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Pengaturan tersimpan di website.')));}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext context){if(!loaded&&error==null)return const Center(child:CircularProgressIndicator());return ListView(padding:const EdgeInsets.all(16),children:[if(error!=null)Notice(error!,error:true),if(!loaded)FilledButton(onPressed:load,child:const Text('Coba lagi'))else...[
 heading('Pejabat & surat'),for(final role in ['lurah','atasan'])Panel(child:ExpansionTile(tilePadding:EdgeInsets.zero,title:Text(role=='lurah'?'Lurah':'Atasan langsung'),leading:const Icon(Icons.badge_outlined),children:[field(fields['nama_$role']!,'Nama lengkap'),field(fields['nip_$role']!,'NIP'),field(fields['jabatan_$role']!,'Jabatan')])),Panel(child:ExpansionTile(tilePadding:EdgeInsets.zero,title:const Text('Identitas & format surat'),children:[field(fields['alamat']!,'Alamat kelurahan',lines:2),field(fields['telepon']!,'Telepon'),field(fields['letter_title_pjlp']!,'Judul surat PJLP'),field(fields['letter_title_pppk']!,'Judul surat PPPK'),field(fields['letter_to']!,'Tujuan surat',lines:3)])),FilledButton(onPressed:busy?null:save,child:Text(busy?'Menyimpan…':'Simpan pengaturan')),heading('Akses akun'),ListTile(leading:const Icon(Icons.lock_outline),title:const Text('Ubah kata sandi admin'),onTap:()=>openPage(context,PasswordForm(api:widget.api,onChanged:widget.onLogout))),const Notice('Hak akses mengikuti role di website: admin, PJLP, dan PPPK. Pengaturan QR/TTD dan akses PPPK lintas kecamatan belum tersedia pada API paket ini.'),OutlinedButton(onPressed:widget.onLogout,child:const Text('Keluar'))]]);}
}
