import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'api.dart';import 'ui.dart';
Future<void> exportTable(BuildContext context,String title,List<Json> rows,List<String> keys,List<String> labels,{DateTime? printDate})async{
 try{
 final pdf=pw.Document();pdf.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4.landscape,margin:const pw.EdgeInsets.all(24),header:(_)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Text('KELURAHAN CIKOKO',style:pw.TextStyle(fontSize:16,fontWeight:pw.FontWeight.bold)),pw.Text(title),pw.Text('Tanggal cetak: ${day(printDate??DateTime.now())}',style:const pw.TextStyle(fontSize:9)),pw.SizedBox(height:12)]),footer:(c)=>pw.Align(alignment:pw.Alignment.centerRight,child:pw.Text('Rekap aplikasi • ${c.pageNumber}/${c.pagesCount}',style:const pw.TextStyle(fontSize:8))),build:(_)=>[pw.TableHelper.fromTextArray(headers:labels,data:rows.map((r)=>keys.map((k)=>'${r[k]??'-'}').toList()).toList(),cellStyle:const pw.TextStyle(fontSize:8),headerStyle:pw.TextStyle(fontSize:9,fontWeight:pw.FontWeight.bold),headerDecoration:const pw.BoxDecoration(color:PdfColors.blue50),cellAlignment:pw.Alignment.centerLeft)]));
 final bytes=await pdf.save();if(context.mounted)await previewPdf(context,bytes,'${title.replaceAll(RegExp(r'[^a-zA-Z0-9 -]'),'')}.pdf');
 }catch(e){if(context.mounted)showFailure(context,e);}
}
Future<void> previewPdf(BuildContext context,Uint8List bytes,String name)async{
 if(bytes.length<5||String.fromCharCodes(bytes.take(5))!='%PDF-')throw ApiError('Server tidak mengembalikan PDF yang valid.');
 await openPage(context,Scaffold(appBar:AppBar(title:Text(name)),body:PdfPreview(build:(_)=>bytes,pdfFileName:name,canChangeOrientation:false,canChangePageFormat:false,allowSharing:true,allowPrinting:true)));
}
