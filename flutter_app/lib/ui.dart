import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api.dart';
const brand=Color(0xff1760d5);
String day(DateTime d)=>DateFormat('yyyy-MM-dd').format(d);
String month(DateTime d)=>DateFormat('yyyy-MM').format(d);
String label(dynamic v){const m={'pending':'Menunggu','approved':'Disetujui','rejected':'Ditolak','active':'Aktif','inactive':'Nonaktif','closed':'Selesai','draft':'Draf','submitted':'Dikirim','pjlp':'PJLP','pppk':'PPPK','admin':'Admin'};return m['$v']??'$v';}
Widget field(TextEditingController c,String title,{bool required=false,int lines=1,bool secret=false,TextInputType? keyboard})=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextFormField(controller:c,obscureText:secret,maxLines:lines,keyboardType:keyboard,decoration:InputDecoration(labelText:title),validator:(v)=>required&&(v??'').trim().isEmpty?'Wajib diisi':null));
class Notice extends StatelessWidget {
 final String text;final bool error;const Notice(this.text,{super.key,this.error=false});
 @override Widget build(BuildContext context)=>Container(width:double.infinity,margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:error?const Color(0xffffeaea):const Color(0xffeaf2ff),borderRadius:BorderRadius.circular(12)),child:Text(text,style:TextStyle(fontSize:12,color:error?Colors.red.shade900:const Color(0xff365576))));
}
class Panel extends StatelessWidget {
 final Widget child;const Panel({super.key,required this.child});
 @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:const Color(0xffe2e8f0)),borderRadius:BorderRadius.circular(14)),child:child);
}
class StatusBadge extends StatelessWidget {
 final dynamic value;const StatusBadge(this.value,{super.key});
 @override Widget build(BuildContext context){final good=['active','approved','closed'].contains(value);return Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:good?const Color(0xffd9f7eb):const Color(0xffffefcf),borderRadius:BorderRadius.circular(8)),child:Text(label(value),style:TextStyle(fontSize:11,color:good?Colors.teal.shade800:Colors.brown)));}
}
Widget heading(String s)=>Padding(padding:const EdgeInsets.only(top:12,bottom:10),child:Text(s,style:const TextStyle(fontSize:15,fontWeight:FontWeight.bold)));
Widget info(String k,dynamic v)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Text(k,style:const TextStyle(color:Colors.blueGrey))),Expanded(child:Text('$v',textAlign:TextAlign.right))]));
class Remote extends StatefulWidget {
 final Future<Json> Function() load;final Widget Function(Json) builder;
 const Remote({super.key,required this.load,required this.builder});
 @override State<Remote> createState()=>RemoteState();
}
class RemoteState extends State<Remote> {
 late Future<Json> future;
 @override void initState(){super.initState();future=widget.load();}
 Future<void> reload() async {setState(()=>future=widget.load());try{await future;}catch(_){} }
 @override Widget build(BuildContext context)=>FutureBuilder<Json>(future:future,builder:(context,s){
  if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
  if(s.hasError)return ListView(padding:const EdgeInsets.all(16),children:[Notice(s.error.toString(),error:true),FilledButton(onPressed:reload,child:const Text('Coba lagi'))]);
  return RefreshIndicator(onRefresh:reload,child:widget.builder(s.data!));
 });
}
class MonthPicker extends StatelessWidget {
 final DateTime value;final ValueChanged<DateTime> onChanged;const MonthPicker({super.key,required this.value,required this.onChanged});
 @override Widget build(BuildContext context)=>Panel(child:Row(children:[IconButton(tooltip:'Bulan sebelumnya',onPressed:()=>onChanged(DateTime(value.year,value.month-1)),icon:const Icon(Icons.chevron_left)),Expanded(child:Text(DateFormat('MMMM yyyy','id').format(value),textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w600))),IconButton(tooltip:'Bulan berikutnya',onPressed:()=>onChanged(DateTime(value.year,value.month+1)),icon:const Icon(Icons.chevron_right))]));
}
Future<void> showFailure(BuildContext context,Object e) async {if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
Future<void> openPage(BuildContext c,Widget page)=>Navigator.of(c).push(MaterialPageRoute<void>(builder:(_)=>page));
