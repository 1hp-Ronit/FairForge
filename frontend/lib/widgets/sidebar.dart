import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'support_chatbot.dart';

class Sidebar extends StatelessWidget {
  final String currentRoute;
  final String pipelineLabel;
  final List<bool> stepCompleted;

  const Sidebar({
    super.key,
    required this.currentRoute,
    this.pipelineLabel = 'New Audit Session',
    this.stepCompleted = const [true, false, false, false],
  });

  static const double width = 220;

  // Design tokens from Stitch
  static const Color _sidebarBg = Color(0xFF1B1C1C);
  static const Color _borderColor = Color(0xFF262626);
  static const Color _primaryGreen = Color(0xFF4BE277);
  static const Color _inactiveDot = Color(0xFF292A2A);
  static const Color _mutedText = Color(0xFF64748B); // slate-500

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: _sidebarBg,
        border: Border(
          right: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'FairForge',
              style: GoogleFonts.dmSans(
                color: _primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Pipeline header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PIPELINE',
                  style: GoogleFonts.spaceGrotesk(
                    color: _primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pipelineLabel,
                  style: GoogleFonts.dmMono(
                    color: _mutedText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Pipeline steps
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPipelineStep(
                    icon: Icons.storage_rounded,
                    label: 'DATA INGESTION',
                    isActive: stepCompleted[0],
                  ),
                  const SizedBox(height: 24),
                  _buildPipelineStep(
                    icon: Icons.analytics_outlined,
                    label: 'METRIC COMPUTATION',
                    isActive: stepCompleted[1],
                  ),
                  const SizedBox(height: 24),
                  _buildPipelineStep(
                    icon: Icons.psychology_outlined,
                    label: 'LLM ANALYSIS',
                    isActive: stepCompleted[2],
                  ),
                  const SizedBox(height: 24),
                  _buildPipelineStep(
                    icon: Icons.description_outlined,
                    label: 'REPORT READY',
                    isActive: stepCompleted[3],
                  ),
                  const Spacer(),
                  // Navigation links
                  _buildNavLink(
                    context: context,
                    icon: Icons.add_circle_outline,
                    label: 'NEW AUDIT',
                    route: '/',
                  ),
                  const SizedBox(height: 16),
                  _buildNavLink(
                    context: context,
                    icon: Icons.history,
                    label: 'AUDIT HISTORY',
                    route: '/history',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: _borderColor,
                  ),
                  const SizedBox(height: 24),
                  _buildFooterLink(
                    icon: Icons.menu_book_outlined,
                    label: 'DOCUMENTATION',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildFooterLink(
                    icon: Icons.support_agent_outlined,
                    label: 'SUPPORT',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const SupportChatbot(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final color = isActive ? _primaryGreen : _mutedText;

    return Row(
      children: [
        // Dot indicator
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? _primaryGreen : _inactiveDot,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavLink({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isActive = currentRoute == route;
    final color = isActive ? _primaryGreen : _mutedText;

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(8),
      hoverColor: const Color(0xFF292A2A),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: const Color(0xFF292A2A),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: _mutedText, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: _mutedText,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

