import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';import 'ui.dart';
class MonthlyForm extends StatefulWidget{
 final Api api;final DateTime period;const MonthlyForm({super.key,required this.api,required this.period});
 @override State<MonthlyForm> createState()=>_MonthlyFormState();
}
class _MonthlyFormState extends State<MonthlyForm>{
 String type='lapangan';Json? record;Map<String,dynamic> indicators={},oldItems={};final progress=<String,String>{},photos=<String,XFile>{};final job=TextEditingController();DateTime signed=DateTime.now();bool loading=true,busy=false;String? error;int revision=0;bool exists=false;
 @override void initState(){super.initState();load();}
 @override void dispose(){job.dispose();super.dispose();}
 Future<void> load()async{setState(()=>loading=true);try{final d=await widget.api.call('monthly',query:{'month':month(widget.period),'type':type});final row=d['row'] as Map?;final data=object(d['data']);exists=row!=null;revision=number(row?['revision']);type='${d['type']}';indicators=Map<String,dynamic>.from(d['indicators'] as Map);oldItems=object(data['items']);job.text='${data['member_jabatan']??''}';signed=DateTime.tryParse('${data['signed_date']}')??DateTime.now();progress.clear();photos.clear();record=d;error=null;}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}
 Future<void> pick(String key)async{try{final p=await ImagePicker().pickImage(source:ImageSource.gallery,maxWidth:1600,imageQuality:85);if(p!=null)setState(()=>photos[key]=p);}catch(e){if(mounted)showFailure(context,e);}}
 Future<void> save(String action)async{
 if(job.text.trim().isEmpty){setState(()=>error='Isi jabatan terlebih dahulu.');return;}setState((){busy=true;error=null;});
 try{final fields=<String,dynamic>{'month_key':month(widget.period),'report_type':type,'revision':revision,'member_jabatan':job.text,'signed_date':day(signed),'action':action};
 for(final code in indicators.keys){for(final slot in [1,2]){final key='${slot}_$code';if(progress.containsKey(key))fields['progress_$slot[$code]']=progress[key];if(photos.containsKey(key))fields['photo_$key']=await MultipartFile.fromFile(photos[key]!.path,filename:'evidence.jpg');}}
 await widget.api.request('flutter/monthly_save.php',data:FormData.fromMap(fields));if(mounted)Navigator.pop(context);
 }catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('Kinerja ${month(widget.period)}')),body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[if(error!=null)Notice(error!,error:true),if(record==null)FilledButton(onPressed:load,child:const Text('Coba lagi'))else...[
 DropdownButtonFormField<String>(initialValue:type,items:const [DropdownMenuItem(value:'lapangan',child:Text('Lapangan')),DropdownMenuItem(value:'admin',child:Text('Administratif'))],onChanged:exists||busy?null:(v){type=v!;load();},decoration:const InputDecoration(labelText:'Jenis laporan')),const SizedBox(height:12),field(job,'Jabatan PPPK',required:true),ListTile(title:const Text('Tanggal laporan'),subtitle:Text(day(signed)),trailing:const Icon(Icons.calendar_month),onTap:busy?null:()async{final d=await showDatePicker(context:context,initialDate:signed,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d!=null)setState(()=>signed=d);}),
 const Notice('Foto dan progres tersimpan dipertahankan jika tidak diubah. Kirim ke admin memerlukan minimal satu bukti. Jika data berubah di website, muat ulang sebelum menyimpan.'),
 for(final code in indicators.keys)Panel(child:ExpansionTile(tilePadding:EdgeInsets.zero,title:Text('${indicators[code]}',style:const TextStyle(fontSize:13,fontWeight:FontWeight.w600)),children:[for(final slot in [1,2])evidence(code,slot)])),
 Wrap(spacing:8,children:[OutlinedButton(onPressed:busy?null:()=>save('draft'),child:const Text('Simpan draf')),FilledButton(onPressed:busy?null:()=>save('submit'),child:Text(busy?'Menyimpan…':'Kirim ke admin'))])]]));
 Widget evidence(String code,int slot){final key='${slot}_$code';final old=oldItems[code] as Map?;final caption='${old?['photo_${slot}_caption']??''}';return Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('Periode $slot • ${slot==1?'1–15':'16–akhir bulan'}',style:const TextStyle(fontWeight:FontWeight.bold)),if(caption.isNotEmpty)Text(caption,style:const TextStyle(fontSize:12,color:Colors.blueGrey)),const SizedBox(height:8),DropdownButtonFormField<String>(initialValue:progress[key]??'keep',items:const [DropdownMenuItem(value:'keep',child:Text('Pertahankan progres lama')),DropdownMenuItem(value:'done',child:Text('Terlaksana')),DropdownMenuItem(value:'not_done',child:Text('Belum terlaksana'))],onChanged:busy?null:(v)=>setState((){if(v=='keep'){progress.remove(key);}else{progress[key]=v!;}}),decoration:const InputDecoration(labelText:'Progres')),if(photos[key]!=null)Padding(padding:const EdgeInsets.only(top:8),child:Image.file(File(photos[key]!.path),height:130)),OutlinedButton.icon(onPressed:busy?null:()=>pick(key),icon:const Icon(Icons.add_photo_alternate),label:Text(photos[key]!=null?'Ganti foto pilihan':('${old?['photo_${slot}_path']??''}'.isNotEmpty?'Ganti foto tersimpan':'Tambah foto')))]));}
}
