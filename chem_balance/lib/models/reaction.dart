class Reaction {
  final int? id;
  final String reactants;
  final String products;
  final String balancedEquation;
  final String reactionType;
  final String? description;
  final String? alternativeProducts;

  Reaction({
    this.id,
    required this.reactants,
    required this.products,
    required this.balancedEquation,
    required this.reactionType,
    this.description,
    this.alternativeProducts,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'] as int?,
      reactants: json['reactants'] as String,
      products: json['products'] as String,
      balancedEquation: json['balanced_equation'] as String,
      reactionType: json['reaction_type'] as String,
      description: json['description'] as String?,
      alternativeProducts: json['alternative_products'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reactants': reactants,
      'products': products,
      'balanced_equation': balancedEquation,
      'reaction_type': reactionType,
      'description': description,
      'alternative_products': alternativeProducts,
    };
  }

  bool hasAlternatives() {
    return alternativeProducts != null && alternativeProducts!.isNotEmpty;
  }
}
