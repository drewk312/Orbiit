import 'package:flutter/material.dart';
import '../services/storage/storage_organizer_service.dart';
import '../widgets/organizer_wizard_steps.dart';

class StorageOrganizerScreen extends StatefulWidget {
  const StorageOrganizerScreen({super.key});

  @override
  State<StorageOrganizerScreen> createState() => _StorageOrganizerScreenState();
}

class _StorageOrganizerScreenState extends State<StorageOrganizerScreen> {
  int _currentStep = 0; // 0: Select, 1: Preview, 2: Execute

  bool _isScanning = false;
  StorageAnalysis? _analysis;

  // Execution state
  final List<String> _logs = [];
  bool _isComplete = false;

  final StorageOrganizerService _service = StorageOrganizerService();

  @override
  void initState() {
    super.initState();
    // Listen to service logs
    _service.progressStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
        });
      }
    });
  }

  // --------------------------------------------------------------------------
  // ACTIONS
  // --------------------------------------------------------------------------

  Future<void> _handlePathSelected(String path) async {
    setState(() {
      _isScanning = true;
    });

    try {
      // Run analysis
      final analysis = await _service.analyzeDrive(path);

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _isScanning = false;
          _currentStep = 1; // Move to Preview
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning drive: $e')),
        );
      }
    }
  }

  Future<void> _startOrganization() async {
    if (_analysis == null) return;

    setState(() {
      _currentStep = 2; // Move to Execute
      _logs.clear();
      _logs.add('Starting organization process...');
    });

    final drivePath = _analysis!.drivePath;

    try {
      // 1. Setup Folders
      await _service.setupFolderStructure(drivePath);

      // 2. Organize Games
      await _service.organizeGames(
        drivePath,
        OrganizationStrategy.autoSortAll,
      );

      // 3. Cleanup Duplicates (Optional, safely)
      // await _service.removeDuplicates(drivePath);

      if (mounted) {
        setState(() {
          _isComplete = true;
          _logs.add('PROCESS COMPLETE - Success!');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _logs.add('ERROR: $e');
        });
      }
    }
  }

  void _resetWizard() {
    setState(() {
      _currentStep = 0;

      _analysis = null;
      _isComplete = false;
      _logs.clear();
    });
  }

  // --------------------------------------------------------------------------
  // UI BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Wizard Progress Indicator
            _buildWizardHeader(),
            const SizedBox(height: 32),

            // Main Content Area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return OrganizerStep1Selection(
          onPathSelected: _handlePathSelected,
          isScanning: _isScanning,
        );
      case 1:
        return OrganizerStep2Preview(
          analysis: _analysis!,
          onStartOrganization: _startOrganization,
          onCancel: _resetWizard,
        );
      case 2:
        return OrganizerStep3Execution(
          logs: _logs,
          isComplete: _isComplete,
          onFinish: _resetWizard,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWizardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, 'Select Drive'),
        _buildConnector(0),
        _buildStepDot(1, 'Review'),
        _buildConnector(1),
        _buildStepDot(2, 'Organize'),
      ],
    );
  }

  Widget _buildStepDot(int stepIndex, String label) {
    final isActive = _currentStep >= stepIndex;
    final isCurrent = _currentStep == stepIndex;
    const activeColor = Color(0xFF00C2FF);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 32 : 16,
          height: 16,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white24,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: activeColor.withValues(alpha: 0.4),
                        blurRadius: 12)
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white24,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int stepIndex) {
    final isActive = _currentStep > stepIndex;
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      color: isActive ? const Color(0xFF00C2FF) : Colors.white10,
    );
  }
}
