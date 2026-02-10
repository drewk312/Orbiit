import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Legal Notice Service - Manages disclaimer acceptance for Discovery feature
/// Enhanced legal protection with professional disclaimer language
class LegalNoticeService {
  static const String _acceptedKey = 'legal_notice_accepted';
  static const String _acceptedDateKey = 'legal_notice_accepted_date';
  static const String _rememberChoiceKey = 'legal_notice_remember_choice';

  static bool _hasAccepted = false;
  static DateTime? _acceptedDate;
  static bool _rememberChoice = false;

  /// Check if user has already accepted the legal notice with remember choice
  static Future<bool> hasAccepted() async {
    if (_hasAccepted && _rememberChoice) return true;

    final prefs = await SharedPreferences.getInstance();
    _hasAccepted = prefs.getBool(_acceptedKey) ?? false;
    _rememberChoice = prefs.getBool(_rememberChoiceKey) ?? false;

    final dateStr = prefs.getString(_acceptedDateKey);
    if (dateStr != null) {
      _acceptedDate = DateTime.tryParse(dateStr);
    }

    // Only skip dialog if both accepted AND remember choice is checked
    return _hasAccepted && _rememberChoice;
  }

  /// Mark the legal notice as accepted
  static Future<void> setAccepted(bool remember) async {
    final prefs = await SharedPreferences.getInstance();

    // Always mark as accepted for this session
    _hasAccepted = true;
    _rememberChoice = remember;
    _acceptedDate = DateTime.now();

    // Only persist if remember choice is checked
    if (remember) {
      await prefs.setBool(_acceptedKey, true);
      await prefs.setBool(_rememberChoiceKey, true);
      await prefs.setString(_acceptedDateKey, DateTime.now().toIso8601String());
    }
  }

