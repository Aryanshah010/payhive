import 'package:flutter/material.dart';
import 'package:payhive/core/utils/responsive_layout.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const String _supportPhone = '+977-98XXXXXXXX';
  static const String _supportEmail = 'support@payhive.com';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = ResponsiveLayout.isTablet(context);
    final double scale = isTablet ? 1.2 : 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveLayout.constrainedContent(
            context,
            child: Padding(
              padding: ResponsiveLayout.pagePadding(
                context,
                top: 16,
                bottom: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Need help?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 28 * scale,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    'Find answers quickly or reach out to us directly.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 15 * scale,
                    ),
                  ),
                  SizedBox(height: 20 * scale),
                  _sectionTitle(context, 'FAQs', scale),
                  SizedBox(height: 10 * scale),
                  _buildFaqCard(context),
                  SizedBox(height: 20 * scale),
                  _sectionTitle(context, 'Contact Us', scale),
                  SizedBox(height: 10 * scale),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.phone_outlined, size: 22 * scale),
                          title: Text(
                            _supportPhone,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 17 * scale,
                            ),
                          ),
                          subtitle: Text(
                            'Call us',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14 * scale,
                            ),
                          ),
                          onTap: () => _launchUri('tel:$_supportPhone'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.email_outlined, size: 22 * scale),
                          title: Text(
                            _supportEmail,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 17 * scale,
                            ),
                          ),
                          subtitle: Text(
                            'Email support',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14 * scale,
                            ),
                          ),
                          onTap: () => _launchUri('mailto:$_supportEmail'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12 * scale),
                  Text(
                    'Support hours: 10:00 AM - 6:00 PM (Sun-Fri)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 13 * scale,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, double scale) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 18 * scale,
      ),
    );
  }

  Widget _buildFaqCard(BuildContext context) {
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
    final isTablet = ResponsiveLayout.isTablet(context);
    final scale = isTablet ? 1.15 : 1.0;

    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15 * scale,
        ),
      ),
      tilePadding: EdgeInsets.symmetric(horizontal: 16 * scale),
      childrenPadding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 12),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 13 * scale,
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
