import 'package:flutter/material.dart';
import 'api.dart';
import 'ui.dart';
import 'people.dart';
import 'leave.dart';
import 'work.dart';
import 'reports.dart';
import 'profile.dart';
class AppShell extends StatefulWidget {
 final Api api;final Json user;final Future<void> Function() onLogout;
 const AppShell({super.key,required this.api,required this.user,required this.onLogout});
 @override State<AppShell> createState()=>_AppShellState();
}
class _AppShellState extends State<AppShell>{
 int selected=0;bool get admin=>widget.user['role']=='admin';
 @override Widget build(BuildContext context){
 final labels=admin?['Beranda','Pegawai','Cuti','Laporan','Lainnya']:['Beranda','Jam kerja',widget.user['role']=='pppk'?'Kinerja':'Laporan','Cuti','Profil'];
 final icons=admin?[Icons.home_rounded,Icons.groups_rounded,Icons.calendar_month,Icons.description_outlined,Icons.more_horiz]:[Icons.home_rounded,Icons.schedule,Icons.description_outlined,Icons.calendar_month,Icons.person_outline];
 final pages=admin?<Widget>[Dashboard(api:widget.api,user:widget.user,onTab:(i)=>setState(()=>selected=i)),PeoplePage(api:widget.api),LeavePage(api:widget.api,admin:true),ReportsPage(api:widget.api,user:widget.user),SettingsPage(api:widget.api,onLogout:widget.onLogout)]:<Widget>[Dashboard(api:widget.api,user:widget.user,onTab:(i)=>setState(()=>selected=i)),WorkPage(api:widget.api),ReportsPage(api:widget.api,user:widget.user),LeavePage(api:widget.api,admin:false),ProfilePage(api:widget.api,onLogout:widget.onLogout)];
 return Scaffold(appBar:AppBar(title:Text(selected==0?'${admin?'Admin':label(widget.user['role'])} Cikoko':labels[selected]),actions:[IconButton(tooltip:'Keluar',onPressed:()async{final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Keluar dari aplikasi?'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Keluar'))]));if(yes==true)await widget.onLogout();},icon:const Icon(Icons.logout,size:20))]),body:SafeArea(child:KeyedSubtree(key:ValueKey(selected),child:pages[selected])),bottomNavigationBar:NavigationBar(selectedIndex:selected,onDestinationSelected:(i)=>setState(()=>selected=i),destinations:[for(var i=0;i<labels.length;i++)NavigationDestination(icon:Icon(icons[i]),label:labels[i])]));
 }
}
class Dashboard extends StatelessWidget {
 final Api api;final Json user;final ValueChanged<int> onTab;const Dashboard({super.key,required this.api,required this.user,required this.onTab});
 @override Widget build(BuildContext context)=>Remote(load:()=>api.call('dashboard'),builder:(d){final a=user['role']=='admin';final stats=d['stats'] as Map;final u=d['user'] as Map;final active=d['active'] as Map?;
 final metrics=a?[['${stats['pegawai']}','Pegawai',Icons.groups,Colors.blue],['${stats['hadir']}','Hadir hari ini',Icons.check_circle,Colors.teal],['${stats['cuti']}','Cuti menunggu',Icons.schedule,Colors.orange],['${stats['laporan']}','Foto bulan ini',Icons.description,Colors.deepPurple]]:[['${u['saldo_cuti']}','Sisa cuti',Icons.calendar_month,Colors.deepPurple],['${stats['laporan']}','Foto bulan ini',Icons.description,Colors.blue],['${stats['cuti']}','Cuti menunggu',Icons.schedule,Colors.orange],['${stats['hadir']}','Sesi hari ini',Icons.check_circle,Colors.teal]];
 return ListView(padding:const EdgeInsets.all(16),physics:const AlwaysScrollableScrollPhysics(),children:[Text('Halo, ${u['nama_lengkap']}',style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const Text('Kelurahan Cikoko',style:TextStyle(color:Colors.blueGrey)),const SizedBox(height:14),if(!a)Notice(active!=null?'Sedang bekerja • Mulai ${active['checkin_at']}':'Belum ada sesi kerja aktif'),GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),childAspectRatio:1.9,mainAxisSpacing:8,crossAxisSpacing:8,children:metrics.map((m)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:(m[3] as Color).withValues(alpha:0.09),borderRadius:BorderRadius.circular(12)),child:Row(children:[Icon(m[2] as IconData,color:m[3] as Color),const SizedBox(width:12),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(m[0] as String,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),Text(m[1] as String,style:const TextStyle(fontSize:11))]))]))).toList()),heading(a?'Menu admin':'Akses cepat'),
 Wrap(spacing:8,runSpacing:8,children:[if(a)...[action('Pegawai',Icons.groups,()=>onTab(1)),action('Jam kerja',Icons.schedule,()=>openPage(context,Scaffold(appBar:AppBar(title:const Text('Jam Kerja Pegawai')),body:WorkPage(api:api,admin:true)))),action('Cuti',Icons.calendar_month,()=>onTab(2)),action('Laporan',Icons.description,()=>onTab(3)),action('Pengaturan',Icons.settings,()=>onTab(4))]else...[action('Jam kerja',Icons.schedule,()=>onTab(1)),action('Laporan',Icons.description,()=>onTab(2)),action('Ajukan cuti',Icons.calendar_month,()=>onTab(3)),action('Profil',Icons.person,()=>onTab(4))]]),
 heading('Informasi'),const Notice('Data berasal dari website Cikoko. Tarik layar ke bawah untuk memperbarui ringkasan.'),if(!a)const Notice('Saldo cuti dicadangkan saat pengajuan dikirim. Jika ditolak, saldo dikembalikan oleh server.'),
 ]);
 });
 Widget action(String title,IconData icon,VoidCallback tap)=>SizedBox(width:145,child:OutlinedButton.icon(onPressed:tap,icon:Icon(icon,size:20),label:Text(title)));
}
