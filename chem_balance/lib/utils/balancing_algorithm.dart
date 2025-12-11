import 'dart:math';

class BalancingAlgorithm {
  /// Parse a chemical formula and return a map of elements to their counts
  static Map<String, int> parseFormula(String formula) {
    final Map<String, int> elements = {};
    final RegExp regex = RegExp(r'([A-Z][a-z]?)(\d*)');
    final matches = regex.allMatches(formula);

    for (final match in matches) {
      final element = match.group(1)!;
      final countStr = match.group(2);
      final count = countStr != null && countStr.isNotEmpty
          ? int.parse(countStr)
          : 1;
      elements[element] = (elements[element] ?? 0) + count;
    }

    return elements;
  }

  /// Parse compounds with parentheses like Ca(OH)2
  static Map<String, int> parseComplexFormula(String formula) {
    final Map<String, int> elements = {};

    // Handle parentheses
    final parenthesesRegex = RegExp(r'\(([^)]+)\)(\d*)');
    String processedFormula = formula;

    for (final match in parenthesesRegex.allMatches(formula)) {
      final insideParens = match.group(1)!;
      final multiplierStr = match.group(2);
      final multiplier = multiplierStr != null && multiplierStr.isNotEmpty
          ? int.parse(multiplierStr)
          : 1;

      final insideElements = parseFormula(insideParens);
      for (final entry in insideElements.entries) {
        elements[entry.key] =
            (elements[entry.key] ?? 0) + (entry.value * multiplier);
      }

      processedFormula = processedFormula.replaceFirst(match.group(0)!, '');
    }

    // Parse remaining formula
    final remainingElements = parseFormula(processedFormula);
    for (final entry in remainingElements.entries) {
      elements[entry.key] = (elements[entry.key] ?? 0) + entry.value;
    }

    return elements;
  }

  /// Balance chemical equation using matrix method with GCD simplification
  static Map<String, dynamic>? balanceEquation(
    List<String> reactantCompounds,
    List<String> productCompounds,
  ) {
    // Get all unique elements
    final Set<String> allElements = {};

    for (final compound in [...reactantCompounds, ...productCompounds]) {
      final elements = parseComplexFormula(compound);
      allElements.addAll(elements.keys);
    }

    if (allElements.isEmpty) return null;

    // Try brute force method for simple cases (faster for small equations)
    final bruteForceResult = _bruteForceBalance(
      reactantCompounds,
      productCompounds,
      allElements.toList(),
    );

    if (bruteForceResult != null) {
      return bruteForceResult;
    }

    // Fallback to matrix method for complex cases
    return _matrixBalance(
      reactantCompounds,
      productCompounds,
      allElements.toList(),
    );
  }

  /// Brute force balancing for simple equations
  static Map<String, dynamic>? _bruteForceBalance(
    List<String> reactants,
    List<String> products,
    List<String> elements,
  ) {
    const int maxCoeff = 20;
    final int totalCompounds = reactants.length + products.length;

    // Generate coefficient combinations
    List<int> coeffs = List.filled(totalCompounds, 1);

    bool tryCoefficients(int index) {
      if (index == totalCompounds) {
        // Check if this combination balances
        final Map<String, int> reactantCounts = {};
        final Map<String, int> productCounts = {};

        // Count reactant atoms
        for (int i = 0; i < reactants.length; i++) {
          final elemCounts = parseComplexFormula(reactants[i]);
          for (final entry in elemCounts.entries) {
            reactantCounts[entry.key] =
                (reactantCounts[entry.key] ?? 0) + (entry.value * coeffs[i]);
          }
        }

        // Count product atoms
        for (int i = 0; i < products.length; i++) {
          final elemCounts = parseComplexFormula(products[i]);
          for (final entry in elemCounts.entries) {
            productCounts[entry.key] =
                (productCounts[entry.key] ?? 0) +
                (entry.value * coeffs[reactants.length + i]);
          }
        }

        // Check if balanced
        for (final element in elements) {
          if ((reactantCounts[element] ?? 0) != (productCounts[element] ?? 0)) {
            return false;
          }
        }

        return true;
      }

      // Try different coefficients
      for (int coeff = 1; coeff <= maxCoeff; coeff++) {
        coeffs[index] = coeff;
        if (tryCoefficients(index + 1)) {
          return true;
        }
      }

      return false;
    }

    if (tryCoefficients(0)) {
      // Simplify coefficients by GCD
      final gcd = _findGCD(coeffs);
      if (gcd > 1) {
        coeffs = coeffs.map((c) => c ~/ gcd).toList();
      }

      return _buildResult(reactants, products, coeffs, elements);
    }

    return null;
  }

