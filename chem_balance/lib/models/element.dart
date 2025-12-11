class Element {
  final int? id;
  final String symbol;
  final String name;
  final int atomicNumber;
  final double atomicMass;
  final String category;
  final int? groupNumber;
  final int? periodNumber;
  final String? oxidationStates;
  final String? description;

  Element({
    this.id,
    required this.symbol,
    required this.name,
    required this.atomicNumber,
    required this.atomicMass,
    required this.category,
    this.groupNumber,
    this.periodNumber,
    this.oxidationStates,
    this.description,
  });

  factory Element.fromJson(Map<String, dynamic> json) {
    return Element(
      id: json['id'] as int?,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      atomicNumber: json['atomic_number'] as int,
      atomicMass: (json['atomic_mass'] as num).toDouble(),
      category: json['category'] as String,
      groupNumber: json['group_number'] as int?,
      periodNumber: json['period_number'] as int?,
      oxidationStates: json['oxidation_states'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'atomic_number': atomicNumber,
      'atomic_mass': atomicMass,
      'category': category,
      'group_number': groupNumber,
      'period_number': periodNumber,
      'oxidation_states': oxidationStates,
      'description': description,
    };
  }

  String getCategoryColor() {
    switch (category) {
      case 'Alkali Metal':
        return '#FF6B6B';
      case 'Alkaline Earth':
        return '#FFD93D';
      case 'Transition Metal':
        return '#6BCB77';
      case 'Post-transition Metal':
        return '#4D96FF';
      case 'Metalloid':
        return '#9D84B7';
      case 'Nonmetal':
        return '#F49D1A';
      case 'Halogen':
        return '#FF6B9D';
      case 'Noble Gas':
        return '#C780FA';
      default:
        return '#A0A0A0';
    }
  }
}
