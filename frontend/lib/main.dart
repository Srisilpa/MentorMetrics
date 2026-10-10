
import 'package:flutter/material.dart';

void main() {
  runApp(const MentorMetricsApp());
}

class MentorMetricsApp extends StatelessWidget {
  const MentorMetricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MentorMetrics',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MentorMetrics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Welcome to MentorMetrics!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your voice helps improve teaching quality.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            FeatureCard(
              icon: Icons.rate_review_outlined,
              title: 'Submit Feedback',
              subtitle: 'Share your feedback about faculty.',
              onTap: () {},
            ),
            FeatureCard(
              icon: Icons.analytics_outlined,
              title: 'Feedback Analytics',
              subtitle: 'View teaching insights and trends.',
              onTap: () {},
            ),
            FeatureCard(
              icon: Icons.person_outline,
              title: 'Faculty Information',
              subtitle: 'Explore faculty and subjects.',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
