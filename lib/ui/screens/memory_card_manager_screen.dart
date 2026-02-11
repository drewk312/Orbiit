import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../services/memory_card_service.dart';
import '../../ui/fusion/design_system.dart';
import '../../widgets/immersive_glass_header.dart';

class MemoryCardManagerScreen extends StatefulWidget {
  const MemoryCardManagerScreen({super.key});

  @override
  State<MemoryCardManagerScreen> createState() =>
      _MemoryCardManagerScreenState();
}

class _MemoryCardManagerScreenState extends State<MemoryCardManagerScreen> {
  final MemoryCardService _service = MemoryCardService();

  List<File> _cards = [];
  bool _loading = false;
  Directory? _libraryRoot;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _loading = true);

    // In a real flow, you'd get this from settings/provider.
    // For now, let's look in typical path or ask.
    // Assuming we don't have global active library path in this scope easily,
    // we might check a default or ask.

    // For specific task, let's stub or use FilePicker if not set.
    if (_libraryRoot == null) {
      // We'll scan a dummy path or ask user on first interaction if empty?
      // Let's just finish loading as empty initially.
      setState(() => _loading = false);
      return;
    }

    try {
      final cards = await _service.scanForMemoryCards(_libraryRoot!);
      if (mounted) setState(() => _cards = cards);
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickLibrary() async {
    final result = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Select Game Library Root');
    if (result != null) {
      setState(() => _libraryRoot = Directory(result));
      _loadCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          ImmersiveGlassHeader(
            title: 'Memory Card Manager',
            subtitle: 'Manage GameCube Saves (.raw/.gcp)',
            leading: const Icon(Icons.sd_storage_rounded,
                color: FusionColors.nebulaViolet),
            actions: [
              IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _pickLibrary,
                  tooltip: 'Identify Library Root'),
              IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _libraryRoot == null ? null : _showCreateDialog,
                  tooltip: 'New Card'),
            ],
          ),
          if (_libraryRoot == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_off,
                        size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                        'Select your Game Library folder to scan for saves.',
                        style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _pickLibrary,
                        child: const Text('Select Folder')),
                  ],
                ),
              ),
            )
          else if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_cards.isEmpty)
            const Expanded(
                child: Center(
                    child: Text('No memory cards found in /saves.',
                        style: TextStyle(color: Colors.white54))))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  final sizeMb =
                      (card.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
                  return Card(
                    color: FusionColors.surfaceCard,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.save,
                          color: FusionColors.nebulaViolet),
                      title: Text(path.basename(card.path),
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text('$sizeMb MB',
                          style: const TextStyle(color: Colors.white54)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.backup,
                                color: FusionColors.nebulaCyan),
                            onPressed: () => _backupCard(card),
                            tooltip: 'Backup',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () => _deleteCard(card),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _backupCard(File card) async {
    try {
      await _service.backupCard(card);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Backup created!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteCard(File card) async {
    // Confirm dialog...
    await card.delete();
    _loadCards();
  }

  void _showCreateDialog() {
    showDialog(
        context: context,
        builder: (_) => _CreateCardDialog(onCreate: (name, size) async {
              try {
                await _service.createBlankCard(_libraryRoot!, name, size);
                Navigator.pop(context);
                _loadCards();
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }));
  }
}

class _CreateCardDialog extends StatefulWidget {
  final Function(String, int) onCreate;
  const _CreateCardDialog({required this.onCreate});

  @override
  State<_CreateCardDialog> createState() => _CreateCardDialogState();
}

class _CreateCardDialogState extends State<_CreateCardDialog> {
  final _nameController = TextEditingController(text: 'ninmem.raw');
  int _selectedSize = MemoryCardService.size2043; // Default 16MB (2043 blocks)

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FusionColors.bgSurface,
      title: const Text('Create Memory Card',
          style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: 'Filename',
                labelStyle: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(height: 16),
          DropdownButton<int>(
            value: _selectedSize,
            dropdownColor: FusionColors.bgSurface,
            style: const TextStyle(color: Colors.white),
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                  value: MemoryCardService.size59,
                  child: Text('59 Blocks (512KB)')),
              DropdownMenuItem(
                  value: MemoryCardService.size123,
                  child: Text('123 Blocks (1MB)')),
              DropdownMenuItem(
                  value: MemoryCardService.size251,
                  child: Text('251 Blocks (2MB)')),
              DropdownMenuItem(
                  value: MemoryCardService.size507,
                  child: Text('507 Blocks (4MB)')),
              DropdownMenuItem(
                  value: MemoryCardService.size1019,
                  child: Text('1019 Blocks (8MB)')),
              DropdownMenuItem(
                  value: MemoryCardService.size2043,
                  child: Text('2043 Blocks (16MB)')),
            ],
            onChanged: (val) => setState(() => _selectedSize = val!),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => widget.onCreate(_nameController.text, _selectedSize),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
