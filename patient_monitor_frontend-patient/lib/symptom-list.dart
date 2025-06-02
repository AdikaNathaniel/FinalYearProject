import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SymptomListPage extends StatefulWidget {
  const SymptomListPage({Key? key}) : super(key: key);

  @override
  _SymptomListPageState createState() => _SymptomListPageState();
}

class _SymptomListPageState extends State<SymptomListPage> {
  List<dynamic> symptoms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSymptoms();
  }

  Future<void> fetchSymptoms() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3100/api/v1/symptoms'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          symptoms = data['result'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("Failed to load symptoms: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching symptoms: $e");
    }
  }

  Widget symptomTile(Map<String, dynamic> symptom) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  symptom['username'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            Row(children: [
              const Icon(Icons.headphones, color: Colors.red),
              const SizedBox(width: 8),
              Text("Headache: ${symptom['feelingHeadache']}"),
            ]),
            Row(children: [
              const Icon(Icons.sick, color: Colors.green),
              const SizedBox(width: 8),
              Text("Vomiting/Nausea: ${symptom['vomitingAndNausea']}"),
            ]),
            Row(children: [
              const Icon(Icons.pan_tool_alt, color: Colors.orange),
              const SizedBox(width: 8),
              Text("Pain at Top of Tummy: ${symptom['painAtTopOfTommy']}"),
            ]),
            Row(children: [
              const Icon(Icons.calendar_today, color: Colors.blue),
              const SizedBox(width: 8),
              Text("Created: ${DateTime.parse(symptom['createdAt']).toLocal().toString().split('.')[0]}"),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text('Patient Symptom Checker'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : symptoms.isEmpty
              ? const Center(child: Text("No symptoms found"))
              : RefreshIndicator(
                  onRefresh: fetchSymptoms,
                  child: ListView.builder(
                    itemCount: symptoms.length,
                    itemBuilder: (context, index) => symptomTile(symptoms[index]),
                  ),
                ),
    );
  }
}
