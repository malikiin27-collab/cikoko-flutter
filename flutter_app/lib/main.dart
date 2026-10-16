import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'api.dart';
import 'shell.dart';
import 'ui.dart';
void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const CikokoApp()); }
class CikokoApp extends StatefulWidget {
  const CikokoApp({super.key});
  @override State<CikokoApp> createState()=>_CikokoAppState();
}
class _CikokoAppState extends State<CikokoApp> {
  final api=Api(); Json? user; bool restoring=true; String? startupError;
  @override void initState() { super.initState(); api.onUnauthorized=expire; restore(); }
  void expire() { api.forget(); if(mounted) setState(()=>user=null); }
  Future<void> restore() async {
    try { await api.restore(); if(api.token!=null) user=Map<String,dynamic>.from((await api.call('me'))['user'] as Map); }
    catch(e) { startupError=e.toString(); }
    if(mounted) setState(()=>restoring=false);
  }
  Future<void> logout() async {
    try { await api.call('logout',data:{}); } catch(_) { /* local logout always clears credentials */ }
    await api.forget(); if(mounted) setState(()=>user=null);
  }
  @override Widget build(BuildContext context)=>MaterialApp(
    debugShowCheckedModeBanner:false, title:'Kelurahan Cikoko', locale:const Locale('id'),
    supportedLocales:const [Locale('id'),Locale('en')],localizationsDelegates:GlobalMaterialLocalizations.delegates,
    theme:ThemeData(useMaterial3:true, colorScheme:ColorScheme.fromSeed(seedColor:brand),scaffoldBackgroundColor:const Color(0xfff5f7fb),
      appBarTheme:const AppBarTheme(backgroundColor:brand,foregroundColor:Colors.white,centerTitle:false,toolbarHeight:56),
      inputDecorationTheme:InputDecorationTheme(isDense:true,filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))),
      visualDensity:VisualDensity.compact,
      navigationBarTheme:const NavigationBarThemeData(height:64,backgroundColor:Colors.white),
    ),
    home:restoring?const Scaffold(body:Center(child:CircularProgressIndicator())):user==null?
      LoginPage(api:api,initialError:startupError,onLogin:(u)=>setState((){user=u;startupError=null;})):
      AppShell(api:api,user:user!,onLogout:logout),
  );
}
class LoginPage extends StatefulWidget {
 final Api api; final void Function(Json) onLogin; final String? initialError;
 const LoginPage({super.key,required this.api,required this.onLogin,this.initialError});
 @override State<LoginPage> createState()=>_LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
 final form=GlobalKey<FormState>();final username=TextEditingController(),password=TextEditingController();bool busy=false,hidden=true;String? error;
 @override void initState(){super.initState();error=widget.initialError;}
 @override void dispose(){username.dispose();password.dispose();super.dispose();}
 Future<void> submit() async {
  if(!form.currentState!.validate())return;setState((){busy=true;error=null;});
  try{final u=await widget.api.login(username.text.trim(),password.text);if(mounted)widget.onLogin(u);}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 const Icon(Icons.account_balance_rounded,size:52,color:brand),const SizedBox(height:16),const Text('Kelurahan Cikoko',textAlign:TextAlign.center,style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const Text('Satu akun untuk pekerjaan sehari-hari',textAlign:TextAlign.center),const SizedBox(height:28),
 field(username,'Username / email',required:true),const SizedBox(height:12),TextFormField(controller:password,obscureText:hidden,validator:(v)=>(v??'').isEmpty?'Isi kata sandi':null,decoration:InputDecoration(labelText:'Kata sandi',suffixIcon:IconButton(onPressed:()=>setState(()=>hidden=!hidden),icon:Icon(hidden?Icons.visibility:Icons.visibility_off))),onFieldSubmitted:(_){if(!busy)submit();}),
 const SizedBox(height:12),if(error!=null)Notice(error!,error:true),FilledButton(onPressed:busy?null:submit,child:Text(busy?'Memeriksa akun…':'Masuk')),
 const SizedBox(height:12),const Text('Admin dan PJLP: username website.\nPPPK: email yang terdaftar pada website.\nMenu ditentukan otomatis oleh akun.',textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:Colors.blueGrey)),
 ])))))));
}
