import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Help and Support sub-page opened from the Profile menu.
///
/// The answers describe what the app actually does. Where a capability is not
/// built, the answer says so instead of walking people toward a flow that does
/// not exist. "Contact support" and "Report a problem" are informational only:
/// there is no support or reporting channel, so they carry no tap target and
/// no chevron rather than implying somewhere to go.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _FaqItem {
  final String question;
  final String answer;
  bool expanded;
  _FaqItem(this.question, this.answer, {this.expanded = false});
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // TODO: replace with FAQ content fetched from your backend or a CMS.
  final List<_FaqItem> _faqs = [
    _FaqItem('How do I reset my password?',
        'There is no self-service password reset yet. Nothing under Settings can change your password, and no reset link is sent to your email, so please keep the password you signed up with.'),
    _FaqItem('How do I make my account private?',
        'Private accounts are not supported yet. The switch under Privacy is not saved, so it does not hide your posts from anyone, and there are no follower controls to limit who can see them.'),
    _FaqItem('How do I delete a post?',
        'Open the post from your "My posts" tab, tap the menu icon on the post, then choose Delete.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: buildSimpleAppBar(context, 'Help and Support'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Frequently asked questions',
              style: TextStyle(fontSize: 12, color: context.textSecondaryColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            decoration: cardDecoration(context),
            child: Column(
              children: List.generate(_faqs.length, (i) {
                final faq = _faqs[i];
                return Column(
                  children: [
                    if (i != 0) Divider(height: 1, color: context.borderColor, indent: 14, endIndent: 14),
                    InkWell(
                      onTap: () => setState(() => faq.expanded = !faq.expanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(faq.question,
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: context.textPrimaryColor)),
                                ),
                                Icon(faq.expanded ? Icons.expand_less : Icons.expand_more,
                                    color: context.textSecondaryColor),
                              ],
                            ),
                            if (faq.expanded) ...[
                              const SizedBox(height: 8),
                              Text(faq.answer,
                                  style: TextStyle(fontSize: 12.5, color: context.textSecondaryColor, height: 1.4)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Text('Still need help?',
              style: TextStyle(fontSize: 12, color: context.textSecondaryColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            decoration: cardDecoration(context),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryPurple),
                  title: Text('Contact support',
                      style: TextStyle(fontSize: 13.5, color: context.textPrimaryColor)),
                  subtitle: Text('No support channel is set up yet.',
                      style: TextStyle(fontSize: 11.5, color: context.textSecondaryColor)),
                ),
                Divider(height: 1, color: context.borderColor, indent: 14, endIndent: 14),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined, color: AppColors.primaryPurple),
                  title: Text('Report a problem',
                      style: TextStyle(fontSize: 13.5, color: context.textPrimaryColor)),
                  subtitle: Text('There is nowhere to send a report yet.',
                      style: TextStyle(fontSize: 11.5, color: context.textSecondaryColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}