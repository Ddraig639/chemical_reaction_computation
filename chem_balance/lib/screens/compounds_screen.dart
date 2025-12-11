import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equation_provider.dart';
import '../models/compound.dart';

class CompoundsScreen extends StatefulWidget {
  const CompoundsScreen({super.key});

  @override
  State<CompoundsScreen> createState() => _CompoundsScreenState();
}

class _CompoundsScreenState extends State<CompoundsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Acid',
    'Base',
    'Salt',
    'Oxide',
    'Organic',
  ];

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Acid':
        return const Color(0xFFFF6B6B);
      case 'Base':
        return const Color(0xFF4D96FF);
      case 'Salt':
        return const Color(0xFF6BCB77);
      case 'Oxide':
        return const Color(0xFFF49D1A);
      case 'Organic':
        return const Color(0xFF9D84B7);
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon(String state) {
    switch (state.toLowerCase()) {
      case 'solid':
        return Icons.square;
      case 'liquid':
        return Icons.water_drop;
      case 'gas':
        return Icons.cloud;
      case 'aqueous':
        return Icons.waves;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Common Compounds'),
        elevation: 0,
      ),
      body: Consumer<EquationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredCompounds = provider.compounds.where((compound) {
            final matchesSearch = _searchQuery.isEmpty ||
                compound.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                compound.formula
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (compound.commonName
                        ?.toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ??
                    false);

            final matchesCategory = _selectedCategory == 'All' ||
                compound.category == _selectedCategory;

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
                    hintText: 'Search compounds (e.g., "salt", "H2O")...',
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

              // Compounds List
              Expanded(
                child: filteredCompounds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.science_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No compounds found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredCompounds.length,
                        itemBuilder: (context, index) {
                          final compound = filteredCompounds[index];
                          return _buildCompoundCard(compound);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompoundCard(Compound compound) {
    final categoryColor = _getCategoryColor(compound.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showCompoundDetails(compound),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Formula Circle
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      categoryColor.withOpacity(0.8),
                      categoryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    compound.formula,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Compound Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      compound.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (compound.commonName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        compound.commonName!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            compound.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: categoryColor.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _getStateIcon(compound.state),
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          compound.state,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompoundDetails(Compound compound) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final categoryColor = _getCategoryColor(compound.category);

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
                        // Compound Header
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
                          child: Column(
                            children: [
                              Text(
                                compound.formula,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                compound.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (compound.commonName != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  compound.commonName!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Properties
                        _buildPropertyRow('Category', compound.category),
                        _buildPropertyRow('State', compound.state),
                        _buildPropertyRow(
                          'Molar Mass',
                          '${compound.molarMass.toStringAsFixed(2)} g/mol',
                        ),

                        const SizedBox(height: 16),

                        // Description
                        if (compound.description != null) ...[
                          Text(
                            'Description',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            compound.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Uses
                        if (compound.uses != null) ...[
                          Text(
                            'Common Uses',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            compound.uses!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Add to Equation Button
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<EquationProvider>().addToEquation(
                                  compound.formula,
                                );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${compound.formula} added to equation',
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
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
