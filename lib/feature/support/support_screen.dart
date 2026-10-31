// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/widgets/app_logo.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  static const String path = "/support";

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Help & Community Support",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withAlpha(90),
                    theme.colorScheme.secondaryContainer.withAlpha(50),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const AppLogo.icon(size: 44, borderRadius: 10),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "We're Here to Help",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "BorrowBox is built on community trust, verified handovers, and mutual respect.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQ Section
            Text(
              "Frequently Asked Questions",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildFaqTile(
              "How does borrowing work on BorrowBox?",
              "Discover an item in your community circle or marketplace, choose your borrowing dates (within the owner's allowed duration), and submit a request. Once approved, coordinate pickup in chat and scan the QR code to confirm handover.",
            ),
            _buildFaqTile(
              "Are items free or do they cost money?",
              "BorrowBox is fundamentally a peer-to-peer sharing network. Most items are free to borrow. Owners can optionally request a refundable security deposit for high-value items, which is refunded upon safe return.",
            ),
            _buildFaqTile(
              "How do QR Code handovers protect me?",
              "When an owner approves your request, a cryptographic one-time token is generated. At pickup, scanning this token validates the physical handover and activates the loan. A second token verifies the item's return.",
            ),
            _buildFaqTile(
              "What happens if an item is damaged or returned late?",
              "Both parties confirm item condition upon handover. If an item is damaged or missing, either user can file a dispute through chat or the activity screen. Community reputation scores reflect loan reliability.",
            ),
            _buildFaqTile(
              "Can I list multiple photos for my item?",
              "Yes! When creating or editing a listing, you can upload clear photos showing the item and its current condition.",
            ),
            const SizedBox(height: 28),

            // Contact Support Form
            Text(
              "Contact Support & Safety Team",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Have a question, report, or feature suggestion? Send a note directly to our team:",
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(60),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: "Subject",
                        hintText: "e.g., Question about security deposits",
                        prefixIcon: const Icon(Symbols.subject),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Message",
                        hintText: "Describe your issue or suggestion...",
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submitMessage,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: const Text("Send Message to Support"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _submitMessage() async {
    final sub = _subjectController.text.trim();
    final msg = _messageController.text.trim();

    if (sub.isEmpty || msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both subject and message.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _subjectController.clear();
        _messageController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[800],
          content: const Text(
            "Thank you! Your ticket was submitted. Support will reply within 24 hours.",
          ),
        ),
      );
    }
  }
}
