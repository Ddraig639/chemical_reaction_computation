import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equation_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSubscriptInput = false;
  final TextEditingController _subscriptController = TextEditingController();

  final List<List<String>> _commonElements = [
    ['H', 'He', 'Li', 'Be'],
    ['B', 'C', 'N', 'O'],
    ['F', 'Ne', 'Na', 'Mg'],
    ['Al', 'Si', 'P', 'S'],

    // Period 3 & 4
    ['Cl', 'Ar', 'K', 'Ca'],
    ['Sc', 'Ti', 'V', 'Cr'],
    ['Mn', 'Fe', 'Co', 'Ni'],
    ['Cu', 'Zn', 'Ga', 'Ge'],

    // More Period 4
    ['As', 'Se', 'Br', 'Kr'],

    // Period 5
    ['Rb', 'Sr', 'Ag', 'Cd'],
    ['In', 'Sn', 'Sb', 'I'],
    ['Xe', 'Cs', 'Ba', 'W'],

    // Period 6 & 7
    ['Pt', 'Au', 'Hg', 'Pb'],
    ['Ra', 'U', '', ''],
  ];

  @override
  void dispose() {
    _subscriptController.dispose();
    super.dispose();
  }

  void _showSubscriptDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Subscript'),
          content: TextField(
            controller: _subscriptController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g., 2',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _subscriptController.clear();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_subscriptController.text.isNotEmpty) {
                  context
                      .read<EquationProvider>()
                      .addToEquation(_subscriptController.text);
                  Navigator.pop(context);
                  _subscriptController.clear();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormattedEquation(String equation) {
    if (equation.isEmpty) {
      return Text(
        'Enter equation...',
        style: TextStyle(
          fontSize: 24,
          color:
              Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      );
    }

    List<TextSpan> spans = [];
    String current = '';
    bool nextIsCoefficient = true;

    for (int i = 0; i < equation.length; i++) {
      String char = equation[i];

      // 🔹 Check if character is a digit
      if (RegExp(r'\d').hasMatch(char)) {
        // Add any pending text
        if (current.isNotEmpty) {
          spans.add(TextSpan(
            text: current,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ));
          current = '';
        }

        // 🔹 Decide: coefficient or subscript
        bool isCoefficient = nextIsCoefficient;

        if (isCoefficient) {
          // Coefficient — normal size and bold
          spans.add(TextSpan(
            text: char,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ));
          nextIsCoefficient = false;
        } else {
          // Subscript — smaller font
          spans.add(TextSpan(
            text: char,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ));
        }
      } else {
        // 🔹 Reset coefficient flag after +, →, or space
        if (char == '+' || char == '→' || char == ' ' || char == '=') {
          nextIsCoefficient = true;
        } else if (RegExp(r'[A-Z]').hasMatch(char)) {
          // Uppercase letter → part of element name
          nextIsCoefficient = false;
        }

        current += char;
      }
    }

    // Add remaining text
    if (current.isNotEmpty) {
      spans.add(TextSpan(
        text: current,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'monospace',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        children: spans,
      ),
    );
  }

  // Format balanced equation result
  Widget _buildFormattedResult(String equation) {
    List<TextSpan> spans = [];
    String current = '';
    bool nextIsCoefficient = true;

    for (int i = 0; i < equation.length; i++) {
      String char = equation[i];

      // Check if character is a digit
      if (RegExp(r'\d').hasMatch(char)) {
        // Add previous text
        if (current.isNotEmpty) {
          spans.add(TextSpan(
            text: current,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ));
          current = '';
        }

        // Check if this is a coefficient (at start, after +, or after space)
        bool isCoefficient = nextIsCoefficient;

        if (isCoefficient) {
          // This is a coefficient - normal size, bold
          spans.add(TextSpan(
            text: char,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ));
          nextIsCoefficient = false;
        } else {
          // This is a subscript - smaller size
          spans.add(TextSpan(
            text: char,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ));
        }
      } else {
        // Reset coefficient flag after + or →
        if (char == '+' || char == '→' || char == ' ') {
          nextIsCoefficient = true;
        } else if (RegExp(r'[A-Z]').hasMatch(char)) {
          // Uppercase letter means we're in element name
          nextIsCoefficient = false;
        }
        current += char;
      }
    }

    // Add remaining text
    if (current.isNotEmpty) {
      spans.add(TextSpan(
        text: current,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'monospace',
          color: Colors.grey,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildFormatteddisplayResult(String equation) {
    List<TextSpan> spans = [];
    String current = '';
    bool nextIsCoefficient = true;

    for (int i = 0; i < equation.length; i++) {
      String char = equation[i];

      // Check if character is a digit
      if (RegExp(r'\d').hasMatch(char)) {
        // Add previous text
        if (current.isNotEmpty) {
          spans.add(TextSpan(
            text: current,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ));
          current = '';
        }

        // Check if this is a coefficient (at start, after +, or after space)
        bool isCoefficient = nextIsCoefficient;

        if (isCoefficient) {
          // This is a coefficient - normal size, bold
          spans.add(TextSpan(
            text: char,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ));
          nextIsCoefficient = false;
        } else {
          // This is a subscript - smaller size
          spans.add(TextSpan(
            text: char,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ));
        }
      } else {
        // Reset coefficient flag after + or →
        if (char == '+' || char == '→' || char == ' ') {
          nextIsCoefficient = true;
        } else if (RegExp(r'[A-Z]').hasMatch(char)) {
          // Uppercase letter means we're in element name
          nextIsCoefficient = false;
        }
        current += char;
      }
    }

    // Add remaining text
    if (current.isNotEmpty) {
      spans.add(TextSpan(
        text: current,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'monospace',
          color: Theme.of(context).colorScheme.primary,
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<EquationProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                // Display Area
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  color: Colors.white,
                  child: Column(
                    children: [
// Suggestions List
                      // if (provider.suggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        height: 150,
                        child: Stack(
                          children: [
                            ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1),
                              itemCount: provider.suggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = provider.suggestions[index];
                                return ListTile(
                                  dense: true,
                                  title: _buildFormattedResult(
                                      suggestion['balanced']!),
                                  subtitle: Text(
                                    suggestion['type']!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onTap: () {
                                    provider
                                        .setEquation(suggestion['original']!);
                                    provider.balanceEquation();
                                  },
                                );
                              },
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: IgnorePointer(
                                child: Container(
                                  height: 30,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Error Message
                      if (provider.errorMessage != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  provider.errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Balanced Result
                      if (provider.balancedResult == null)
                        Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.only(
                              top: 20, right: 20, left: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                constraints:
                                    const BoxConstraints(minHeight: 50),
                                child: _buildFormattedEquation(
                                    provider.currentEquation),
                              ),
                            ],
                          ),
                        ),

                      if (provider.balancedResult != null)
                        Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.only(
                              top: 20, right: 20, left: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormatteddisplayResult(
                                  '${provider.balancedResult!['reactants']} → ${provider.balancedResult!['products']}'),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Balanced Equation',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      provider.balancedResult!['type'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Alternative Reactions
                              if (provider.balancedResult!['hasAlternatives'] ==
                                  true) ...[
                                const Divider(height: 32),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Alternative Reaction',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildFormattedResult(
                                    provider.balancedResult!['alternatives']),
                              ],
                            ],
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            // Operation Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: _buildOperationButton(
                                    context,
                                    '+',
                                    () => provider.addToEquation('+'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildOperationButton(
                                    context,
                                    '→',
                                    () => provider.addToEquation('->'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildOperationButton(
                                    context,
                                    ' ( ',
                                    () => provider.addToEquation('('),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildOperationButton(
                                    context,
                                    ' )',
                                    () => provider.addToEquation(')'),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildOperationButton(
                                    context,
                                    'Num',
                                    _showSubscriptDialog,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: provider.isLoading
                                        ? null
                                        : provider.balanceEquation,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: provider.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Balance',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildOperationButton(context, '⌫',
                                      () {
                                    provider.clearResultEquation();
                                    provider.deleteLastCharacter();
                                  },
                                      color: Colors.red,
                                      onLongPress: () =>
                                          provider.clearEquation()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // Calculator Interface
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Element Buttons
                        ...List.generate(_commonElements.length, (rowIndex) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: List.generate(
                                  _commonElements[rowIndex].length, (colIndex) {
                                final element =
                                    _commonElements[rowIndex][colIndex];
                                final elementData =
                                    provider.findElement(element);
                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (provider.balancedResult != null) {
                                          provider.clearEquation();
                                        }
                                        provider.addToEquation(element);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            element,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          // if (elementData != null)
                                          //   Text(
                                          //     '${elementData.atomicNumber}',
                                          //     style: const TextStyle(
                                          //       fontSize: 10,
                                          //     ),
                                          //   ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOperationButton(
      BuildContext context, String label, VoidCallback onPressed,
      {Color? color, VoidCallback? onLongPress}) {
    return ElevatedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            color ?? Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: color != null
            ? Colors.white
            : Theme.of(context).colorScheme.onSecondaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
