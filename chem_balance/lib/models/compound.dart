class Compound {
  final int? id;
  final String formula;
  final String name;
  final String? commonName;
  final double molarMass;
  final String category;
  final String state;
  final String? description;
  final String? uses;

  Compound({
    this.id,
    required this.formula,
    required this.name,
    this.commonName,
    required this.molarMass,
    required this.category,
    required this.state,
    this.description,
    this.uses,
  });

  factory Compound.fromJson(Map<String, dynamic> json) {
    return Compound(
      id: json['id'] as int?,
      formula: json['formula'] as String,
      name: json['name'] as String,
      commonName: json['common_name'] as String?,
      molarMass: (json['molar_mass'] as num).toDouble(),
      category: json['category'] as String,
      state: json['state'] as String,
      description: json['description'] as String?,
      uses: json['uses'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'formula': formula,
      'name': name,
      'common_name': commonName,
      'molar_mass': molarMass,
      'category': category,
      'state': state,
      'description': description,
      'uses': uses,
    };
  }
}
