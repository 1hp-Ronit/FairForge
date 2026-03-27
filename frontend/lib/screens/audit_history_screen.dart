import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sidebar.dart';

class AuditHistoryScreen extends StatefulWidget {
  const AuditHistoryScreen({super.key});

  @override
  State<AuditHistoryScreen> createState() => _AuditHistoryScreenState();
}

class _AuditHistoryScreenState extends State<AuditHistoryScreen> {
  // Design tokens
  static const Color _background = Color(0xFF0F0F0F);
  static const Color _surface = Color(0xFF161616);
  static const Color _borderColor = Color(0xFF262626);
  static const Color _elevatedBg = Color(0xFF1A1A1A);
  static const Color _primaryGreen = Color(0xFF4BE277);
  static const Color _warning = Color(0xFFFBBF24);
  static const Color _error = Color(0xFFFFB4AB);
  static const Color _primaryText = Color(0xFFE5E5E5);
  static const Color _secondaryText = Color(0xFF888888);
  static const Color _mutedLabel = Color(0xFF555555);
  static const Color _inputBg = Color(0xFF1C1C1C);
  static const Color _hoverBg = Color(0xFF1B1C1C);

  String _searchQuery = '';
  String _selectedDomain = 'All';
  String _selectedRisk = 'All';

  final List<String> _domains = ['All', 'Hiring', 'Lending', 'Healthcare', 'Insurance'];
  final List<String> _risks = ['All', 'HIGH', 'MED', 'LOW'];

  final List<Map<String, dynamic>> _audits = [
    {
      'name': 'hiring_model_v3_prod',
      'domain': 'Hiring',
      'timestamp': '2023-11-24T14:22:01Z',
      'risk': 'HIGH',
      'score': 0.63,
    },
    {
      'name': 'lending_risk_assessment',
      'domain': 'Lending',
      'timestamp': '2023-11-22T09:15:33Z',
      'risk': 'MED',
      'score': 0.71,
    },
    {
      'name': 'patient_triage_classifier',
      'domain': 'Healthcare',
      'timestamp': '2023-11-20T11:08:12Z',
      'risk': 'LOW',
      'score': 0.88,
    },
    {
      'name': 'insurance_pricing_v2',
      'domain': 'Insurance',
      'timestamp': '2023-11-18T16:42:05Z',
      'risk': 'HIGH',
      'score': 0.58,
    },
    {
      'name': 'credit_scoring_model',
      'domain': 'Lending',
      'timestamp': '2023-11-15T08:30:22Z',
      'risk': 'MED',
      'score': 0.74,
    },
    {
      'name': 'resume_screening_bert',
      'domain': 'Hiring',
      'timestamp': '2023-11-12T13:55:41Z',
      'risk': 'HIGH',
      'score': 0.52,
    },
    {
      'name': 'readmission_predictor',
      'domain': 'Healthcare',
      'timestamp': '2023-11-10T10:20:18Z',
      'risk': 'LOW',
      'score': 0.91,
    },
    {
      'name': 'salary_prediction_xgb',
      'domain': 'Hiring',
      'timestamp': '2023-11-08T15:12:33Z',
      'risk': 'MED',
      'score': 0.69,
    },
  ];

  List<Map<String, dynamic>> get _filteredAudits {
    return _audits.where((audit) {
      final matchesSearch = _searchQuery.isEmpty ||
          audit['name'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
      final matchesDomain =
          _selectedDomain == 'All' || audit['domain'] == _selectedDomain;
      final matchesRisk =
          _selectedRisk == 'All' || audit['risk'] == _selectedRisk;
      return matchesSearch && matchesDomain && matchesRisk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Row(
        children: [
          const Sidebar(
            currentRoute: '/history',
            pipelineLabel: 'Audit History',
            stepCompleted: [false, false, false, false],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 32),
                    _buildStatPills(),
                    const SizedBox(height: 32),
                    _buildFilterBar(),
                    const SizedBox(height: 24),
                    _buildAuditList(),
                    const SizedBox(height: 32),
                    _buildPagination(),
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

  Widget _buildPageHeader() {
    return Text(
      'Audit History',
      style: GoogleFonts.dmSans(
        color: _primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 30,
      ),
    );
  }

  Widget _buildStatPills() {
    return Row(
      children: [
        _statChip('14 Audits'),
        const SizedBox(width: 12),
        _statChip('Avg Score 0.71'),
        const SizedBox(width: 12),
        _statChip('Top Bias: Gender'),
      ],
    );
  }

  Widget _statChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _elevatedBg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmMono(
          color: _secondaryText,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        // Search input
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              style: GoogleFonts.dmSans(
                color: _primaryText,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Search audits...',
                hintStyle: GoogleFonts.dmSans(
                  color: _mutedLabel,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: _mutedLabel,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Domain dropdown
        _dropdown(
          label: 'Domain',
          value: _selectedDomain,
          items: _domains,
          onChanged: (v) => setState(() => _selectedDomain = v!),
        ),
        const SizedBox(width: 12),
        // Risk dropdown
        _dropdown(
          label: 'Risk',
          value: _selectedRisk,
          items: _risks,
          onChanged: (v) => setState(() => _selectedRisk = v!),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                '$label: $item',
                style: GoogleFonts.dmSans(
                  color: _primaryText,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          dropdownColor: _elevatedBg,
          icon: const Icon(Icons.expand_more, color: _mutedLabel, size: 18),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildAuditList() {
    final audits = _filteredAudits;
    if (audits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        child: Text(
          'No audits match your filters.',
          style: GoogleFonts.dmSans(
            color: _mutedLabel,
            fontSize: 14,
          ),
        ),
      );
    }
    return Column(
      children: audits
          .map((audit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _auditCard(audit),
              ))
          .toList(),
    );
  }

  Widget _auditCard(Map<String, dynamic> audit) {
    final risk = audit['risk'] as String;
    Color riskColor;
    switch (risk) {
      case 'HIGH':
        riskColor = _error;
        break;
      case 'MED':
        riskColor = _warning;
        break;
      default:
        riskColor = _primaryGreen;
    }

    final domain = audit['domain'] as String;

    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        hoverColor: _hoverBg,
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              // Left: name + domain tag
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audit['name'] as String,
                      style: GoogleFonts.dmSans(
                        color: _primaryText,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _elevatedBg,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        domain,
                        style: GoogleFonts.dmSans(
                          color: _secondaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Center: timestamp
              Expanded(
                flex: 2,
                child: Text(
                  (audit['timestamp'] as String).substring(0, 10),
                  style: GoogleFonts.dmMono(
                    color: _mutedLabel,
                    fontSize: 11,
                  ),
                ),
              ),
              // Right: risk badge + view button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: riskColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      risk,
                      style: GoogleFonts.dmSans(
                        color: riskColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => context.go('/results'),
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'View Report →',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _paginationButton('←', false),
        const SizedBox(width: 8),
        _paginationButton('1', true),
        const SizedBox(width: 8),
        _paginationButton('2', false),
        const SizedBox(width: 8),
        _paginationButton('3', false),
        const SizedBox(width: 8),
        _paginationButton('→', false),
      ],
    );
  }

  Widget _paginationButton(String label, bool isActive) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? _primaryGreen.withValues(alpha: 0.1) : _surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? _primaryGreen.withValues(alpha: 0.3) : _borderColor,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmMono(
              color: isActive ? _primaryGreen : _secondaryText,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
