import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/sidebar.dart';
import '../services/api_service.dart';

class AuditResultsScreen extends StatefulWidget {
  final String? auditId;

  const AuditResultsScreen({super.key, this.auditId});

  @override
  State<AuditResultsScreen> createState() => _AuditResultsScreenState();
}

class _AuditResultsScreenState extends State<AuditResultsScreen> {
  // Design tokens
  static const Color _background = Color(0xFF0F0F0F);
  static const Color _surface = Color(0xFF161616);
  static const Color _borderColor = Color(0xFF262626);
  static const Color _primaryGreen = Color(0xFF4BE277);
  static const Color _primaryGreenCta = Color(0xFF22C55E);
  static const Color _warning = Color(0xFFFBBF24);
  static const Color _error = Color(0xFFFFB4AB);
  static const Color _primaryText = Color(0xFFE5E5E5);
  static const Color _secondaryText = Color(0xFF888888);
  static const Color _mutedLabel = Color(0xFF555555);
  static const Color _inputBg = Color(0xFF1C1C1C);
  static const Color _hoverBg = Color(0xFF1B1C1C);

  final List<bool> _mitigationChecked = [false, false, false];

  bool get _anyMitigationChecked => _mitigationChecked.any((v) => v);

  Map<String, dynamic>? _auditData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.auditId == null) {
      setState(() {
        _errorMessage = 'No Audit ID provided.';
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await ApiService.getAuditDetails(widget.auditId!);
      setState(() {
        _auditData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Row(
        children: [
          const Sidebar(
            currentRoute: '/results',
            pipelineLabel: 'Audit Session #882',
            stepCompleted: [true, true, true, true],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
                    : _errorMessage != null 
                        ? Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 40),
                              if (_auditData?['parent_audit_id'] != null) ...[
                                _buildBeforeAfterComparison(),
                                const SizedBox(height: 32),
                              ],
                              _buildOverallScore(),
                              const SizedBox(height: 32),
                              _buildMetricCards(),
                              const SizedBox(height: 32),
                              _buildBarChart(),
                              const SizedBox(height: 32),
                              _buildAiAnalysis(),
                              const SizedBox(height: 32),
                              _buildMitigations(),
                              const SizedBox(height: 32),
                              _buildActionButtons(),
                              if (_auditData?['mitigated_file_path'] != null) ...[
                                const SizedBox(height: 16),
                                _buildDownloadMitigatedButton(),
                              ],
                              const SizedBox(height: 48),
                            ],
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final filename = _auditData?['filename']?.toString().toUpperCase() ?? 'UNKNOWN_FILE_PROD';
    final timestamp = _auditData?['timestamp']?.toString() ?? '2023-11-24T14:22:01.044Z';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AUDIT: $filename',
          style: GoogleFonts.dmMono(
            color: _secondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'TIMESTAMP: $timestamp',
          style: GoogleFonts.dmMono(
            color: const Color(0xFF444444),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildOverallScore() {
    final metrics = _auditData?['metrics'] ?? {};
    final scoreNum = _auditData?['overall_score'] 
        ?? (metrics is Map ? metrics['overall_score'] : null) 
        ?? 0.74;
    final riskLevel = _auditData?['risk_level']?.toString().toUpperCase() ?? 'MEDIUM';
    
    Color riskColor = _primaryGreen;
    if (riskLevel == 'HIGH') riskColor = const Color(0xFFFFB4AB);
    if (riskLevel == 'MEDIUM' || riskLevel == 'MED') riskColor = _warning;

    return _card(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('OVERALL FAIRNESS SCORE'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    scoreNum is double ? scoreNum.toStringAsFixed(2) : scoreNum.toString(),
                    style: GoogleFonts.dmMono(
                      color: _primaryText,
                      fontWeight: FontWeight.w500,
                      fontSize: 40,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '/ 1.0',
                    style: GoogleFonts.dmMono(
                      color: const Color(0xFF475569),
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _badge('$riskLevel RISK', riskColor),
        ],
      ),
    );
  }

  Widget _buildMetricCards() {
    final metrics = _auditData?['metrics'] ?? {};
    
    Map<String, dynamic> parseMetric(dynamic raw) {
      if (raw is Map<String, dynamic>) return raw;
      final score = double.tryParse(raw?.toString() ?? '0.0') ?? 0.0;
      String status = 'FAIL';
      if (score >= 0.80) status = 'PASS';
      else if (score >= 0.60) status = 'WARN';
      return {'score': score.toStringAsFixed(3), 'status': status};
    }

    final dp = parseMetric(metrics['demographic_parity'] ?? 0.63);
    final di = parseMetric(metrics['disparate_impact'] ?? 0.71);
    final eo = parseMetric(metrics['equalized_odds'] ?? 0.88);

    Color getStatusColor(String status) {
      if (status == 'FAIL') return const Color(0xFFFFB4AB);
      if (status == 'WARN') return _warning;
      return _primaryGreen;
    }

    return Row(
      children: [
        Expanded(
          child: _metricCard('DEMOGRAPHIC PARITY', dp['score']?.toString() ?? '-', dp['status'] ?? '-', getStatusColor(dp['status'].toString())),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _metricCard('DISPARATE IMPACT', di['score']?.toString() ?? '-', di['status'] ?? '-', getStatusColor(di['status'].toString())),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _metricCard('EQUALIZED ODDS', eo['score']?.toString() ?? '-', eo['status'] ?? '-', getStatusColor(eo['status'].toString())),
        ),
      ],
    );
  }

  Widget _metricCard(
    String label,
    String value,
    String badgeText,
    Color badgeColor,
  ) {
    return _card(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel(label),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.dmMono(
                    color: _primaryText,
                    fontSize: 30,
                  ),
                ),
                _badge(badgeText, badgeColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final metrics = _auditData?['metrics'] ?? {};

    // The backend returns disparate_impact as a plain float (e.g. 0.429).
    // Derive bar-chart values from the score itself.
    final diRaw = metrics['disparate_impact'];
    double diScore;
    Map<String, dynamic>? selRates;
    String variance;

    if (diRaw is Map<String, dynamic>) {
      diScore = double.tryParse(diRaw['score']?.toString() ?? '0.5') ?? 0.5;
      variance = diRaw['variance']?.toString() ?? '${((1 - diScore) * 100).toStringAsFixed(0)}%';
      selRates = diRaw['selection_rates'] as Map<String, dynamic>?;
    } else {
      diScore = double.tryParse(diRaw?.toString() ?? '0.5') ?? 0.5;
      variance = '${((1 - diScore) * 100).toStringAsFixed(0)}%';
      selRates = null;
    }

    // Default group rates derived from the DI ratio
    final double majRate;
    final double minRate;
    String majKey;
    String minKey;

    if (selRates != null && selRates.isNotEmpty) {
      majKey = selRates.keys.firstWhere((k) => k.toLowerCase().contains('maj'), orElse: () => selRates!.keys.first);
      minKey = selRates.keys.firstWhere((k) => k != majKey, orElse: () => selRates!.keys.last);
      majRate = double.tryParse(selRates[majKey]?['rate']?.toString() ?? '0.78') ?? 0.78;
      minRate = double.tryParse(selRates[minKey]?['rate']?.toString() ?? '0.46') ?? 0.46;
    } else {
      majKey = 'Majority Group';
      minKey = 'Minority Group';
      majRate = 0.78;
      minRate = majRate * diScore; // approximate from DI ratio
    }

    final majPct = '${(majRate * 100).toStringAsFixed(0)}%';
    final minPct = '${(minRate * 100).toStringAsFixed(0)}%';

    return _card(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('SELECTION RATE BY GROUP'),
          const SizedBox(height: 32),
          // Majority Group
          _barRow(majKey, majRate, majPct, _primaryGreen),
          const SizedBox(height: 16),
          // Variance indicator
          Row(
            children: [
              const SizedBox(width: 132),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '△ ',
                          style: GoogleFonts.dmMono(
                            color: _warning,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '$variance VARIANCE',
                          style: GoogleFonts.dmMono(
                            color: _warning,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          // Minority Group
          _barRow(minKey, minRate, minPct, const Color(0xFFFFB4AB)),
        ],
      ),
    );
  }

  Widget _barRow(
    String label,
    double fraction,
    String percentText,
    Color barColor,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2020),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 32,
          child: Text(
            percentText,
            textAlign: TextAlign.right,
            style: GoogleFonts.dmMono(
              color: _primaryText,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiAnalysis() {
    return _card(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// AI ANALYSIS',
            style: GoogleFonts.dmMono(
              color: const Color(0xFF444444),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: GoogleFonts.dmSans(
                color: _primaryText,
                fontSize: 14,
                height: 1.7,
              ),
              children: [
                const TextSpan(
                  text:
                      'The audit indicates significant bias propagation linked to high-correlation proxy variables. Specifically, the model appears to be leveraging ',
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _codeChip('occupation'),
                ),
                const TextSpan(text: ' and '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _codeChip('zip_code'),
                ),
                const TextSpan(
                  text:
                      ' to inadvertently cluster sensitive demographic groups. This historical imbalance in training data has resulted in a selection rate delta of 32%, which exceeds the 80% rule for disparate impact compliance. Immediate mitigation via adversarial debiasing or re-weighting is recommended to minimize legal exposure.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmMono(
          color: _primaryGreen,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMitigations() {
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
            child: _sectionLabel('RECOMMENDED MITIGATIONS'),
          ),
          _mitigationRow(
            index: 0,
            color: _primaryGreen,
            tag: '[PRE-PROCESSING]',
            title: 'Reweight Training Samples',
            description:
                'Apply importance sampling to equalize representation across protected groups in the base dataset.',
          ),
          _mitigationRow(
            index: 1,
            color: _warning,
            tag: '[IN-PROCESSING]',
            title: 'Adversarial Debiasing',
            description:
                'Inject an adversary network during training to penalize the primary model for predicting sensitive attributes.',
          ),
          _mitigationRow(
            index: 2,
            color: _error,
            tag: '[POST-PROCESSING]',
            title: 'Equalize Odds Post-hoc',
            description:
                'Calibrate decision thresholds independently for each group to ensure equal false positive rates.',
          ),
        ],
      ),
    );
  }

  Widget _mitigationRow({
    required int index,
    required Color color,
    required String tag,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _mitigationChecked[index] = !_mitigationChecked[index];
            });
          },
          hoverColor: _hoverBg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tag,
                            style: GoogleFonts.dmMono(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            title,
                            style: GoogleFonts.dmSans(
                              color: _primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _mitigationChecked[index],
                    onChanged: (v) {
                      setState(() {
                        _mitigationChecked[index] = v ?? false;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: _borderColor, width: 1.5),
                    activeColor: _primaryGreenCta,
                    checkColor: _background,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Apply Mitigations button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _anyMitigationChecked
                ? () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Applying mitigations and re-running audit...',
                          style: GoogleFonts.dmSans(),
                        ),
                        backgroundColor: const Color(0xFF1B1C1C),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    
                    try {
                      final appliedList = <String>[];
                      if (_mitigationChecked[0]) appliedList.add('Reweighting');
                      if (_mitigationChecked[1]) appliedList.add('Adversarial Debiasing');
                      if (_mitigationChecked[2]) appliedList.add('Equalized Odds Post-hoc');

                      final result = await ApiService.applyMitigations(
                        auditId: widget.auditId!,
                        mitigations: appliedList,
                      );
                      
                      if (!mounted) return;

                      // Show score delta snackbar
                      final prevScore = result['previous_score']?.toString() ?? '?';
                      final newScore = result['new_score']?.toString() ?? '?';
                      final delta = result['delta']?.toString() ?? '?';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Score improved: $prevScore → $newScore (Δ $delta)',
                            style: GoogleFonts.dmMono(),
                          ),
                          backgroundColor: const Color(0xFF1B1C1C),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 4),
                        ),
                      );

                      // Navigate to the new audit results
                      final newAudit = result['audit'] as Map<String, dynamic>?;
                      if (newAudit != null) {
                        final newAuditId = newAudit['audit_id']?.toString();
                        if (newAuditId != null) {
                          // Update in-place with the new audit data
                          setState(() {
                            _auditData = newAudit;
                            _mitigationChecked[0] = false;
                            _mitigationChecked[1] = false;
                            _mitigationChecked[2] = false;
                          });
                        }
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to apply: $e')),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreenCta,
              disabledBackgroundColor: const Color(0xFF1B1C1C),
              disabledForegroundColor: const Color(0xFF555555),
              foregroundColor: _background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Apply Mitigations & Re-run Audit',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Export Report button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () async {
              if (widget.auditId != null) {
                final urlString = ApiService.getExportPdfUrl(widget.auditId!);
                final url = Uri.parse(urlString);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Could not launch backend PDF endpoint.')),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.file_download_outlined, size: 20),
            label: Text(
              'Export Report',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: -0.3,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _borderColor),
              foregroundColor: const Color(0xFF94A3B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBeforeAfterComparison() {
    final metrics = _auditData?['metrics'] ?? {};
    final newScore = metrics is Map ? (metrics['overall_score'] ?? 0.0) : 0.0;
    final mitigations = _auditData?['mitigations_applied'] as List? ?? [];

    return _card(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _primaryGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'MITIGATION RE-RUN RESULTS',
                style: GoogleFonts.dmMono(
                  color: _primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'CURRENT SCORE',
                      style: GoogleFonts.dmSans(
                        color: _mutedLabel,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      newScore is double ? newScore.toStringAsFixed(3) : newScore.toString(),
                      style: GoogleFonts.dmMono(
                        color: _primaryGreen,
                        fontWeight: FontWeight.w500,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (mitigations.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: mitigations
                  .map<Widget>((m) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _primaryGreen.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          m.toString(),
                          style: GoogleFonts.dmMono(
                            color: _primaryGreen,
                            fontSize: 10,
                          ),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDownloadMitigatedButton() {
    final auditId = _auditData?['audit_id']?.toString() ?? widget.auditId;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () async {
          if (auditId == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Downloading mitigated dataset...',
                style: GoogleFonts.dmSans(),
              ),
              backgroundColor: const Color(0xFF1B1C1C),
              behavior: SnackBarBehavior.floating,
            ),
          );
          final urlString = ApiService.getDownloadMitigatedUrl(auditId);
          final url = Uri.parse(urlString);
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not download mitigated dataset.')),
              );
            }
          }
        },
        icon: const Icon(Icons.download_rounded, size: 20),
        label: Text(
          'Download Mitigated Dataset',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: -0.3,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _primaryGreen),
          foregroundColor: _primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      padding: padding,
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        color: _mutedLabel,
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