  /// Matrix-based balancing (Gaussian elimination)
  static Map<String, dynamic>? _matrixBalance(
    List<String> reactants,
    List<String> products,
    List<String> elements,
  ) {
    final int numElements = elements.length;
    final int numCompounds = reactants.length + products.length;

    // Build the matrix
    List<List<double>> matrix = List.generate(
      numElements,
      (_) => List.filled(numCompounds + 1, 0.0),
    );

    // Fill matrix for reactants (positive)
    for (int i = 0; i < reactants.length; i++) {
      final elemCounts = parseComplexFormula(reactants[i]);
      for (int j = 0; j < elements.length; j++) {
        matrix[j][i] = (elemCounts[elements[j]] ?? 0).toDouble();
      }
    }

    // Fill matrix for products (negative)
    for (int i = 0; i < products.length; i++) {
      final elemCounts = parseComplexFormula(products[i]);
      for (int j = 0; j < elements.length; j++) {
        matrix[j][reactants.length + i] = -(elemCounts[elements[j]] ?? 0)
            .toDouble();
      }
    }

    // Try to solve using Gaussian elimination
    // For simplicity, we'll use a basic approach
    // Set last coefficient to 1 and solve for others
    List<int> coeffs = List.filled(numCompounds, 1);

    // This is a simplified solution - in production, you'd use proper matrix solving
    // For now, return null to indicate we couldn't balance it
    return null;
  }

  /// Find GCD of a list of integers
  static int _findGCD(List<int> numbers) {
    if (numbers.isEmpty) return 1;
    return numbers.reduce((a, b) => _gcd(a, b));
  }

  /// Calculate GCD of two numbers
  static int _gcd(int a, int b) {
    while (b != 0) {
      final temp = b;
      b = a % b;
      a = temp;
    }
    return a.abs();
  }

  /// Build result map from coefficients
  static Map<String, dynamic> _buildResult(
    List<String> reactants,
    List<String> products,
    List<int> coeffs,
    List<String> elements,
  ) {
    // Build balanced equation strings
    final List<String> balancedReactants = [];
    for (int i = 0; i < reactants.length; i++) {
      final coeff = coeffs[i];
      balancedReactants.add(coeff > 1 ? '$coeff${reactants[i]}' : reactants[i]);
    }

    final List<String> balancedProducts = [];
    for (int i = 0; i < products.length; i++) {
      final coeff = coeffs[reactants.length + i];
      balancedProducts.add(coeff > 1 ? '$coeff${products[i]}' : products[i]);
    }

    // Build verification data
    final Map<String, int> reactantCounts = {};
    final Map<String, int> productCounts = {};

    for (int i = 0; i < reactants.length; i++) {
      final elemCounts = parseComplexFormula(reactants[i]);
      for (final entry in elemCounts.entries) {
        reactantCounts[entry.key] =
            (reactantCounts[entry.key] ?? 0) + (entry.value * coeffs[i]);
      }
    }

    for (int i = 0; i < products.length; i++) {
      final elemCounts = parseComplexFormula(products[i]);
      for (final entry in elemCounts.entries) {
        productCounts[entry.key] =
            (productCounts[entry.key] ?? 0) +
            (entry.value * coeffs[reactants.length + i]);
      }
    }

    final List<Map<String, dynamic>> verification = [];
    for (final element in elements) {
      verification.add({
        'element': element,
        'reactants': reactantCounts[element] ?? 0,
        'products': productCounts[element] ?? 0,
      });
    }

    return {
      'reactants': balancedReactants.join(' + '),
      'products': balancedProducts.join(' + '),
      'verification': verification,
    };
  }

  /// Detect reaction type based on pattern
  static String detectReactionType(
    List<String> reactants,
    List<String> products,
  ) {
    if (reactants.length == 1 && products.length > 1) {
      return 'Decomposition';
    }

    if (reactants.length > 1 && products.length == 1) {
      return 'Synthesis';
    }

    // Check for combustion (contains O2 as reactant and CO2, H2O as products)
    if (reactants.any((r) => r.contains('O2'))) {
      if (products.any((p) => p.contains('CO2')) &&
          products.any((p) => p.contains('H2O'))) {
        return 'Combustion';
      }
    }

    if (reactants.length == 2 && products.length == 2) {
      // Could be single or double replacement
      // Simple heuristic: if one product is an element, it's single replacement
      bool hasElementProduct = products.any((p) {
        final parsed = parseComplexFormula(p);
        return parsed.length == 1 && p.length <= 2;
      });

      if (hasElementProduct) {
        return 'Single Replacement';
      }
      return 'Double Replacement';
    }

    return 'General Reaction';
  }
}
