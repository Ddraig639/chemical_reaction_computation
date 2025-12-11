import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equation_provider.dart';
import '../models/element.dart' as chem;

class PeriodicTableScreen extends StatefulWidget {
  const PeriodicTableScreen({super.key});

  @override
  State<PeriodicTableScreen> createState() => _PeriodicTableScreenState();
}

class _PeriodicTableScreenState extends State<PeriodicTableScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Alkali Metal',
    'Alkaline Earth',
    'Transition Metal',
    'Post-transition Metal',
    'Metalloid',
    'Nonmetal',
    'Halogen',
    'Noble Gas',
  ];

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Alkali Metal':
        return const Color(0xFFFF6B6B);
      case 'Alkaline Earth':
        return const Color(0xFFFFD93D);
      case 'Transition Metal':
        return const Color(0xFF6BCB77);
      case 'Post-transition Metal':
        return const Color(0xFF4D96FF);
      case 'Metalloid':
        return const Color(0xFF9D84B7);
      case 'Nonmetal':
        return const Color(0xFFF49D1A);
      case 'Halogen':
        return const Color(0xFFFF6B9D);
      case 'Noble Gas':
        return const Color(0xFFC780FA);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Periodic Table'), elevation: 0),
      body: Consumer<EquationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredElements = provider.elements.where((element) {
            final matchesSearch = _searchQuery.isEmpty ||
                element.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                element.symbol.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );

            final matchesCategory = _selectedCategory == 'All' ||
                element.category == _selectedCategory;

            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search elements...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                ),
              ),

              // Category Filter
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: category == 'All'
                            ? null
                            : _getCategoryColor(category).withOpacity(0.2),
                        selectedColor: category == 'All'
                            ? Theme.of(context).colorScheme.primaryContainer
                            : _getCategoryColor(category).withOpacity(0.5),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Elements Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredElements.length,
                  itemBuilder: (context, index) {
                    final element = filteredElements[index];
                    return _buildElementCard(element);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildElementCard(chem.Element element) {
    final categoryColor = _getCategoryColor(element.category);

    return InkWell(
      onTap: () => _showElementDetails(element),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [categoryColor.withOpacity(0.8), categoryColor],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    element.symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${element.atomicNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    element.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${element.atomicMass.toStringAsFixed(2)} u',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showElementDetails(chem.Element element) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final categoryColor = _getCategoryColor(element.category);

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Element Header
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                categoryColor.withOpacity(0.8),
                                categoryColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Text(
                                element.symbol,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      element.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      element.category,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Properties
                        _buildPropertyRow(
                          'Atomic Number',
                          '${element.atomicNumber}',
                        ),
                        _buildPropertyRow(
                          'Atomic Mass',
                          '${element.atomicMass.toStringAsFixed(3)} u',
                        ),
                        if (element.groupNumber != null)
                          _buildPropertyRow('Group', '${element.groupNumber}'),
                        if (element.periodNumber != null)
                          _buildPropertyRow(
                            'Period',
                            '${element.periodNumber}',
                          ),
                        if (element.oxidationStates != null)
                          _buildPropertyRow(
                            'Oxidation States',
                            element.oxidationStates!,
                          ),

                        const SizedBox(height: 16),

                        // Description
                        if (element.description != null) ...[
                          Text(
                            'Description',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            element.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Add to Equation Button
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<EquationProvider>().addToEquation(
                                  element.symbol,
                                );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${element.symbol} added to equation',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add to Equation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: categoryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
