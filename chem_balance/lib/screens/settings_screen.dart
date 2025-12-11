import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/equation_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Information
          _buildSectionHeader(context, 'About'),
          _buildInfoCard(context),

          const SizedBox(height: 24),

          // Appearance
          // _buildSectionHeader(context, 'Appearance'),
          // _buildThemeCard(context),

          const SizedBox(height: 24),

          // Data Management
          _buildSectionHeader(context, 'Data'),
          _buildDataCard(context),

          const SizedBox(height: 24),

          // Developer Info
          _buildSectionHeader(context, 'Developer'),
          _buildDeveloperCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.science,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ChemBalance',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chemical Equation Computation and Balancing Application',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Light Mode'),
                trailing: Radio<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.light);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.dark_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Dark Mode'),
                trailing: Radio<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.dark);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.brightness_auto,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('System Default'),
                trailing: Radio<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.system);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Consumer<EquationProvider>(
            builder: (context, provider, child) {
              return ListTile(
                leading: Icon(
                  Icons.storage,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Database Status'),
                subtitle: Text('${provider.elements.length} elements loaded'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All History'),
            subtitle: const Text('Remove all saved equations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showClearDataDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    'JW',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'James Onasa Wisdom',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Cos/7494/2020',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.school, 'Department of Computer Science'),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_city,
              'Federal University of Petroleum Resources',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'Supervisor: Dr. Max-Egba A. T.'),
            const SizedBox(height: 16),
            const Text(
              'Final Year Project - 2025',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All History'),
          content: const Text(
            'This will permanently delete all saved equations from history. This action cannot be undone.\n\nAre you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<EquationProvider>().clearHistory();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All history has been cleared'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}
