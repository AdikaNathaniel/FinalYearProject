import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class CsvPage extends StatefulWidget {
  @override
  State<CsvPage> createState() => _CsvPageState();
}

class _CsvPageState extends State<CsvPage> {
  String? latestId;
  bool isLoadingLatest = false;
  List<String> allIds = [];
  bool isLoadingAllIds = false;
  final TextEditingController idController = TextEditingController();
  String? downloadMessage;

  final String baseUrl = "https://patient-monitor-backend-patient.fly.dev/api/v1/csv";

  // --- GET latest ID ---
  Future<void> fetchLatestId() async {
    setState(() {
      isLoadingLatest = true;
      latestId = null;
      downloadMessage = null; // Clear previous download message
    });
    
    try {
      final response = await http.get(Uri.parse("$baseUrl/latest-id"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          latestId = data['result']['id'];
        });
      } else {
        setState(() {
          latestId = "Error fetching latest ID (${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        latestId = "Error fetching latest ID: $e";
      });
    } finally {
      setState(() {
        isLoadingLatest = false;
      });
    }
  }

  // --- Enhanced Download CSV (Works on Mobile & Web) ---
  Future<void> downloadCsv(String id) async {
    setState(() {
      downloadMessage = "Downloading CSV...";
    });
    
    try {
      final response = await http.get(Uri.parse("$baseUrl/download/$id"));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final csvContent = utf8.decode(bytes);
        
        // For mobile: Save as file and open
        if (!kIsWeb) {
          await _saveAndOpenCsvFile(id, csvContent);
        } else {
          // For web: Show preview dialog
          _showEnhancedCsvPreviewDialog(id, csvContent, bytes.length);
        }
        
        setState(() {
          downloadMessage = "CSV downloaded successfully!";
        });
        
        // Clear message after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              downloadMessage = null;
            });
          }
        });
        
      } else {
        setState(() {
          downloadMessage = "Failed to download CSV. Status code: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        downloadMessage = "Error downloading CSV: $e";
      });
    }
  }

  // --- Save and Open CSV File (Mobile Only) ---
  Future<void> _saveAndOpenCsvFile(String id, String csvContent) async {
    try {
      // Try to get Downloads directory first (works on newer Android versions)
      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$id.csv';
      final file = File(filePath);
      
      // Write CSV content to file
      await file.writeAsString(csvContent);
      
      // Show success message with file path
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CSV saved successfully!'),
              SizedBox(height: 4),
              Text(
                'Location: ${directory.path}',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
      
      // Try to open the file with appropriate app
      try {
        await OpenFile.open(filePath);
      } catch (e) {
        print('Could not open file automatically: $e');
        // File is still saved, user can access it manually
      }
      
      // Also show preview dialog
      _showEnhancedCsvPreviewDialog(id, csvContent, csvContent.length);
      
    } catch (e) {
      // Fallback: If saving to Downloads fails, try application directory
      try {
        final fallbackDir = await getApplicationDocumentsDirectory();
        final fallbackPath = '${fallbackDir.path}/$id.csv';
        final fallbackFile = File(fallbackPath);
        await fallbackFile.writeAsString(csvContent);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('CSV saved to app storage!'),
                SizedBox(height: 4),
                Text(
                  'Use a file manager to access: Android/data/<your.app>/files/',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 6),
          ),
        );
        
        _showEnhancedCsvPreviewDialog(id, csvContent, csvContent.length);
        
      } catch (fallbackError) {
        // If everything fails, just show the preview
        _showEnhancedCsvPreviewDialog(id, csvContent, csvContent.length);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save file. Showing preview instead.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Enhanced CSV preview dialog with multiple export options
  void _showEnhancedCsvPreviewDialog(String id, String content, int fileSize) {
    final double sizeInKB = fileSize / 1024;
    final double sizeInMB = sizeInKB / 1024;
    final String fileSizeText = sizeInMB > 1 ? 
        '${sizeInMB.toStringAsFixed(2)} MB' : '${sizeInKB.toStringAsFixed(2)} KB';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.table_chart, color: Colors.blue),
            SizedBox(width: 8),
            Text('CSV File: $id'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File Size: $fileSizeText',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Preview (first 500 characters):',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    content.length > 500 ? '${content.substring(0, 500)}...' : content,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Export Options:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Copy full content button
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Full CSV content copied to clipboard'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
              Navigator.pop(context);
            },
            icon: Icon(Icons.copy, size: 18),
            label: Text('Copy All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          
          // Save file button (mobile) / Download button (web)
          if (!kIsWeb)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _saveAndOpenCsvFile(id, content);
              },
              icon: Icon(Icons.save, size: 18),
              label: Text('Save File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          
          // View full content button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close preview dialog
              _showFullCsvContentDialog(id, content); // Open full content dialog
            },
            icon: Icon(Icons.fullscreen, size: 18),
            label: Text('View Full'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // Full CSV content dialog for large files
  void _showFullCsvContentDialog(String id, String content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Full CSV Content: $id',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      content,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10),
                    ),
                  ),
                ),
              ),
              
              // Footer actions
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${content.length} characters',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Full CSV content copied to clipboard'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.copy),
                      label: Text('Copy All Content'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- GET all IDs ---
  Future<void> fetchAllIds() async {
    setState(() {
      isLoadingAllIds = true;
      allIds = [];
    });
    
    try {
      final response = await http.get(Uri.parse("$baseUrl/all-ids"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          allIds = List<String>.from(data['result']);
        });
      } else {
        setState(() {
          allIds = ["Error fetching IDs (${response.statusCode})"];
        });
      }
    } catch (e) {
      setState(() {
        allIds = ["Error fetching IDs: $e"];
      });
    } finally {
      setState(() {
        isLoadingAllIds = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Default white background
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Vitals In CSV"),
        centerTitle: true, 
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Card 1: Get Latest CSV ---
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey, width: 1.0), // Grey casing
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.description, color: Colors.blue, size: 32),
                        SizedBox(width: 10),
                        Text(
                          "Get Latest CSV Readings",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: isLoadingLatest ? null : fetchLatestId,
                      child: isLoadingLatest
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text("Fetch Latest ID"),
                    ),
                    if (latestId != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Latest ID: $latestId",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: latestId != null && !latestId!.contains("Error")
                            ? () => downloadCsv(latestId!)
                            : null,
                        icon: const Icon(Icons.download),
                        label: const Text("Download CSV"),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Card 2: All CSV IDs ---
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey, width: 1.0), // Grey casing
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.list, color: Colors.blue, size: 32),
                        SizedBox(width: 10),
                        Text(
                          "All CSV IDs",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: isLoadingAllIds ? null : fetchAllIds,
                      child: isLoadingAllIds
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text("Fetch All IDs"),
                    ),
                    const SizedBox(height: 12),
                    if (allIds.isNotEmpty)
                      Container(
                        constraints: BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: allIds.length,
                          itemBuilder: (context, index) {
                            final id = allIds[index];
                            final isError = id.contains("Error");
                            
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 2),
                              color: isError ? Colors.red.shade50 : Colors.grey.shade50,
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  id,
                                  style: TextStyle(
                                    color: isError ? Colors.red : Colors.black87,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                trailing: isError
                                    ? Icon(Icons.error, color: Colors.red)
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.copy, color: Colors.blue),
                                            tooltip: "Copy ID",
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: id));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("ID '$id' copied to clipboard"),
                                                  duration: Duration(seconds: 2),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.download, color: Colors.green),
                                            tooltip: "Download CSV",
                                            onPressed: () => downloadCsv(id),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Card 3: Download by ID ---
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey, width: 1.0), // Grey casing
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.search, color: Colors.blue, size: 32),
                        SizedBox(width: 10),
                        Text(
                          "Download CSV by ID",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: idController,
                      decoration: InputDecoration(
                        labelText: "Enter CSV ID",
                        hintText: "e.g., csv-12345",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                        prefixIcon: Icon(Icons.fingerprint, color: Colors.blue),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          downloadCsv(value.trim());
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        if (idController.text.trim().isNotEmpty) {
                          downloadCsv(idController.text.trim());
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: const Text("Download"),
                    ),
                  ],
                ),
              ),
            ),

            // --- Download Status Message ---
            if (downloadMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: downloadMessage!.contains("Error") || downloadMessage!.contains("Failed")
                      ? Colors.red.shade100
                      : downloadMessage!.contains("Downloading")
                          ? Colors.blue.shade100
                          : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: downloadMessage!.contains("Error") || downloadMessage!.contains("Failed")
                        ? Colors.red
                        : downloadMessage!.contains("Downloading")
                            ? Colors.blue
                            : Colors.green,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      downloadMessage!.contains("Error") || downloadMessage!.contains("Failed")
                          ? Icons.error
                          : downloadMessage!.contains("Downloading")
                              ? Icons.downloading
                              : Icons.check_circle,
                      color: downloadMessage!.contains("Error") || downloadMessage!.contains("Failed")
                          ? Colors.red
                          : downloadMessage!.contains("Downloading")
                              ? Colors.blue
                              : Colors.green,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        downloadMessage!,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: downloadMessage!.contains("Error") || downloadMessage!.contains("Failed")
                              ? Colors.red.shade800
                              : downloadMessage!.contains("Downloading")
                                  ? Colors.blue.shade800
                                  : Colors.green.shade800,
                        ),
                      ),
                    ),
                    if (downloadMessage!.contains("Downloading"))
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}