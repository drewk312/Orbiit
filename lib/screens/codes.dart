import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/txtcodes_service.dart';
import '../widgets/immersive_glass_header.dart';

/// When [embedInWrapper] is true, returns only content (no app shell) for use in NavigationWrapper.
class TxtCodesScreen extends StatefulWidget {
  final bool embedInWrapper;

  const TxtCodesScreen({super.key, this.embedInWrapper = false});

  @override
  State<TxtCodesScreen> createState() => _TxtCodesScreenState();
}

class _TxtCodesScreenState extends State<TxtCodesScreen> {
  final TextEditingController _idController = TextEditingController();
  String _status = '';
  String _codes = '';
  bool _loading = false;

  Future<void> _fetchCodes() async {
    final id = _idController.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _loading = true;
      _status = 'Fetching codes for $id...';
      _codes = '';
    });
    final result = await TxtCodesService.fetchCodes(id);
    setState(() {
      _loading = false;
      _status = result.status;
      _codes = result.codes ?? '';
    });
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF00C2FF).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, color: Color(0xFF00C2FF), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _idController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Enter Game ID (e.g., RMCE01)',
                      hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _fetchCodes(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _fetchCodes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C2FF),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('GET',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Save Release',
                  child: IconButton(
                    onPressed: _codes.isEmpty
                        ? null
                        : () async {
                            final id = _idController.text.trim();
                            if (id.isEmpty) return;
                            final String? outputFile =
                                await FilePicker.platform.saveFile(
                              dialogTitle: 'Save Codes',
                              fileName: '$id.txt',
                              allowedExtensions: ['txt', 'gct'],
                              type: FileType.custom,
                            );
                            if (outputFile != null) {
                              final file = File(outputFile);
                              await file.writeAsString(_codes);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Saved to $outputFile'),
                                    backgroundColor: const Color(0xFF00C2FF),
                                  ),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    color: const Color(0xFF00C2FF),
                    disabledColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _status,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF20202A), // FusionColors.bgSurface
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: _buildCodesBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodesBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C2FF)),
      );
    }
    if (_codes.isEmpty) {
      return Center(child: _buildEmptyStateColumn());
    }
    return SingleChildScrollView(
      child: SelectableText(
        _codes,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyStateColumn() {
    final hasId = _idController.text.isNotEmpty;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.code_off,
            size: 64, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text(
          _idController.text.isEmpty
              ? 'Enter a Game ID to search'
              : 'No codes found for "${_idController.text}"',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (hasId) ...[
          Text(
            'Checked: RiiConnect24, GeckoCodes, GameHacking',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          SelectableText(
            'Try searching online for "Gecko Codes ${_idController.text}"',
            style: const TextStyle(color: Color(0xFF00C2FF)),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'Example: RMCE01 (Mario Kart Wii)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedInWrapper) return _buildContent();
    return Container(
      decoration:
          const BoxDecoration(color: Color(0xFF000000)), // FusionColors.void_
      child: ImmersiveAppShell(
        title: 'CHEAT CODES',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        child: _buildContent(),
      ),
    );
  }
}