  /// Reset acceptance (for testing or if user wants to see it again)
  static Future<void> resetAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_acceptedKey);
    await prefs.remove(_acceptedDateKey);
    await prefs.remove(_rememberChoiceKey);
    _hasAccepted = false;
    _rememberChoice = false;
    _acceptedDate = null;
  }

  /// Show the legal notice dialog
  /// Returns true if user accepted, false if they declined
  static Future<bool> showLegalNotice(BuildContext context) async {
    // Check if already accepted with remember choice
    if (await hasAccepted()) {
      return true;
    }

    bool rememberChoice = false;
    bool hasScrolledToBottom = false;
    final scrollController = ScrollController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Listen to scroll position
          scrollController.addListener(() {
            if (!hasScrolledToBottom) {
              final maxScroll = scrollController.position.maxScrollExtent;
              final currentScroll = scrollController.position.pixels;
              // Consider "scrolled to bottom" when within 50 pixels of the end
              if (currentScroll >= maxScroll - 50) {
                setState(() {
                  hasScrolledToBottom = true;
                });
              }
            }
          });

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 540,
              constraints: const BoxConstraints(maxWidth: 540, maxHeight: 650),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D0D1A),
                    Color(0xFF151C28),
                    Color(0xFF0A0E14),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD4AF37).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                const Color(0xFFD4AF37).withValues(alpha: 0.05),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37)
                                    .withValues(alpha: 0.2),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.gavel_rounded,
                            size: 28,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'LEGAL DISCLAIMER',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please read carefully before proceeding',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  Flexible(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Purpose Statement
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Text(
                                  'WiiGC Fusion is a personal game library management tool designed exclusively for organizing and backing up games that users legally own physical or digital copies of.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                    height: 1.45,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Terms Section Header
                              Text(
                                'TERMS OF USE',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Legal Terms - Compact
                              _buildLegalPoint(
                                Icons.person_outline_rounded,
                                'Personal Backup Use Only',
                                'This software is provided solely for creating personal backup copies of games you legally own.',
                                const Color(0xFF00C2FF),
                              ),
                              _buildLegalPoint(
                                Icons.album_outlined,
                                'Proof of Ownership Required',
                                'Users must own legitimate copies of any games managed. Creating copies of games you do not own constitutes copyright infringement.',
                                const Color(0xFF00C2FF),
                              ),
                              _buildLegalPoint(
                                Icons.gavel_outlined,
                                'Copyright Compliance',
                                'Unauthorized reproduction of copyrighted games is illegal under DMCA (17 U.S.C. § 512) and international copyright treaties.',
                                Colors.amber,
                              ),
                              _buildLegalPoint(
                                Icons.block_outlined,
                                'No Distribution or Hosting',
                                'This software does not host or distribute copyrighted content. We maintain no affiliation with any third-party hosting services.',
                                Colors.amber,
                              ),
                              _buildLegalPoint(
                                Icons.public_outlined,
                                'Third-Party Content Sources',
                                'Discovery may search public archives. Users must verify their legal right to access any content found.',
                                const Color(0xFF00C2FF),
                              ),
                              _buildLegalPoint(
                                Icons.account_balance_outlined,
                                'User Responsibility & Liability',
                                'You are solely responsible for compliance with all applicable laws. Developers assume no liability for misuse.',
                                Colors.amber,
                              ),

                              const SizedBox(height: 12),

                              // Legal Agreement Box
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C2FF)
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF00C2FF)
                                        .withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Text(
                                  'By clicking "I Accept", you acknowledge that you have read, understood, and agree to these terms. You confirm that you will only use this software for legitimate personal backup purposes.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ),

                              // Extra padding to ensure scrolling is required
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        // Scroll indicator overlay
                        if (!hasScrolledToBottom)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFF0D0D1A)
                                        .withValues(alpha: 0.95),
                                    const Color(0xFF0D0D1A),
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.keyboard_double_arrow_down_rounded,
                                    color: const Color(0xFFD4AF37)
                                        .withValues(alpha: 0.8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Scroll down to continue',
                                    style: TextStyle(
                                      color: const Color(0xFFD4AF37)
                                          .withValues(alpha: 0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.keyboard_double_arrow_down_rounded,
                                    color: const Color(0xFFD4AF37)
                                        .withValues(alpha: 0.8),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Footer with checkbox and buttons
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Remember Choice Checkbox
                        GestureDetector(
                          onTap: () =>
                              setState(() => rememberChoice = !rememberChoice),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: rememberChoice
                                  ? const Color(0xFF00C2FF)
                                      .withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: rememberChoice
                                    ? const Color(0xFF00C2FF)
                                        .withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: rememberChoice
                                        ? const Color(0xFF00C2FF)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: rememberChoice
                                          ? const Color(0xFF00C2FF)
                                          : Colors.white
                                              .withValues(alpha: 0.25),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: rememberChoice
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Remember my choice',
                                        style: TextStyle(
                                          color: rememberChoice
                                              ? Colors.white
                                              : Colors.white
                                                  .withValues(alpha: 0.65),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Don\'t show this disclaimer again',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.35),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Buttons
                        Row(
                          children: [
                            // Decline button
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(false),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'DECLINE',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Accept button - disabled until scrolled
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: hasScrolledToBottom
                                    ? () async {
                                        await setAccepted(rememberChoice);
                                        if (context.mounted) {
                                          Navigator.of(context).pop(true);
                                        }
                                      }
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: hasScrolledToBottom
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF00C2FF),
                                              Color(0xFF0088CC),
                                            ],
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.grey
                                                  .withValues(alpha: 0.3),
                                              Colors.grey
                                                  .withValues(alpha: 0.2),
                                            ],
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: hasScrolledToBottom
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF00C2FF)
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        hasScrolledToBottom
                                            ? Icons.check_circle_outline
                                            : Icons.lock_outline,
                                        color: hasScrolledToBottom
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.4),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        hasScrolledToBottom
                                            ? 'I ACCEPT'
                                            : 'READ FIRST',
                                        style: TextStyle(
                                          color: hasScrolledToBottom
                                              ? Colors.white
                                              : Colors.white
                                                  .withValues(alpha: 0.4),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return result ?? false;
  }

  static Widget _buildLegalPoint(
      IconData icon, String title, String description, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
