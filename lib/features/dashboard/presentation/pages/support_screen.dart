import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const String _supportPhone = '+977-98XXXXXXXX';
  static const String _supportEmail = 'support@payhive.com';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final double scale = isTablet ? 1.2 : 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Need help?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Find answers quickly or reach out to us directly.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'FAQs'),
              const SizedBox(height: 10),
              _buildFaqCard(context, scale),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Contact Us'),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: Text(_supportPhone),
                      subtitle: const Text('Call us'),
                      onTap: () => _launchUri('tel:$_supportPhone'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: Text(_supportEmail),
                      subtitle: const Text('Email support'),
                      onTap: () => _launchUri('mailto:$_supportEmail'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Support hours: 10:00 AM - 6:00 PM (Sun-Fri)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildFaqCard(BuildContext context, double scale) {
    return Card(
      child: Column(
        children: [
          _faqItem(
            context,
            'How do I add money to my wallet?',
            'Use Bank Transfer or receive money from another Payhive user.',
          ),
          _faqDivider(),
          _faqItem(
            context,
            'How long do bank transfers take?',
            'Most transfers complete within a few minutes, but can take longer depending on the bank.',
          ),
          _faqDivider(),
          _faqItem(
            context,
            'What if my payment fails?',
            'Check your balance and try again. If the issue persists, contact support.',
          ),
          _faqDivider(),
          _faqItem(
            context,
            'Is there a service fee for recharge or booking?',
            'A small service fee may apply depending on the service.',
          ),
          _faqDivider(),
          _faqItem(
            context,
            'How do I reset my PIN or password?',
            'You can update your PIN from Profile > PIN, and reset password from the login screen.',
          ),
          _faqDivider(),
          _faqItem(
            context,
            'How do I contact support?',
            'Use the phone number or email listed below.',
          ),
        ],
      ),
    );
  }

  Widget _faqItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _faqDivider() {
    return const Divider(height: 1);
  }

  Future<void> _launchUri(String uri) async {
    final parsed = Uri.parse(uri);
    await launchUrl(parsed, mode: LaunchMode.externalApplication);
  }
}
