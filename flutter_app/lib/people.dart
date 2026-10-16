import 'package:flutter/material.dart';
import 'create_employee.dart';
import 'api.dart';import 'ui.dart';import 'export.dart';
class PeoplePage extends StatefulWidget{
 final Api api;const PeoplePage({super.key,required this.api});
 @override State<PeoplePage> createState()=>_PeoplePageState();
}
class _PeoplePageState extends State<PeoplePage>{
 String role='',search='';int version=0;final query=TextEditingController();
 @override void dispose(){query.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Column(children:[Padding(padding:const EdgeInsets.fromLTRB(16,16,16,0),child:Column(children:[TextField(controller:query,decoration:InputDecoration(hintText:'Cari nama / NIP',prefixIcon:const Icon(Icons.search),suffixIcon:IconButton(onPressed:()=>setState(()=>search=query.text.trim()),icon:const Icon(Icons.arrow_forward))),onSubmitted:(v)=>setState(()=>search=v)),const SizedBox(height:8),Wrap(spacing:8,children:[for(final r in ['','pjlp','pppk'])ChoiceChip(label:Text(r.isEmpty?'Semua':label(r)),selected:role==r,onSelected:(_)=>setState(()=>role=r))])])),Expanded(child:Remote(key:ValueKey('$role|$search|$version'),load:()=>widget.api.call('employees',query:{'role':role,'q':search}),builder:(d){final rows=records(d['items']);return ListView(padding:const EdgeInsets.all(16),physics:const AlwaysScrollableScrollPhysics(),children:[FilledButton.icon(onPressed:()async{await openPage(context,CreateEmployeePage(api:widget.api));if(mounted)setState(()=>version++);},icon:const Icon(Icons.person_add),label:const Text('Tambah pegawai')),OutlinedButton.icon(onPressed:()=>exportTable(context,'Data Pegawai',rows,['nama_lengkap','role','nomor_pegawai','status','saldo_cuti'],['Nama','Jenis','NIP / nomor','Status','Saldo']),icon:const Icon(Icons.print),label:const Text('Cetak data PDF')),if(rows.isEmpty)const Notice('Tidak ada pegawai sesuai pencarian.'),for(final r in rows)Panel(child:ExpansionTile(tilePadding:EdgeInsets.zero,leading:CircleAvatar(child:Text('${r['nama_lengkap']}'.substring(0,1))),title:Text('${r['nama_lengkap']}',style:const TextStyle(fontSize:14,fontWeight:FontWeight.bold)),subtitle:Text('${label(r['role'])} • ${r['nomor_pegawai']}'),children:[info('Status',label(r['status'])),info('Saldo cuti','${r['saldo_cuti']} hari'),OutlinedButton.icon(onPressed:()async{await openPage(context,EmployeeForm(api:widget.api,data:r));if(mounted)setState(()=>version++);},icon:const Icon(Icons.edit),label:const Text('Edit pegawai'))]))]);}))]);
}
class EmployeeForm extends StatefulWidget{
 final Api api;final Json data;const EmployeeForm({super.key,required this.api,required this.data});
 @override State<EmployeeForm> createState()=>_EmployeeFormState();
}
class _EmployeeFormState extends State<EmployeeForm>{
 final form=GlobalKey<FormState>();late final TextEditingController name,numberField,balance;late String status;bool busy=false;String? error;
 @override void initState(){super.initState();name=TextEditingController(text:'${widget.data['nama_lengkap']}');numberField=TextEditingController(text:'${widget.data['nomor_pegawai']}');balance=TextEditingController(text:'${widget.data['saldo_cuti']}');status='${widget.data['status']}';}
 @override void dispose(){name.dispose();numberField.dispose();balance.dispose();super.dispose();}
 Future<void> save()async{if(!form.currentState!.validate())return;setState(()=>busy=true);try{await widget.api.call('employee_save',data:{'id':widget.data['id'],'nama_lengkap':name.text,'nomor_pegawai':numberField.text,'saldo_cuti':balance.text,'status':status});if(mounted)Navigator.pop(context);}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Edit Pegawai')),body:Form(key:form,child:ListView(padding:const EdgeInsets.all(16),children:[if(error!=null)Notice(error!,error:true),field(name,'Nama lengkap',required:true),field(numberField,'NIP / nomor pegawai'),field(balance,'Saldo cuti tersedia',required:true,keyboard:TextInputType.number),DropdownButtonFormField<String>(initialValue:status,items:['active','inactive'].map((s)=>DropdownMenuItem(value:s,child:Text(label(s)))).toList(),onChanged:(s)=>status=s!,decoration:const InputDecoration(labelText:'Status')),const SizedBox(height:12),const Notice('Perubahan saldo mengganti saldo tersedia, bukan menambah jatah tahunan.'),FilledButton(onPressed:busy?null:save,child:Text(busy?'Menyimpan…':'Simpan perubahan'))])));
}
