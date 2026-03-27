import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sidebar.dart';
import '../services/api_service.dart';

class NewAuditScreen extends StatefulWidget {
  const NewAuditScreen({super.key});

  @override
  State<NewAuditScreen> createState() => _NewAuditScreenState();
}

class _NewAuditScreenState extends State<NewAuditScreen> {
  // Design tokens
  static const Color _background = Color(0xFF0F0F0F);
  static const Color _surface = Color(0xFF161616);
  static const Color _borderColor = Color(0xFF262626);
  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _selectedBg = Color(0xFF166534);
  static const Color _inputBg = Color(0xFF1C1C1C);
  static const Color _primaryText = Color(0xFFE5E5E5);
  static const Color _secondaryText = Color(0xFF888888);
  static const Color _mutedLabel = Color(0xFF444444);

  String? _fileName;
  String? _fileSize;
  String? _fileId;
  final Set<String> _selectedAttributes = {'gender', 'race'};

  final List<String> _allAttributes = [
    'gender',
    'race',
    'age',
    'income',
    'zip_code',
    'education',
  ];

  // Pipeline stepper animation
  final List<bool> _stepCompleted = [false, false, false, false];
  bool _isRunning = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json'],
      withData: true,
    );
    if (result != null) {
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) return;
      
      setState(() {
        _fileName = '${file.name} (Uploading...)';
      });

      try {
        final res = await ApiService.uploadFile(
          filename: file.name,
          fileBytes: bytes,
        );
        setState(() {
          _fileId = res['file_id'];
          _fileName = file.name;
          final size = file.size;
          if (size > 1024 * 1024) {
            _fileSize = '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
          } else {
            _fileSize = '${(size / 1024).toStringAsFixed(1)} KB';
          }
          _stepCompleted[0] = true;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
        setState(() {
          _fileName = null;
        });
      }
    }
  }

  Future<void> _runAudit() async {
    if (_isRunning || _fileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a dataset first.')),
      );
      return;
    }
    setState(() => _isRunning = true);

    try {
      final res = await ApiService.runAudit(
        fileId: _fileId!,
        filename: _fileName!,
        protectedAttributes: _selectedAttributes.toList(),
        domain: 'Hiring',
      );

      setState(() {
        _stepCompleted[1] = true;
        _stepCompleted[2] = true;
        _stepCompleted[3] = true;
      });

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      context.go('/results', extra: res['audit_id']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audit failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Row(
        children: [
          Sidebar(
            currentRoute: '/',
            pipelineLabel: 'New Audit Session',
            stepCompleted: _stepCompleted,
          ),
          // Top bar + main content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: SizedBox(
                        width: 560,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 40),
                            _buildDatasetUpload(),
                            const SizedBox(height: 32),
                            _buildProtectedAttributes(),
                            const SizedBox(height: 40),
                            _buildRunButton(),
                            const SizedBox(height: 64),
                            _buildMetricsFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: _background,
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'FairForge',
            style: GoogleFonts.dmSans(
              color: _primaryText,
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              'Sign in with Google',
              style: GoogleFonts.dmSans(
                color: _primaryText,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Audit',
          style: GoogleFonts.dmSans(
            color: _primaryText,
            fontWeight: FontWeight.w600,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload a dataset and configure protected attributes to begin.',
          style: GoogleFonts.dmSans(
            color: _secondaryText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDatasetUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 1 — DATASET',
          style: GoogleFonts.dmSans(
            color: _mutedLabel,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Dashed upload zone
              GestureDetector(
                onTap: _pickFile,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _borderColor,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _DashedBorderPainter(
                        color: _borderColor,
                        borderRadius: 8,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              color: _mutedLabel,
                              size: 40,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Drop CSV or JSON here',
                              style: GoogleFonts.dmSans(
                                color: _secondaryText,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _primaryGreen),
                              ),
                              child: Text(
                                'Browse Files',
                                style: GoogleFonts.dmSans(
                                  color: _primaryGreen,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // File indicator
              if (_fileName != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _inputBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fileName!,
                          style: GoogleFonts.dmSans(
                            color: _primaryText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        _fileSize ?? '',
                        style: GoogleFonts.dmMono(
                          color: _secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProtectedAttributes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 2 — PROTECTED ATTRIBUTES',
          style: GoogleFonts.dmSans(
            color: _mutedLabel,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allAttributes.map((attr) {
                  final isSelected = _selectedAttributes.contains(attr);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedAttributes.remove(attr);
                        } else {
                          _selectedAttributes.add(attr);
                        }
                      });
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? _selectedBg : _inputBg,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: isSelected ? _primaryGreen : _borderColor,
                          ),
                        ),
                        child: Text(
                          attr,
                          style: GoogleFonts.dmSans(
                            color: isSelected ? Colors.white : _secondaryText,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Select attributes to analyze for bias.',
                style: GoogleFonts.dmSans(
                  color: _secondaryText,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRunButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: _isRunning ? null : _runAudit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          disabledBackgroundColor: _primaryGreen.withValues(alpha: 0.5),
          foregroundColor: _background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isRunning ? 'Running Audit...' : 'Run Audit',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (!_isRunning) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18),
            ],
            if (_isRunning) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _background,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsFooter() {
    return Column(
      children: [
        Container(height: 1, color: _borderColor),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildMetric(
                label: 'COMPUTE LIMIT',
                value: '50,000',
                unit: 'rows/mo',
              ),
            ),
            Expanded(
              child: _buildMetric(
                label: 'AVAILABLE CREDITS',
                value: '84.2%',
                unit: null,
                valueColor: _primaryGreen,
              ),
            ),
            Expanded(
              child: _buildMetric(
                label: 'ENGINE LATENCY',
                value: '0.42',
                unit: 'ms',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    String? unit,
    Color valueColor = _primaryText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: _mutedLabel,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.dmMono(
                color: valueColor,
                fontSize: 18,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.dmSans(
                  color: _secondaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// Custom dashed border painter
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    // No-op: using solid border in container for simplicity
    // The dashed appearance comes from the border style in the container
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
