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
  runApp(const DiagnosticApp());
}

class DiagnosticApp extends StatelessWidget {
  const DiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Diagnostic Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DiagnosticToolPage(),
    );
  }
}

class DiagnosticToolPage extends StatefulWidget {
  const DiagnosticToolPage({super.key});

  @override
  State<DiagnosticToolPage> createState() => _DiagnosticToolPageState();
}

class _DiagnosticToolPageState extends State<DiagnosticToolPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _predictionController = TextEditingController();
  
  bool _isLoading = false;
  String _explanationText = '';
  String _timestamp = '';
  Uint8List? _pdfBytes;

  @override
  void dispose() {
    _patientNameController.dispose();
    _predictionController.dispose();
    super.dispose();
  }

  Future<void> _fetchExplanationAndGeneratePdf() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _explanationText = '';
      _timestamp = '';
      _pdfBytes = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3100/api/v1/health-analytics/explain-diagnostic'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patientName': _patientNameController.text,
          'prediction': _predictionController.text,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          setState(() {
            _explanationText = responseData['result'] as String;
            _timestamp = responseData['timestamps'] as String;
          });

          _pdfBytes = await _generatePdfBytes();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to generate explanation');
        }
      } else {
        throw Exception('Failed to fetch explanation: ${response.statusCode}');
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
    final formattedDate = _timestamp.isNotEmpty 
        ? dateFormat.format(DateTime.parse(_timestamp))
        : dateFormat.format(DateTime.now());

    // Load the image from assets
    final image = pw.MemoryImage(
      (await rootBundle.load('assets/pregnant.png')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      _predictionController.text,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo700,
                      ),
                    ),
                  ),
                  pw.Container(
                    width: 80,
                    height: 80,
                    child: pw.Image(image),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue200),
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
                        pw.Text('Name: ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(_patientNameController.text),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              ..._buildFormattedPdfContent(),
              pw.Spacer(),
              pw.Divider(),
              pw.Text(
                'Generated on $formattedDate',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  List<pw.Widget> _buildFormattedPdfContent() {
    final List<pw.Widget> widgets = [];
    final lines = _explanationText.split('\n');
    bool inBulletList = false;
    bool inNumberedList = false;
    int listIndex = 1;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Handle section headers (###)
      if (line.startsWith('###')) {
        widgets.add(
          pw.Text(
            line.replaceAll('###', '').trim(),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          ),
        );
        widgets.add(pw.SizedBox(height: 12));
        inBulletList = false;
        inNumberedList = false;
      }
      // Handle numbered lists
      else if (RegExp(r'^\d+\.').hasMatch(line)) {
        if (!inNumberedList) {
          inNumberedList = true;
          listIndex = 1;
        }
        
        // Extract the number from the line
        final match = RegExp(r'^(\d+)\.').firstMatch(line);
        final number = match != null ? int.parse(match.group(1)!) : listIndex;
        
        // Extract the content after the number
        final content = line.replaceFirst(RegExp(r'^\d+\.'), '').trim();
        
        // Process the content to handle bold text
        final contentWidgets = _processBoldText(content);
        
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20, bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 20,
                  child: pw.Text(
                    '$number.',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: contentWidgets,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        listIndex = number + 1;
        inBulletList = false;
      }
      // Handle bullet points
      else if (line.startsWith('-') || line.startsWith('•') || line.startsWith('*')) {
        if (!inBulletList) {
          inBulletList = true;
        }
        final content = line.substring(1).trim();
        
        // Process the content to handle bold text
        final contentWidgets = _processBoldText(content);
        
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20, bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: pw.TextStyle(fontSize: 12)),
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: contentWidgets,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        inNumberedList = false;
      }
      // Handle regular text (possibly with bold formatting)
      else {
        if (inBulletList || inNumberedList) {
          widgets.add(pw.SizedBox(height: 8));
          inBulletList = false;
          inNumberedList = false;
        }
        
        // Process the line to handle bold text
        final textWidgets = _processBoldText(line);
        
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.RichText(
              text: pw.TextSpan(
                children: textWidgets,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  List<pw.TextSpan> _processBoldText(String text) {
    final List<pw.TextSpan> textSpans = [];
    
    // Check if text contains any bold markers
    if (text.contains('**')) {
      final regex = RegExp(r'\*\*(.*?)\*\*|([^*]+)');
      final matches = regex.allMatches(text);
      
      for (var match in matches) {
        // Bold text
        if (match.group(1) != null) {
          textSpans.add(
            pw.TextSpan(
              text: match.group(1),
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        } 
        // Regular text
        else if (match.group(2) != null) {
          textSpans.add(
            pw.TextSpan(
              text: match.group(2),
              style: const pw.TextStyle(fontSize: 12),
            ),
          );
        }
      }
    } else {
      // If no bold markers, return the whole text as regular
      textSpans.add(
        pw.TextSpan(
          text: text,
          style: const pw.TextStyle(fontSize: 12),
        ),
      );
    }
    
    return textSpans;
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;

    if (kIsWeb) {
      final blob = html.Blob([_pdfBytes!], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'diagnostic_report_${_patientNameController.text.replaceAll(' ', '_')}.pdf';
      
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/diagnostic_report.pdf');
      await file.writeAsBytes(_pdfBytes!);
      await OpenFile.open(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Report Generator'),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _predictionController,
                        decoration: const InputDecoration(
                          labelText: 'Diagnostic Prediction',
                          prefixIcon: Icon(Icons.medical_services),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchExplanationAndGeneratePdf,
                        icon: const Icon(Icons.medical_services),
                        label: const Text('Generate Report'),
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
                      Text('Generating report...'),
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
                    'Download PDF Report',
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