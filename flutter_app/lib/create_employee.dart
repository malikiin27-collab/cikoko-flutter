import 'package:flutter/material.dart';import 'api.dart';import 'ui.dart';
class CreateEmployeePage extends StatefulWidget{
 final Api api;const CreateEmployeePage({super.key,required this.api});
 @override State<CreateEmployeePage> createState()=>_CreateEmployeePageState();
}
class _CreateEmployeePageState extends State<CreateEmployeePage>{
 final form=GlobalKey<FormState>();final fields={for(final k in ['nama_lengkap','nomor_pegawai','username','email','password','saldo_cuti'])k:TextEditingController(text:k=='saldo_cuti'?'0':'')};String role='pjlp';bool busy=false;String? error;
 @override void dispose(){for(final c in fields.values){c.dispose();}super.dispose();}
 Future<void> save()async{if(!form.currentState!.validate())return;setState(()=>busy=true);try{await widget.api.request('flutter/employee_create.php',data:{'role':role,...fields.map((k,v)=>MapEntry(k,v.text))});if(mounted)Navigator.pop(context);}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Tambah Pegawai')),body:Form(key:form,child:ListView(padding:const EdgeInsets.all(16),children:[if(error!=null)Notice(error!,error:true),DropdownButtonFormField<String>(initialValue:role,items:const [DropdownMenuItem(value:'pjlp',child:Text('PJLP')),DropdownMenuItem(value:'pppk',child:Text('PPPK'))],onChanged:busy?null:(v)=>setState(()=>role=v!),decoration:const InputDecoration(labelText:'Jenis pegawai')),const SizedBox(height:12),field(fields['nama_lengkap']!,'Nama lengkap',required:true),field(fields['nomor_pegawai']!,'NIP / nomor pegawai'),field(fields['username']!,'Username',required:true),field(fields['email']!,'Email',required:role=='pppk',keyboard:TextInputType.emailAddress),field(fields['password']!,'Kata sandi awal (minimal 12 karakter)',required:true,secret:true),field(fields['saldo_cuti']!,'Saldo cuti awal',required:true,keyboard:TextInputType.number),const Notice('Akun baru langsung tersimpan di website. PJLP masuk dengan username; PPPK menggunakan email.'),FilledButton(onPressed:busy?null:save,child:Text(busy?'Membuat akun…':'Buat akun'))])));
}
