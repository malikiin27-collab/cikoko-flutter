import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef Json = Map<String, dynamic>;
Json object(dynamic value) => value is Map ? Map<String,dynamic>.from(value) : <String,dynamic>{};
int number(dynamic value) => num.tryParse('$value')?.toInt() ?? 0;
List<Json> records(dynamic value) => value is List ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList() : [];
class ApiError implements Exception {
  final String message;
  final int? status;
  ApiError(this.message, [this.status]);
  @override String toString() => message;
}
class Api {
  static const server = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://cikoko.datawebs.my.id');
  static const _storage = FlutterSecureStorage();
  final Dio dio;
  String? token;
  void Function()? onUnauthorized;
  Api() : dio = Dio(BaseOptions(baseUrl: '${server.replaceAll(RegExp(r'/+$'), '')}/api/', connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(seconds: 60), sendTimeout: const Duration(seconds: 60), followRedirects: false)) {
    if (Uri.parse(server).scheme != 'https') { throw ArgumentError('API_BASE_URL wajib HTTPS.'); }
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
      o.headers['Accept'] = 'application/json';
      h.next(o);
    }, onError: (e,h) {
      if (e.response?.statusCode == 401) onUnauthorized?.call();
      h.next(e);
    }));
  }
  Future<void> restore() async { token = await _storage.read(key: 'cikoko_token'); }
  Future<void> forget() async { token = null; await _storage.delete(key: 'cikoko_token'); }
  Future<Json> login(String username, String password) async {
    final r = await call('login', data: {'username':username, 'password':password});
    token = r['token'] as String;
    await _storage.write(key:'cikoko_token', value:token);
    return Map<String,dynamic>.from(r['user'] as Map);
  }
  Future<Json> call(String action, {Json? data, Json? query}) => request('flutter/index.php', data:data, query:{'action':action, ...?query});
  Future<Json> request(String path, {dynamic data, Json? query}) async {
    try {
      final r = await dio.request<dynamic>(path, data:data, queryParameters:query, options:Options(method:data == null ? 'GET' : 'POST'));
      if (r.data is! Map) throw ApiError('Respons server bukan JSON. Pastikan patch API terpasang pada website yang benar.');
      final body = Map<String,dynamic>.from(r.data as Map);
      if (body['ok'] != true) throw ApiError('${body['message'] ?? 'Permintaan gagal.'}');
      return body;
    } on DioException catch(e) {
      final b=e.response?.data;
      throw ApiError(b is Map ? '${b['message'] ?? 'Permintaan ditolak.'}' : 'Tidak dapat menghubungi server. Periksa koneksi dan pemasangan API.', e.response?.statusCode);
    }
  }
  Future<Uint8List> bytes(String path, Json query) async {
    try {
      final r=await dio.get<List<int>>(path, queryParameters:query, options:Options(responseType:ResponseType.bytes));
      return Uint8List.fromList(r.data!);
    } on DioException catch(e) { throw ApiError('Berkas tidak tersedia atau akses ditolak.',e.response?.statusCode); }
  }
}
