import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LegalDisclaimerDialog extends StatefulWidget {
  const LegalDisclaimerDialog({super.key});

  @override
  State<LegalDisclaimerDialog> createState() => _LegalDisclaimerDialogState();
}

class _LegalDisclaimerDialogState extends State<LegalDisclaimerDialog> {
  bool _hasScrolledToBottom = false;
  bool _acceptedTerms = false;
  bool _dontShowAgain = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  int _secondsRemaining = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);

    // Start countdown timer - must wait 10 seconds before accepting
    _scrollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _checkScrollPosition() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 20) {
      if (!_hasScrolledToBottom) {
        setState(() => _hasScrolledToBottom = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('legal_disclaimer_accepted', true);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final canAccept = _hasScrolledToBottom && _secondsRemaining == 0;

    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.gavel, color: Colors.amber[700], size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Legal Disclaimer & Fair Use Notice',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Please read carefully before proceeding',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            // Scrollable content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                padding: const EdgeInsets.all(16),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: SelectableText(
                      _disclaimerText,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[300],
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scroll instruction
            if (!_hasScrolledToBottom || _secondsRemaining > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[900]?.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[700]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.amber[400], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        !_hasScrolledToBottom
                            ? 'Please scroll to the bottom to continue'
                            : 'Please wait $_secondsRemaining second${_secondsRemaining != 1 ? 's' : ''} to continue',
                        style: TextStyle(
                          color: Colors.amber[100],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Checkboxes
            CheckboxListTile(
              value: _acceptedTerms,
              enabled: canAccept,
              onChanged: canAccept
                  ? (val) => setState(() => _acceptedTerms = val ?? false)
                  : null,
              title: Text(
                'I have read and understand this disclaimer',
                style: TextStyle(
                  color: canAccept ? Colors.white : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              activeColor: Colors.blue,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            CheckboxListTile(
              value: _dontShowAgain,
              enabled: canAccept,
              onChanged: canAccept
                  ? (val) => setState(() => _dontShowAgain = val ?? false)
                  : null,
              title: Text(
                'Don\'t show this again',
                style: TextStyle(
                  color: canAccept ? Colors.white : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              activeColor: Colors.blue,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed:
                      (_acceptedTerms && canAccept) ? _handleAccept : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'I Agree & Continue',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const String _disclaimerText = '''
LEGAL DISCLAIMER & FAIR USE NOTICE

IMPORTANT: READ CAREFULLY BEFORE USING THIS SOFTWARE

1. NO WARRANTY & LIMITATION OF LIABILITY
This software is provided "AS IS" without warranty of any kind, either express or implied, including but not limited to warranties of merchantability, fitness for a particular purpose, or non-infringement. The developers, contributors, and distributors of this software shall not be held liable for any damages, claims, or losses arising from the use or inability to use this software.

2. USER RESPONSIBILITY
By using this software, you acknowledge and agree that:
• You are solely responsible for your use of this software and any content you access
• You must comply with all applicable local, state, national, and international laws
• You assume all risks associated with the use of this software
• The developers are not responsible for how you choose to use this software

3. COPYRIGHT & FAIR USE
This software is designed for lawful purposes only, including:
• Backing up legally owned physical media
• Preservation of personal gaming collections
• Educational and research purposes
• Fair use under applicable copyright law (17 U.S.C. § 107)

4. INTELLECTUAL PROPERTY DISCLAIMER
• This software does NOT contain any copyrighted Nintendo content, code, or assets
• This software does NOT bypass, circumvent, or violate any copy protection mechanisms
• This software merely facilitates file organization and management
• All game titles, logos, and trademarks are property of their respective owners
• Nintendo® and all related marks are trademarks of Nintendo Co., Ltd.

5. DIGITAL MILLENNIUM COPYRIGHT ACT (DMCA)
This software complies with the DMCA and similar international laws:
• It does not contain or distribute copyrighted material
• It does not provide tools to circumvent DRM or copy protection
• It is designed for interoperability and archival purposes
• Users are responsible for ensuring they own legal copies of any content

6. NO AFFILIATION
This software is an independent project and is NOT:
• Affiliated with, endorsed by, or sponsored by Nintendo
• An official Nintendo product or service
• Authorized or approved by any game publisher or developer

7. CONTENT SOURCES
Any content accessed through this software comes from third-party sources. The developers:
• Do NOT host, store, or distribute copyrighted content
• Do NOT control or monitor third-party sources
• Are NOT responsible for the content, accuracy, or legality of external sources
• Make no representations about the legitimacy of any content

8. PRIVACY & DATA COLLECTION
This software:
• Does NOT collect, store, or transmit your personal information
• Does NOT track your usage or downloads
• Does NOT share data with third parties
• Operates entirely on your local device

9. AGE RESTRICTION
You must be 18 years of age or older, or have parental consent, to use this software.

10. INDEMNIFICATION
You agree to indemnify, defend, and hold harmless the developers, contributors, and distributors from any claims, damages, losses, liabilities, and expenses (including legal fees) arising from your use of this software or violation of these terms.

11. SEVERABILITY
If any provision of this disclaimer is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary so that this disclaimer shall otherwise remain in full force and effect.

12. GOVERNING LAW
This disclaimer shall be governed by and construed in accordance with applicable law, without regard to conflict of law principles.

13. CHANGES TO DISCLAIMER
This disclaimer may be updated at any time. Continued use of the software constitutes acceptance of any changes.

14. NO DISTRIBUTION OF PIRATED CONTENT
This software is strictly for personal use with legally obtained content. Distribution, sharing, or downloading of pirated content is illegal and prohibited.

BY CLICKING "I AGREE & CONTINUE" BELOW, YOU ACKNOWLEDGE THAT:
✓ You have read and understood this entire disclaimer
✓ You agree to be bound by all terms and conditions
✓ You will use this software only for lawful purposes
✓ You own legal copies of any content you access
✓ You accept all risks and responsibilities
✓ You will not hold the developers liable for your actions

IF YOU DO NOT AGREE, CLICK "CANCEL" AND DO NOT USE THIS SOFTWARE.

Last Updated: January 26, 2026
Version: 1.0''';
}

/// Check if user has accepted the legal disclaimer
Future<bool> hasAcceptedLegalDisclaimer() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('legal_disclaimer_accepted') ?? false;
}

/// Show legal disclaimer dialog and return whether user accepted
Future<bool> showLegalDisclaimerDialog(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const LegalDisclaimerDialog(),
  );
  return accepted ?? false;
}
