import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko_native/api.dart';
class Adapter implements HttpClientAdapter {
 final int code;final dynamic payload;RequestOptions? request;
 Adapter(this.payload,{this.code=200});
 @override void close({bool force=false}){}
 @override Future<ResponseBody> fetch(RequestOptions options,Stream<Uint8List>? requestStream,Future<void>? cancelFuture)async{
  request=options;return ResponseBody.fromString(jsonEncode(payload),code,headers:{Headers.contentTypeHeader:['application/json']});
 }
}
void main(){
 test('GET carries bearer and action; token is never in query',()async{
  final api=Api()..token='secret-token';final a=Adapter({'ok':true,'items':[]});api.dio.httpClientAdapter=a;
  await api.call('leaves',query:{'month':'2026-10'});
  expect(a.request!.method,'GET');expect(a.request!.queryParameters,{'action':'leaves','month':'2026-10'});expect(a.request!.headers['Authorization'],'Bearer secret-token');
 });
 test('mutations use POST and JSON body',()async{
  final api=Api();final a=Adapter({'ok':true});api.dio.httpClientAdapter=a;
  await api.call('leave_review',data:{'id':2,'decision':'approve'});
  expect(a.request!.method,'POST');expect(a.request!.data,{'id':2,'decision':'approve'});
 });
 test('unauthorized response expires session',()async{
  final api=Api();var expired=false;api.onUnauthorized=()=>expired=true;api.dio.httpClientAdapter=Adapter({'ok':false,'message':'Sesi berakhir'},code:401);
  await expectLater(api.call('me'),throwsA(isA<ApiError>()));expect(expired,true);
 });
 test('false success from server is rejected',()async{
  final api=Api();api.dio.httpClientAdapter=Adapter({'ok':false,'message':'Saldo tidak mencukupi'});
  await expectLater(api.call('leave_create',data:{}),throwsA(predicate((e)=>e.toString()=='Saldo tidak mencukupi')));
 });
 test('PHP empty associative result can be an empty array',(){expect(object([]),isEmpty);expect(object({'a':1}),{'a':1});});
 test('numeric SQL strings normalize safely',(){expect(number('12'),12);expect(number(null),0);});
}
