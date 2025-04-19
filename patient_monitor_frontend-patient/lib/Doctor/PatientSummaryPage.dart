import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const PatientSummaryApp());
}

class PatientSummaryApp extends StatelessWidget {
  const PatientSummaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient Summary Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PatientSummaryPage(),
    );
  }
}

class PatientSummaryPage extends StatefulWidget {
  const PatientSummaryPage({super.key});

  @override
  State<PatientSummaryPage> createState() => _PatientSummaryPageState();
}

class _PatientSummaryPageState extends State<PatientSummaryPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  
  bool _isLoading = false;
  String _summaryText = '';
  Uint8List? _pdfBytes;

  @override
  void dispose() {
    _patientNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummaryAndGeneratePdf() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _summaryText = '';
      _pdfBytes = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/health-analytics/summary?patientName=${Uri.encodeComponent(_patientNameController.text)}'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          setState(() {
            _summaryText = responseData['result'] as String;
          });

          _pdfBytes = await _generatePdfBytes();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to generate summary');
        }
      } else {
        throw Exception('Failed to fetch summary: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Uint8List> _generatePdfBytes() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMMM d, yyyy - h:mm a');
    final formattedDate = dateFormat.format(DateTime.now());

    // Load the pregnant.png image from assets
    final pregnantImage = pw.MemoryImage(
      (await rootBundle.load('pregnant.png')).buffer.asUint8List(),
    );

    // Create the circular grey person icon
    final image = pw.MemoryImage(
  (await rootBundle.load('person.png')).buffer.asUint8List(),
);

final personIcon = pw.Container(
  width: 60,
  height: 60,
  decoration: pw.BoxDecoration(
    color: PdfColors.grey300,
    shape: pw.BoxShape.circle,
  ),
  child: pw.Center(
    child: pw.Image(image, width: 30, height: 30),
  ),
);


    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PATIENT SUMMARY',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Container(
                      width: 60,
                      height: 60,
                      child: pw.Image(pregnantImage),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Center(child: personIcon),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    _patientNameController.text,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated on $formattedDate | Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Patient Information',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Text('Name: ', 
                        style: const pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        )),
                      pw.Text(_patientNameController.text,
                        style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Text('Report Date: ', 
                        style: const pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        )),
                      pw.Text(formattedDate,
                        style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary Overview',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      _summaryText.isNotEmpty 
                          ? _summaryText.split('\n')[0]
                          : 'No summary available',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Detailed Summary',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  ..._buildFormattedPdfContent(),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  List<pw.Widget> _buildFormattedPdfContent() {
    final List<pw.Widget> widgets = [];
    final lines = _summaryText.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('-')) {
        final content = line.substring(1).trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: const pw.TextStyle(fontSize: 12)),
                pw.Expanded(
                  child: pw.Text(
                    content,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              line,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;

    if (kIsWeb) {
      final blob = html.Blob([_pdfBytes!], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'patient_summary_${_patientNameController.text.replaceAll(' ', '_')}.pdf';
      
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/patient_summary.pdf');
      await file.writeAsBytes(_pdfBytes!);
      await OpenFile.open(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Summary Generator'),
        actions: [
          if (_pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadPdf,
              tooltip: 'Download PDF',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _patientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Patient Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchSummaryAndGeneratePdf,
                        icon: const Icon(Icons.medical_services),
                        label: const Text('Generate Summary'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating summary...'),
                    ],
                  ),
                ),
              )
            else if (_pdfBytes != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _downloadPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text(
                    'Download PDF Summary',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}