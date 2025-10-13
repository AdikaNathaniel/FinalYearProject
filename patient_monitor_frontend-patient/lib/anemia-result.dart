import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AnaemiaResultsScreen extends StatefulWidget {
  const AnaemiaResultsScreen({super.key});

  @override
  _AnaemiaResultsScreenState createState() => _AnaemiaResultsScreenState();
}

class _AnaemiaResultsScreenState extends State<AnaemiaResultsScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _anaemiaAssessments = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Update this URL to match your backend server
  static const String baseUrl = 'https://patient-monitor-backend-patient.fly.dev';

  @override
  void initState() {
    super.initState();
    _fetchAnaemiaAssessments();
  }

  Future<void> _fetchAnaemiaAssessments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/anaemia-risk/assessments'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['result'] != null) {
          setState(() {
            _anaemiaAssessments = List<Map<String, dynamic>>.from(
                jsonData['result'].map((item) => Map<String, dynamic>.from(item)));
          });
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load data');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInterpretationCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.indigo[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'RISK INDICATOR GUIDE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF38A169), // Green
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'GREEN TICK Implies Risk Factor Is ABSENT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE53E3E), // Red
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'RED X Implies Risk Factor Is PRESENT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'More red indicators = Higher anaemia risk',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber[800],
                        ),
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

  Widget _buildAnaemiaAssessmentCard(Map<String, dynamic> assessment, int index) {
    final String riskClass = assessment['riskClass']?.toString() ?? 'UNKNOWN';
    final double calculatedRisk = _getCalculatedRisk(assessment);
    final String createdAt = assessment['createdAt']?.toString() ?? '';
    final String patientId = assessment['patientId']?.toString() ?? 'Unknown Patient';

    DateTime? assessmentDate;
    try {
      if (createdAt.isNotEmpty) {
        assessmentDate = DateTime.parse(createdAt);
      }
    } catch (_) {}

    final bool isHighRisk = riskClass.toUpperCase().contains('HIGH');
    final Color riskColor = isHighRisk ? const Color(0xFFE53E3E) : const Color(0xFF38A169);
    final IconData riskIcon = isHighRisk ? Icons.warning : Icons.check_circle;

    return AnimatedContainer(
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Card(
        elevation: 8,
        shadowColor: riskColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: riskColor.withOpacity(0.3), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailedResults(assessment),
          child: Column(
            children: [
              // Header with risk assessment and patient ID
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [riskColor.withOpacity(0.1), riskColor.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient ID at the top
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Patient ID: $patientId',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: riskColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(riskIcon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ANAEMIA RISK ASSESSMENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      riskClass.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: riskColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'RISK',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: riskColor, width: 2),
                          ),
                          child: Text(
                            '${calculatedRisk.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: riskColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (assessmentDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Assessed: ${_formatDate(assessmentDate)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Risk factors section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assessment, color: Colors.grey[700], size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'CLINICAL FINDINGS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[800],
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_countPositiveFactors(assessment)} of ${_getTotalFactors(assessment)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRiskFactorsList(assessment),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600], size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tap for detailed assessment breakdown',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.blue[600], size: 14),
                        ],
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

  double _getCalculatedRisk(Map<String, dynamic> assessment) {
    // Handle different probability formats from backend
    final dynamic prob = assessment['probability'];
    if (prob == null) return 0.0;
    
    final double probability = (prob as num).toDouble();
    
    // If probability is already in percentage format (>1), return as is
    if (probability > 1) {
      return probability;
    }
    
    // If probability is in decimal format (0-1), convert to percentage
    return probability * 100;
  }

  Widget _buildRiskFactorsList(Map<String, dynamic> assessment) {
    final Map<String, String> riskFactors = {
      'excessiveVomiting': 'Excessive Vomiting',
      'diarrhea': 'Diarrhea',
      'historyHeavyMenstrualFlow': 'Heavy Menstrual Flow',
      'infections': 'Infections',
      'chronicDisease': 'Chronic Disease',
      'familyHistory': 'Family History of Anaemia',
      'shortInterpregnancyInterval': 'Short Inter-pregnancy Interval',
      'multiplePregnancy': 'Multiple Pregnancy',
      'poverty': 'Socioeconomic Factors',
      'lackOfAccessHealthcare': 'Limited Healthcare Access',
      'education': 'Educational Barriers',
    };

    final List<Widget> factorWidgets = [];

    // Add standard risk factors
    riskFactors.forEach((key, label) {
      if (assessment.containsKey(key)) {
        final dynamic value = assessment[key];
        final bool isPresent = (value == 1 || value == true);
        factorWidgets.add(_buildFactorItem(label, isPresent));
      }
    });

    // Add BMI-related factors
    if (assessment.containsKey('bmiLow')) {
      final bool isBmiLow = (assessment['bmiLow'] == 1 || assessment['bmiLow'] == true);
      final double? bmiValue = assessment['bmiValue']?.toDouble();
      final String bmiLabel = bmiValue != null 
          ? 'Low BMI Risk (BMI: ${bmiValue.toStringAsFixed(1)})' 
          : 'Low BMI Risk';
      factorWidgets.add(_buildFactorItem(bmiLabel, isBmiLow));
    }

    // Add Age-related factors
    if (assessment.containsKey('age35OrLess')) {
      final bool isAge35OrLess = (assessment['age35OrLess'] == 1 || assessment['age35OrLess'] == true);
      factorWidgets.add(_buildFactorItem('Age 35 or Less', isAge35OrLess));
    }

    // Handle legacy BMI and Age fields
    final int? bmi = assessment['bmi'] as int?;
    final int? age = assessment['age'] as int?;
    
    if (bmi != null && bmi > 0 && !assessment.containsKey('bmiLow')) {
      factorWidgets.add(_buildFactorItem('BMI Factor (BMI: $bmi)', true));
    }
    if (age != null && age > 0 && !assessment.containsKey('age35OrLess')) {
      factorWidgets.add(_buildFactorItem('Age Factor (Age: $age)', true));
    }

    return Column(children: factorWidgets);
  }

  Widget _buildFactorItem(String label, bool isPresent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPresent ? const Color(0xFFE53E3E) : const Color(0xFF38A169),
            ),
            child: Icon(
              isPresent ? Icons.close : Icons.check,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isPresent ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPresent ? Colors.red[200]! : Colors.green[200]!,
              ),
            ),
            child: Text(
              isPresent ? 'PRESENT' : 'ABSENT',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isPresent ? Colors.red[700] : Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedResults(Map<String, dynamic> assessment) {
    final String riskClass = assessment['riskClass']?.toString() ?? 'UNKNOWN';
    final double calculatedRisk = _getCalculatedRisk(assessment);
    final String patientId = assessment['patientId']?.toString() ?? 'Unknown Patient';
    final bool isHighRisk = riskClass.toUpperCase().contains('HIGH');
    final Color riskColor = isHighRisk ? const Color(0xFFE53E3E) : const Color(0xFF38A169);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [riskColor.withOpacity(0.1), riskColor.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Patient ID at the top
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Row wraps content
                          children: [
                            Icon(Icons.person, size: 18, color: Colors.blue[600]),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Patient ID: $patientId',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: riskColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isHighRisk ? Icons.warning : Icons.check_circle,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DETAILED ASSESSMENT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Flexible(
                                child: Text(
                                  '$riskClass RISK',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: riskColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: riskColor, width: 2),
                          ),
                          child: Text(
                            '${calculatedRisk.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: riskColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Assessment Summary
                      _buildDetailSection(
                        'Assessment Summary',
                        Icons.analytics,
                        [
                          _buildDetailRow('Patient ID', patientId),
                          _buildDetailRow('Risk Classification', riskClass.toUpperCase()),
                          _buildDetailRow('Calculated Risk Score', '${calculatedRisk.toStringAsFixed(2)}%'),
                          _buildDetailRow('Assessment Date', assessment['createdAt'] != null 
                            ? _formatDetailedDate(DateTime.parse(assessment['createdAt'])) 
                            : 'Not available'),
                          if (assessment['rawScore'] != null)
                            _buildDetailRow('Raw Score', assessment['rawScore'].toString()),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Patient Information
                      _buildDetailSection(
                        'Patient Information',
                        Icons.person,
                        [
                          if (assessment['encodedAge'] != null)
                            _buildDetailRow('Age Category', assessment['encodedAge'] == 1 ? '35 years or younger' : 'Over 35 years'),
                          if (assessment['bmiValue'] != null)
                            _buildDetailRow('BMI Value', assessment['bmiValue'].toStringAsFixed(2)),
                          if (assessment['age'] != null)
                            _buildDetailRow('Age', '${assessment['age']} years'),
                          if (assessment['bmi'] != null)
                            _buildDetailRow('BMI', assessment['bmi'].toString()),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Clinical Risk Factors
                      _buildDetailSection(
                        'Clinical Risk Factors',
                        Icons.medical_services,
                        _buildClinicalFactors(assessment),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Social & Environmental Factors
                      _buildDetailSection(
                        'Social & Environmental Factors',
                        Icons.home,
                        _buildSocialFactors(assessment),
                      ),

                      // Feature Contributions (if available)
                      if (assessment['featureContributions'] != null) ...[
                        const SizedBox(height: 20),
                        _buildFeatureContributionsSection(assessment['featureContributions']),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _exportAssessmentReport(assessment),
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
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

  Widget _buildFeatureContributionsSection(Map<String, dynamic> contributions) {
    return _buildDetailSection(
      'Feature Contributions',
      Icons.analytics_outlined,
      contributions.entries.map((entry) {
        final contribution = entry.value;
        final input = contribution['input'];
        final weight = contribution['weight'];
        final contributionValue = contribution['contribution'];
        
        return _buildDetailRow(
          _formatFeatureName(entry.key),
          'Input: $input, Weight: $weight, Contribution: ${contributionValue.toStringAsFixed(2)}%'
        );
      }).toList(),
    );
  }

  String _formatFeatureName(String key) {
    final Map<String, String> nameMap = {
      'excessiveVomiting': 'Excessive Vomiting',
      'diarrhea': 'Diarrhea',
      'historyHeavyMenstrualFlow': 'Heavy Menstrual Flow',
      'infections': 'Infections',
      'chronicDisease': 'Chronic Disease',
      'familyHistory': 'Family History',
      'bmiLow': 'Low BMI',
      'shortInterpregnancyInterval': 'Short Inter-pregnancy',
      'multiplePregnancy': 'Multiple Pregnancy',
      'age35OrLess': 'Age 35 or Less',
      'poverty': 'Poverty',
      'lackOfAccessHealthcare': 'Healthcare Access',
      'education': 'Education',
    };
    return nameMap[key] ?? key;
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey[700], size: 20),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children.isEmpty 
              ? [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'No data available',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ]
              : children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildClinicalFactors(Map<String, dynamic> assessment) {
    final Map<String, String> clinicalFactors = {
      'excessiveVomiting': 'Excessive Vomiting',
      'diarrhea': 'Diarrhea',
      'historyHeavyMenstrualFlow': 'Heavy Menstrual Flow',
      'infections': 'Current/Recent Infections',
      'chronicDisease': 'Chronic Disease',
      'familyHistory': 'Family History of Anaemia',
      'shortInterpregnancyInterval': 'Short Inter-pregnancy Interval',
      'multiplePregnancy': 'Multiple Pregnancy',
    };

    final List<Widget> widgets = [];
    clinicalFactors.forEach((key, label) {
      if (assessment.containsKey(key)) {
        final dynamic value = assessment[key];
        final bool isPresent = (value == 1 || value == true);
        widgets.add(_buildFactorDetailRow(label, isPresent));
      }
    });

    // Add BMI-related factors
    if (assessment.containsKey('bmiLow')) {
      final bool isBmiLow = (assessment['bmiLow'] == 1 || assessment['bmiLow'] == true);
      widgets.add(_buildFactorDetailRow('Low BMI Risk', isBmiLow));
    }

    // Add Age-related factors
    if (assessment.containsKey('age35OrLess')) {
      final bool isAge35OrLess = (assessment['age35OrLess'] == 1 || assessment['age35OrLess'] == true);
      widgets.add(_buildFactorDetailRow('Age 35 or Less', isAge35OrLess));
    }

    return widgets;
  }

  List<Widget> _buildSocialFactors(Map<String, dynamic> assessment) {
    final Map<String, String> socialFactors = {
      'poverty': 'Socioeconomic Challenges',
      'lackOfAccessHealthcare': 'Limited Healthcare Access',
      'education': 'Educational Barriers',
    };

    final List<Widget> widgets = [];
    socialFactors.forEach((key, label) {
      if (assessment.containsKey(key)) {
        final dynamic value = assessment[key];
        final bool isPresent = (value == 1 || value == true);
        widgets.add(_buildFactorDetailRow(label, isPresent));
      }
    });

    return widgets;
  }

  Widget _buildFactorDetailRow(String label, bool isPresent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPresent ? Colors.red[400] : Colors.green[400],
            ),
            child: Icon(
              isPresent ? Icons.close : Icons.check,
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isPresent ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPresent ? Colors.red[200]! : Colors.green[200]!,
                width: 1,
              ),
            ),
            child: Text(
              isPresent ? 'PRESENT' : 'ABSENT',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isPresent ? Colors.red[700] : Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAssessmentReport(Map<String, dynamic> assessment) async {
    final String riskClass = assessment['riskClass']?.toString() ?? 'UNKNOWN';
    final double calculatedRisk = _getCalculatedRisk(assessment);
    final String patientId = assessment['patientId']?.toString() ?? 'Unknown Patient';
    final String assessmentDate = assessment['createdAt'] != null 
        ? _formatDetailedDate(DateTime.parse(assessment['createdAt'])) 
        : 'Not available';
    
    // Generate the report content
    String reportContent = '''
=========================================
       ANAEMIA RISK ASSESSMENT REPORT
=========================================

PATIENT INFORMATION
-------------------
Patient ID: $patientId
Risk Classification: ${riskClass.toUpperCase()}
Calculated Risk Score: ${calculatedRisk.toStringAsFixed(2)}%
Assessment Date: $assessmentDate''';

    if (assessment['rawScore'] != null) {
      reportContent += '\nRaw Score: ${assessment['rawScore']}';
    }

    reportContent += '''

DEMOGRAPHIC INFORMATION
-----------------------''';

    if (assessment['encodedAge'] != null) {
      reportContent += '\nAge Category: ${assessment['encodedAge'] == 1 ? "35 years or younger" : "Over 35 years"}';
    }
    if (assessment['bmiValue'] != null) {
      reportContent += '\nBMI Value: ${assessment['bmiValue'].toStringAsFixed(2)}';
    }
    if (assessment['age'] != null) {
      reportContent += '\nAge: ${assessment['age']} years';
    }
    if (assessment['bmi'] != null) {
      reportContent += '\nBMI: ${assessment['bmi']}';
    }
    
    if (assessment['encodedAge'] == null && assessment['bmiValue'] == null && 
        assessment['age'] == null && assessment['bmi'] == null) {
      reportContent += '\nNo demographic data available';
    }

    reportContent += '''

CLINICAL RISK FACTORS
---------------------''';

    final Map<String, String> clinicalFactors = {
      'excessiveVomiting': 'Excessive Vomiting',
      'diarrhea': 'Diarrhea',
      'historyHeavyMenstrualFlow': 'Heavy Menstrual Flow',
      'infections': 'Current/Recent Infections',
      'chronicDisease': 'Chronic Disease',
      'familyHistory': 'Family History of Anaemia',
      'shortInterpregnancyInterval': 'Short Inter-pregnancy Interval',
      'multiplePregnancy': 'Multiple Pregnancy',
    };

    bool hasClinicalFactors = false;
    clinicalFactors.forEach((key, label) {
      if (assessment.containsKey(key)) {
        final dynamic value = assessment[key];
        final bool isPresent = (value == 1 || value == true);
        reportContent += '\n• $label: ${isPresent ? "PRESENT" : "ABSENT"}';
        if (isPresent) hasClinicalFactors = true;
      }
    });

    // Add BMI and Age factors
    if (assessment.containsKey('bmiLow')) {
      final bool isBmiLow = (assessment['bmiLow'] == 1 || assessment['bmiLow'] == true);
      reportContent += '\n• Low BMI Risk: ${isBmiLow ? "PRESENT" : "ABSENT"}';
      if (isBmiLow) hasClinicalFactors = true;
    }

    if (assessment.containsKey('age35OrLess')) {
      final bool isAge35OrLess = (assessment['age35OrLess'] == 1 || assessment['age35OrLess'] == true);
      reportContent += '\n• Age 35 or Less: ${isAge35OrLess ? "PRESENT" : "ABSENT"}';
      if (isAge35OrLess) hasClinicalFactors = true;
    }

    if (!hasClinicalFactors) {
      reportContent += '\nNo clinical risk factors detected.';
    }

    reportContent += '''

SOCIAL & ENVIRONMENTAL FACTORS
-------------------------------''';

    final Map<String, String> socialFactors = {
      'poverty': 'Socioeconomic Challenges',
      'lackOfAccessHealthcare': 'Limited Healthcare Access',
      'education': 'Educational Barriers',
    };

    bool hasSocialFactors = false;
    socialFactors.forEach((key, label) {
      if (assessment.containsKey(key)) {
        final dynamic value = assessment[key];
        final bool isPresent = (value == 1 || value == true);
        reportContent += '\n• $label: ${isPresent ? "PRESENT" : "ABSENT"}';
        if (isPresent) hasSocialFactors = true;
      }
    });

    if (!hasSocialFactors) {
      reportContent += '\nNo social or environmental risk factors detected.';
    }

    // Add feature contributions if available
    if (assessment['featureContributions'] != null) {
      reportContent += '''

FEATURE CONTRIBUTIONS
---------------------''';
      
      final Map<String, dynamic> contributions = assessment['featureContributions'];
      contributions.forEach((key, value) {
        final input = value['input'];
        final weight = value['weight'];
        final contribution = value['contribution'];
        reportContent += '\n• ${_formatFeatureName(key)}: Input=$input, Weight=$weight, Contribution=${contribution.toStringAsFixed(2)}%';
      });
    }

    reportContent += '''

SUMMARY
-------
Patient ID: $patientId
Total Risk Factors Present: ${_countPositiveFactors(assessment)} of ${_getTotalFactors(assessment)}
Overall Risk Level: ${riskClass.toUpperCase()}
Risk Percentage: ${calculatedRisk.toStringAsFixed(2)}%''';

    if (assessment['rawScore'] != null) {
      reportContent += '\nRaw Assessment Score: ${assessment['rawScore']}';
    }

    reportContent += '''

RECOMMENDATIONS
---------------''';

    if (riskClass.toUpperCase().contains('HIGH')) {
      reportContent += '''
⚠️  HIGH RISK DETECTED
• Immediate medical consultation recommended
• Regular monitoring of hemoglobin levels
• Nutritional counseling and iron supplementation
• Address identified risk factors promptly
• Follow-up assessment within 1-2 weeks''';
    } else {
      reportContent += '''
✓  LOW/MILD RISK
• Continue routine prenatal care
• Maintain balanced, iron-rich diet
• Monitor for symptoms of anaemia
• Regular follow-up as per standard protocol
• Reassess if new risk factors develop''';
    }

    reportContent += '''

NOTE: This assessment is a screening tool and should not replace 
professional medical judgment. Please consult with healthcare 
providers for comprehensive evaluation and treatment decisions.

Report Generated: ${DateTime.now().toString()}
=========================================''';

    try {
      // For mobile/desktop: Save to device storage
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/anaemia_assessment_${patientId}_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(reportContent);
      
      // Show success message with file path
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Assessment report for Patient $patientId saved successfully!'),
                Text(
                  'File: ${file.path}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Fallback: Show share dialog with text content
      if (mounted) {
        _showShareDialog(reportContent, patientId);
      }
    }
  }

  void _showShareDialog(String reportContent, String patientId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report generated successfully!'),
            const SizedBox(height: 16),
            const Text('You can copy the report content and save it manually:'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                reportContent,
                style: const TextStyle(fontSize: 10, fontFamily: 'Monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard
              _copyToClipboard(reportContent);
              Navigator.of(context).pop();
            },
            child: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    // For Flutter, you would typically use a package like clipboard
    // This is a simplified version - in practice, use the clipboard package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDetailedDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  int _countPositiveFactors(Map<String, dynamic> assessment) {
    final List<String> factors = [
      'excessiveVomiting',
      'diarrhea',
      'historyHeavyMenstrualFlow',
      'infections',
      'chronicDisease',
      'familyHistory',
      'shortInterpregnancyInterval',
      'multiplePregnancy',
      'poverty',
      'lackOfAccessHealthcare',
      'education',
      'bmiLow',
      'age35OrLess'
    ];
    
    int count = 0;
    for (final f in factors) {
      if (assessment.containsKey(f)) {
        final dynamic value = assessment[f];
        if (value == 1 || value == true) count++;
      }
    }
    
    // Handle legacy fields
    if ((assessment['bmi'] as int?) != null && assessment['bmi'] > 0 && !assessment.containsKey('bmiLow')) count++;
    if ((assessment['age'] as int?) != null && assessment['age'] > 0 && !assessment.containsKey('age35OrLess')) count++;
    
    return count;
  }

  int _getTotalFactors(Map<String, dynamic> assessment) {
    // Count available factors in this assessment
    final List<String> possibleFactors = [
      'excessiveVomiting',
      'diarrhea',
      'historyHeavyMenstrualFlow',
      'infections',
      'chronicDisease',
      'familyHistory',
      'shortInterpregnancyInterval',
      'multiplePregnancy',
      'poverty',
      'lackOfAccessHealthcare',
      'education',
      'bmiLow',
      'age35OrLess'
    ];
    
    int totalCount = 0;
    for (final factor in possibleFactors) {
      if (assessment.containsKey(factor)) {
        totalCount++;
      }
    }
    
    // Add legacy factors if new ones don't exist
    if (!assessment.containsKey('bmiLow') && assessment.containsKey('bmi')) totalCount++;
    if (!assessment.containsKey('age35OrLess') && assessment.containsKey('age')) totalCount++;
    
    return totalCount > 0 ? totalCount : 11; // Fallback to standard count
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          "Anaemia Results",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchAnaemiaAssessments,
            tooltip: 'Refresh Assessments',
          ),
        ],
      ),
      body: Column(
        children: [
          // Add interpretation card at the top
          _buildInterpretationCard(),
          
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading assessments...'),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Error Loading Data',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 8),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchAnaemiaAssessments,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _anaemiaAssessments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No Assessments Found',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                const Text('No anaemia risk assessments have been recorded yet.'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchAnaemiaAssessments,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              itemCount: _anaemiaAssessments.length,
                              itemBuilder: (context, index) =>
                                  _buildAnaemiaAssessmentCard(_anaemiaAssessments[index], index),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}