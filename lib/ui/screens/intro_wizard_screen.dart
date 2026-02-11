import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/theme.dart';
import '../../providers/theme_provider.dart';
import '../../screens/navigation_wrapper.dart';
import '../../services/sd_card_service.dart';

class IntroWizardScreen extends StatefulWidget {
  const IntroWizardScreen({super.key});

  @override
  State<IntroWizardScreen> createState() => _IntroWizardScreenState();
}

class _IntroWizardScreenState extends State<IntroWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  // State for Drive Selection
  final SDCardService _sdService = SDCardService();
  List<SDCardInfo> _drives = [];
  String? _selectedDrivePath;
  bool _isScanning = false;
  bool _isSettingUp = false;
  String _setupStatus = '';
  bool _setupSuccess = false;

  @override
  void initState() {
    super.initState();
    _scanDrives();
  }

  Future<void> _scanDrives() async {
    setState(() {
      _isScanning = true;
    });
    try {
      final drives = await _sdService.detectSDCards();
      setState(() {
        _drives = drives;
        _isScanning = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning drives: $e')),
        );
      }
    }
  }

  Future<void> _setupDrive() async {
    if (_selectedDrivePath == null) return;

    setState(() {
      _isSettingUp = true;
      _setupStatus = 'Creating folder structure...';
    });

    try {
      final result = await _sdService.setupSDCard(
        _selectedDrivePath!,
        createOptional: true,
      );

      setState(() {
        _isSettingUp = false;
        if (result.success) {
          _setupSuccess = true;
          _setupStatus =
              'Successfully created ${result.created.length} folders!';
          Future.delayed(const Duration(seconds: 1), () {
            _nextPage();
          });
        } else {
          _setupStatus = 'Setup failed: ${result.errors.join(", ")}';
        }
      });
    } catch (e) {
      setState(() {
        _isSettingUp = false;
        _setupStatus = 'Error: $e';
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _finishSetup();
    }
  }

  Future<void> _finishSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const NavigationWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header / Progress
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index <= _currentPage
                              ? theme.primaryColor
                              : theme.surfaceColor,
                        ),
                      );
                    }),
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildWelcomeStep(theme),
                      _buildDriveStep(theme),
                      _buildFinishStep(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep(WiiGCTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rocket_launch_rounded,
            size: 80,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Orbiit',
            style: theme.textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'The ultimate manager for your Wii and GameCube library.\nLet\'s get your flight deck ready.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: const Text('Start Setup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriveStep(WiiGCTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Storage',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the USB drive or SD card where you want to store your games.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          if (_isScanning)
            const Center(child: CircularProgressIndicator())
          else if (_drives.isEmpty)
            _buildNoDrivesFound(theme)
          else
            Expanded(
              child: ListView.separated(
                itemCount: _drives.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final drive = _drives[index];
                  final isSelected = _selectedDrivePath == drive.path;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDrivePath = drive.path;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor.withValues(alpha: 0.1)
                            : theme.surfaceColor,
                        border: Border.all(
                          color: isSelected
                              ? theme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            drive.busType == 'USB'
                                ? Icons.usb
                                : Icons.sd_storage,
                            color: theme.textColor,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  drive.displayName,
                                  style: theme.textTheme.titleLarge,
                                ),
                                Text(
                                  'Free Space: ${drive.freeSpace}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: theme.primaryColor),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          if (_setupStatus.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _setupSuccess
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _setupSuccess ? Icons.check : Icons.info,
                    color: _setupSuccess ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(_setupStatus,
                          style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedDrivePath != null && !_isSettingUp
                  ? _setupDrive
                  : null,
              child: _isSettingUp
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Set Up Drive'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDrivesFound(WiiGCTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.usb_off,
              size: 48, color: theme.textColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No valid drives found',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Please insert a USB drive or SD card and try again.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _scanDrives,
            icon: const Icon(Icons.refresh),
            label: const Text('Rescan'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishStep(WiiGCTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 64,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'All Configuration Complete',
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your library is ready. You can now start downloading games or import your existing collection.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          ElevatedButton(
            onPressed: _finishSetup,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: const Text('Launch Orbiit'),
          ),
        ],
      ),
    );
  }
}
