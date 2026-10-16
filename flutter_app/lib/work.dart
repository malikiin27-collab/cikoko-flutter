import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'api.dart';import 'ui.dart';import 'export.dart';
Future<Position> currentPosition()async{
 if(!await Geolocator.isLocationServiceEnabled())throw ApiError('Aktifkan lokasi/GPS perangkat.');
 var p=await Geolocator.checkPermission();if(p==LocationPermission.denied)p=await Geolocator.requestPermission();
 if(p==LocationPermission.denied||p==LocationPermission.deniedForever)throw ApiError('Izin lokasi diperlukan. Aktifkan melalui pengaturan aplikasi.');
 final fix=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.best,timeLimit:Duration(seconds:30)));
 if(fix.accuracy<=0||fix.accuracy>30)throw ApiError('Akurasi GPS ±${fix.accuracy.round()} m. Tunggu di tempat terbuka hingga maksimal 30 m.');return fix;
}
Json fixFields(Position p)=>{'lat':p.latitude,'lng':p.longitude,'acc':p.accuracy,'fix_epoch':p.timestamp.millisecondsSinceEpoch~/1000};
class WorkPage extends StatefulWidget{
 final Api api;final bool admin;const WorkPage({super.key,required this.api,this.admin=false});
 @override State<WorkPage> createState()=>_WorkPageState();
}
class _WorkPageState extends State<WorkPage>{
 DateTime period=DateTime.now();int version=0;bool busy=false;String? error;
 Future<void> capture(bool active)async{
  setState((){busy=true;error=null;});
  try{
   final photo=await ImagePicker().pickImage(source:ImageSource.camera,maxWidth:1600,imageQuality:85);if(photo==null)return;
   final p=await currentPosition();
   await widget.api.request('mobile/${active?'stop':'start'}.php',data:FormData.fromMap({...fixFields(p),'device_info':'Flutter Cikoko','photo':await MultipartFile.fromFile(photo.path,filename:'capture.jpg')}));
   if(mounted)setState(()=>version++);
  }catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Column(children:[if(busy)const LinearProgressIndicator(),Expanded(child:Remote(key:ValueKey('${month(period)}-$version'),load:()=>widget.api.call('attendance',query:{'month':month(period)}),builder:(d){final rows=records(d['items']);final active=d['active'] as Map?;final total=rows.fold<int>(0,(v,r)=>v+number(r['duration_minutes']));return ListView(padding:const EdgeInsets.all(16),physics:const AlwaysScrollableScrollPhysics(),children:[MonthPicker(value:period,onChanged:(v)=>setState(()=>period=v)),if(error!=null)Notice(error!,error:true),if(!widget.admin)...[Panel(child:Column(children:[info('Status',active!=null?'Sedang bekerja':'Belum mulai'),if(active!=null)info('Mulai',active['checkin_at']),FilledButton.icon(onPressed:busy?null:()=>capture(active!=null),icon:Icon(active!=null?Icons.stop_circle_outlined:Icons.camera_alt),label:Text(active!=null?'Foto & selesai kerja':'Foto & mulai kerja'))])),const Notice('Foto kamera dan GPS akurat wajib tersedia. Versi ini mencatat lokasi saat check-in/check-out; belum melacak lokasi terus-menerus di latar belakang.')],Panel(child:info('Total waktu tercatat','${total~/60} jam ${total%60} menit')),OutlinedButton.icon(onPressed:()=>exportTable(context,'Jam Kerja ${month(period)}',rows,['nama_lengkap','checkin_at','checkout_at','checkin_lat','checkin_lng','duration_minutes'],['Nama','Mulai','Selesai','Latitude','Longitude','Menit']),icon:const Icon(Icons.print),label:const Text('Cetak rekap PDF')),heading('Riwayat jam kerja'),if(rows.isEmpty)const Notice('Belum ada sesi kerja pada bulan ini.'),for(final r in rows)Panel(child:ExpansionTile(tilePadding:EdgeInsets.zero,leading:const Icon(Icons.schedule,color:brand),title:Text('${widget.admin?r['nama_lengkap']:r['checkin_at']}',style:const TextStyle(fontSize:14)),subtitle:Text('${r['duration_minutes']} menit • ${label(r['status'])}'),children:[info('Mulai',r['checkin_at']),info('Selesai',r['checkout_at']??'Berjalan'),info('Koordinat mulai','${r['checkin_lat']}, ${r['checkin_lng']}'),if(r['checkout_lat']!=null)info('Koordinat selesai','${r['checkout_lat']}, ${r['checkout_lng']}')]))]);}))]);
}
