import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

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

  final String baseUrl = "https://finalyearproject-3-y6io.onrender.com/api/v1/csv";

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

  // --- Download CSV for Web ---
  Future<void> downloadCsv(String id) async {
    setState(() {
      downloadMessage = "Downloading...";
    });
    
    try {
      final response = await http.get(Uri.parse("$baseUrl/download/$id"));
      
      if (response.statusCode == 200) {
        // Create a blob from the response bytes
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes]);
        
        // Create a download URL
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        // Create a temporary anchor element and trigger download
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = '$id.csv';
        
        // Add to DOM, click, and remove
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        
        // Clean up the URL
        html.Url.revokeObjectUrl(url);
        
        setState(() {
          downloadMessage = "CSV file '$id.csv' downloaded successfully!";
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
      backgroundColor: Colors.cyan.shade50,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: Text("Pregnant Woman Vitals In CSV Format"),
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
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.description, color: Colors.cyan, size: 32),
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
                        backgroundColor: Colors.cyan,
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
                          color: Colors.cyan.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.cyan),
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
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.list, color: Colors.cyan, size: 32),
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
                        backgroundColor: Colors.cyan,
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
                                            icon: const Icon(Icons.copy, color: Colors.cyan),
                                            tooltip: "Copy ID",
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: id));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("ID '$id' copied to clipboard"),
                                                  duration: Duration(seconds: 2),
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
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.search, color: Colors.cyan, size: 32),
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
                          borderSide: BorderSide(color: Colors.cyan, width: 2),
                        ),
                        prefixIcon: Icon(Icons.fingerprint, color: Colors.cyan),
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
                        backgroundColor: Colors.green,
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