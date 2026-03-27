import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sidebar.dart';
import '../services/api_service.dart';

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

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalAudits = 0;
  List<dynamic> _audits = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getAuditHistory(
        page: _currentPage,
        perPage: 10,
        domain: _selectedDomain,
        riskLevel: _selectedRisk,
        search: _searchQuery,
      );
      setState(() {
        _audits = res['data'] ?? [];
        _totalAudits = res['total'] ?? 0;
        _totalPages = (res['total'] / 10).ceil();
        if (_totalPages < 1) _totalPages = 1;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged() {
    _currentPage = 1;
    _fetchHistory();
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
        _statChip('$_totalAudits Audits Total'),
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
                onSubmitted: (value) {
                  setState(() => _searchQuery = value);
                  _onFilterChanged();
                },
                style: GoogleFonts.dmSans(
                  color: _primaryText,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Search audits... (Press Enter)',
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
          onChanged: (v) {
            setState(() => _selectedDomain = v!);
            _onFilterChanged();
          },
        ),
        const SizedBox(width: 12),
        // Risk dropdown
        _dropdown(
          label: 'Risk',
          value: _selectedRisk,
          items: _risks,
          onChanged: (v) {
            setState(() => _selectedRisk = v!);
            _onFilterChanged();
          },
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
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(color: _primaryGreen)),
      );
    }
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_audits.isEmpty) {
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
      children: _audits
          .map((audit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _auditCard(audit as Map<String, dynamic>),
              ))
          .toList(),
    );
  }

  Widget _auditCard(Map<String, dynamic> audit) {
    // Determine risk level correctly
    final riskLevel = (audit['risk_level'] ?? 'LOW').toString().toUpperCase();
    Color riskColor = _primaryGreen;
    if (riskLevel == 'HIGH') riskColor = _error;
    if (riskLevel == 'MEDIUM') riskColor = _warning;

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
                      audit['filename']?.toString() ?? 'Unnamed Audit',
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
                  audit['timestamp'] != null 
                    ? audit['timestamp'].toString().substring(0, 10)
                    : 'N/A',
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
                      riskLevel,
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
                    onPressed: () => context.go('/results', extra: audit['id'] ?? audit['_id']),
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
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_currentPage > 1) 
          _paginationButton('←', false, () {
            setState(() => _currentPage--);
            _fetchHistory();
          }),
        const SizedBox(width: 8),
        _paginationButton('Page $_currentPage of $_totalPages', true, () {}),
        const SizedBox(width: 8),
        if (_currentPage < _totalPages)
          _paginationButton('→', false, () {
            setState(() => _currentPage++);
            _fetchHistory();
          }),
      ],
    );
  }

  Widget _paginationButton(String label, bool isActive, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
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
