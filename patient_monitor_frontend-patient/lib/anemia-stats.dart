import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class AnaemiaRiskStatisticsPage extends StatefulWidget {
  const AnaemiaRiskStatisticsPage({super.key});

  @override
  State<AnaemiaRiskStatisticsPage> createState() =>
      _AnaemiaRiskStatisticsPageState();
}

class _AnaemiaRiskStatisticsPageState extends State<AnaemiaRiskStatisticsPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _fullData;
  Map<String, dynamic>? _statistics;
  List<dynamic>? _interpretations;
  Map<String, dynamic>? _summary;
  bool _loading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchStatistics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatistics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = Uri.parse("https://finalyearproject-3-y6io.onrender.com/api/v1/anaemia-risk/statistics");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fullData = data["result"];
          _statistics = data["result"]["statistics"];
          _interpretations = data["result"]["interpretations"];
          _summary = data["result"]["summary"];
          _error = null;
        });
        _animationController.forward();
      } else {
        setState(() {
          _error = "Failed to load statistics (Status: ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error fetching statistics: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildHeaderCard() {
    if (_summary == null) return const SizedBox();

    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.analytics, size: 48, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                "Risk Assessment Overview",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHeaderStat(
                    "Total Assessments",
                    _summary!["totalAssessments"].toString(),
                    Icons.people,
                  ),
                  Container(width: 1, height: 40, color: Colors.white30),
                  _buildHeaderStat(
                    "Average Risk",
                    "${_summary!["averageRisk"].toStringAsFixed(1)}%",
                    Icons.trending_up,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    if (_summary == null) return const SizedBox();

    final riskDist = _summary!["riskDistribution"];
    final total = _summary!["totalAssessments"];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.donut_large, color: Colors.blue.shade600, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    "Risk Distribution",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 280,
                child: total > 0
                    ? PieChart(
                        PieChartData(
                          sections: _buildPieChartSections(riskDist, total),
                          sectionsSpace: 4,
                          centerSpaceRadius: 70,
                          startDegreeOffset: -90,
                        ),
                      )
                    : const Center(
                        child: Text(
                          "No assessment data available",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              if (total > 0) _buildRiskLegend(riskDist),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, dynamic> riskDist, int total) {
    final sections = <PieChartSectionData>[];
    
    final riskCategories = [
      {'key': 'high', 'color': const Color(0xFFE53E3E), 'title': 'High'},
      {'key': 'moderate', 'color': const Color(0xFFDD6B20), 'title': 'Moderate'},
      {'key': 'mild', 'color': const Color(0xFFD69E2E), 'title': 'Mild'},
      {'key': 'low', 'color': const Color(0xFF38A169), 'title': 'Low'},
    ];

    for (final category in riskCategories) {
      final value = riskDist[category['key']] ?? 0;
      if (value > 0) {
        final percentage = ((value / total) * 100).toStringAsFixed(1);
        sections.add(
          PieChartSectionData(
            value: value.toDouble(),
            color: category['color'] as Color,
            title: '$percentage%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return sections;
  }

  Widget _buildRiskLegend(Map<String, dynamic> riskDist) {
    final legendItems = [
      {'key': 'high', 'color': const Color(0xFFE53E3E), 'title': 'High Risk'},
      {'key': 'moderate', 'color': const Color(0xFFDD6B20), 'title': 'Moderate Risk'},
      {'key': 'mild', 'color': const Color(0xFFD69E2E), 'title': 'Mild Risk'},
      {'key': 'low', 'color': const Color(0xFF38A169), 'title': 'Low Risk'},
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 12,
      children: legendItems
          .where((item) => (riskDist[item['key']] ?? 0) > 0)
          .map((item) => _buildLegendItem(
                item['color'] as Color,
                '${item['title']} (${riskDist[item['key']]})',
              ))
          .toList(),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid() {
    if (_statistics == null) return const SizedBox();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildStatCard(
              "High Risk Cases",
              _statistics!["highRiskCount"].toString(),
              Icons.warning,
              const Color(0xFFE53E3E),
            ),
            _buildStatCard(
              "Moderate Risk",
              _statistics!["moderateRiskCount"].toString(),
              Icons.info,
              const Color(0xFFDD6B20),
            ),
            _buildStatCard(
              "Mild Risk",
              _statistics!["mildRiskCount"].toString(),
              Icons.lightbulb_outline,
              const Color(0xFFD69E2E),
            ),
            _buildStatCard(
              "Low Risk Cases",
              _statistics!["lowRiskCount"].toString(),
              Icons.check_circle,
              const Color(0xFF38A169),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAnalysisCard() {
    if (_summary == null) return const SizedBox();

    final riskSpread = _summary!["riskSpread"];
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.indigo.shade600, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    "Risk Analysis",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildAnalysisMetric(
                      "Min Risk",
                      "${riskSpread["range"]["min"].toStringAsFixed(1)}%",
                      Colors.green.shade400,
                    ),
                  ),
                  Expanded(
                    child: _buildAnalysisMetric(
                      "Max Risk",
                      "${riskSpread["range"]["max"].toStringAsFixed(1)}%",
                      Colors.red.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildAnalysisMetric(
                      "Std Deviation",
                      riskSpread["standardDeviation"].toStringAsFixed(2),
                      Colors.blue.shade400,
                    ),
                  ),
                  Expanded(
                    child: _buildAnalysisMetric(
                      "Variance",
                      riskSpread["variance"].toStringAsFixed(2),
                      Colors.purple.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisMetric(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    if (_summary == null) return const SizedBox();

    final timeline = _summary!["timeline"];
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.timeline, color: Colors.teal.shade600, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    "Assessment Timeline",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTimelineItem(
                      "First Assessment",
                      _formatDate(timeline["earliest"]),
                      Icons.play_arrow,
                      Colors.blue.shade400,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.green.shade400],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTimelineItem(
                      "Latest Assessment",
                      _formatDate(timeline["latest"]),
                      Icons.schedule,
                      Colors.green.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String date, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInsightsCard() {
    if (_interpretations == null || _interpretations!.isEmpty) {
      return const SizedBox();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights, color: Colors.amber.shade700, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    "Key Insights",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ..._interpretations!.asMap().entries.map((entry) {
                final index = entry.key;
                final interpretation = entry.value.toString();
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(
                        width: 4,
                        color: Colors.amber.shade600,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          interpretation,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Anaemia Risk Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchStatistics,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF667eea),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loading analytics...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Unable to Load Data',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _fetchStatistics,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667eea),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                )
              : _statistics == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.data_usage, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "No assessment data available",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeaderCard(),
                          _buildPieChart(),
                          _buildStatisticsGrid(),
                          _buildRiskAnalysisCard(),
                          _buildTimelineCard(),
                          _buildInsightsCard(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }
}