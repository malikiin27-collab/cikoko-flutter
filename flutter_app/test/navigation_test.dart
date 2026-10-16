import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko_native/api.dart';
import 'package:cikoko_native/shell.dart';
class FakeApi extends Api {
 final String role;FakeApi(this.role);
 @override Future<Json> call(String action,{Json? data,Json? query})async=>{
  'ok':true,'user':{'id':1,'role':role,'nama_lengkap':'Pegawai Uji','saldo_cuti':8},
  'stats':{'pegawai':48,'hadir':2,'cuti':1,'laporan':4},'active':null,'items':[],
 };
}
void main(){
 for(final role in ['admin','pjlp','pppk']){
  testWidgets('$role has five native destinations and compact dashboard',(tester)async{
   tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
   addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
   await tester.pumpWidget(MaterialApp(locale:const Locale('id'),localizationsDelegates:GlobalMaterialLocalizations.delegates,supportedLocales:const [Locale('id')],home:AppShell(api:FakeApi(role),user:{'role':role,'nama_lengkap':'Pegawai Uji'},onLogout:()async{})));
   await tester.pumpAndSettle();expect(find.byType(NavigationDestination),findsNWidgets(5));
   final bar=tester.widget<NavigationBar>(find.byType(NavigationBar));
   final labels=bar.destinations.cast<NavigationDestination>().map((e)=>e.label).toList();
   expect(labels,role=='admin'?['Beranda','Pegawai','Cuti','Laporan','Lainnya']:['Beranda','Jam kerja',role=='pppk'?'Kinerja':'Laporan','Cuti','Profil']);
   expect(tester.takeException(),isNull);
  });
 }
}
