import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/element.dart';
import '../models/compound.dart';
import '../models/reaction.dart';
import '../models/history_item.dart';
import '../utils/balancing_algorithm.dart';

class EquationProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  String _currentEquation = '';
  Map<String, dynamic>? _balancedResult;
  String? _errorMessage;
  List<Element> _elements = [];
  List<Compound> _compounds = [];
  List<HistoryItem> _history = [];
  List<HistoryItem> _savedHistory = [];
  List<Map<String, String>> _suggestions = [];
  bool _isLoading = false;

  String get currentEquation => _currentEquation;
  Map<String, dynamic>? get balancedResult => _balancedResult;
  String? get errorMessage => _errorMessage;
  List<Element> get elements => _elements;
  List<Compound> get compounds => _compounds;
  List<HistoryItem> get history => _history;
  List<HistoryItem> get savedHistory => _savedHistory;
  List<Map<String, String>> get suggestions => _suggestions;
  bool get isLoading => _isLoading;

  EquationProvider() {
    _loadElements();
    _loadCompounds();
    _loadHistory();
    _loadSavedHistory();
  }

  Future<void> _loadElements() async {
    _isLoading = true;
    notifyListeners();

    try {
      _elements = await _db.getAllElements();
    } catch (e) {
      debugPrint('Error loading elements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCompounds() async {
    _isLoading = true;
    notifyListeners();

    try {
      _compounds = await _db.getAllCompounds();
    } catch (e) {
      debugPrint('Error loading compounds: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadHistory() async {
    try {
      _history = await _db.getAllHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _loadSavedHistory() async {
    try {
      _savedHistory = await _db.getSavedHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved history: $e');
    }
  }

  void addToEquation(String value) {
    _currentEquation += value;
    _errorMessage = null;
    _updateSuggestions();
    notifyListeners();
  }

  void setEquation(String equation) {
    _currentEquation = equation;
    _errorMessage = null;
    _updateSuggestions();
    notifyListeners();
  }

  void clearEquation() {
    _currentEquation = '';
    _balancedResult = null;
    _errorMessage = null;
    _suggestions = [];
    notifyListeners();
  }

  void clearResultEquation() {
    _balancedResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  void deleteLastCharacter() {
    if (_currentEquation.isNotEmpty) {
      if (_currentEquation.endsWith('->')) {
        _currentEquation =
            _currentEquation.substring(0, _currentEquation.length - 2);
      } else {
        final character =
            _currentEquation.substring(_currentEquation.length - 1);
        final isLetter = RegExp(r'[a-zA-Z]').hasMatch(character);
        if (isLetter) {
          if (character == character.toUpperCase()) {
            _currentEquation =
                _currentEquation.substring(0, _currentEquation.length - 1);
          } else {
            _currentEquation =
                _currentEquation.substring(0, _currentEquation.length - 2);
          }
        } else {
          _currentEquation =
              _currentEquation.substring(0, _currentEquation.length - 1);
        }
      }
      _updateSuggestions();
      notifyListeners();
    }
  }

  Future<void> _updateSuggestions() async {
    _suggestions = [];

    if (_currentEquation.isEmpty) {
      notifyListeners();
      return;
    }

    try {
      final inputElements = _extractElements(_currentEquation);

      // Allow suggestions even for single elements
      if (inputElements.isEmpty) {
        notifyListeners();
        return;
      }

      final hasArrow = _currentEquation.contains('->');
      final parts = _currentEquation.split('->');
      final reactantSide = parts[0].trim();
      final productSide = hasArrow && parts.length > 1 ? parts[1].trim() : '';

      // Generate predictions for incomplete equations
      if (!hasArrow || productSide.isEmpty) {
        final predictions = await _generatePredictions(_currentEquation);
        _suggestions.addAll(predictions);
      }

      // Get all reactions from database
      final allReactions = await _db.getAllReactions();

      for (final reaction in allReactions) {
        final reactionReactantElements = _extractElements(reaction.reactants);
        final reactionProductElements = _extractElements(reaction.products);
        final allReactionElements = {
          ...reactionReactantElements,
          ...reactionProductElements
        };

        int score = 0;
        int reactantMatches = 0;
        int productMatches = 0;
        int totalMatches = 0;

        // Count matches in reactants and products
        for (final inputElem in inputElements) {
          if (reactionReactantElements.contains(inputElem)) {
            reactantMatches++;
            totalMatches++;
          }
          if (reactionProductElements.contains(inputElem)) {
            productMatches++;
            if (!reactionReactantElements.contains(inputElem)) {
              totalMatches++;
            }
          }
        }

        // Skip if no matches at all
        if (totalMatches == 0) continue;

        // Calculate relevance score
        if (hasArrow && productSide.isNotEmpty) {
          // User has entered both reactants and products
          final inputProductElements = _extractElements(productSide);
          int productInputMatches = 0;

          for (final elem in inputProductElements) {
            if (reactionProductElements.contains(elem)) {
              productInputMatches++;
            }
          }

          // Prioritize complete matches
          score = (reactantMatches * 100) + (productInputMatches * 100);
        } else {
          // User is still on reactant side or no arrow yet

          // Tier 1: All input elements are in reactants (highest priority)
          if (reactantMatches == inputElements.length) {
            score = 1000 + (reactantMatches * 10);
          }
          // Tier 2: Most input elements are in reactants
          else if (reactantMatches > inputElements.length / 2) {
            score = 500 + (reactantMatches * 10);
          }
          // Tier 3: Some input elements in reactants
          else if (reactantMatches > 0) {
            score = 300 + (reactantMatches * 10);
          }
          // Tier 4: Input elements only in products
          else if (productMatches > 0) {
            score = 100 + (productMatches * 5);
          }

          // Bonus for exact number of elements matching
          if (reactantMatches == inputElements.length &&
              reactionReactantElements.length == inputElements.length) {
            score += 200; // Exact match bonus
          }
        }

        final parts = reaction.balancedEquation.split('->');
        final reactants = parts[0].trim();
        final products = parts.length > 1 ? parts[1].trim() : '';

        _suggestions.add({
          'original': '${reaction.reactants}->${reaction.products}',
          'balanced': '$reactants→$products',
          'type': reaction.reactionType,
          'matchScore': score.toString(),
          'reactantMatches': reactantMatches.toString(),
          'productMatches': productMatches.toString(),
        });
      }

      // Sort by relevance score
      _suggestions.sort((a, b) {
        // Predictions always come first
        final aIsPrediction = a['type']?.startsWith('Predicted') ?? false;
        final bIsPrediction = b['type']?.startsWith('Predicted') ?? false;

        if (aIsPrediction && !bIsPrediction) return -1;
        if (!aIsPrediction && bIsPrediction) return 1;

        // Then sort by match score (descending)
        final aScore = int.tryParse(a['matchScore'] ?? '0') ?? 0;
        final bScore = int.tryParse(b['matchScore'] ?? '0') ?? 0;

        if (aScore != bScore) {
          return bScore.compareTo(aScore);
        }

        // If scores are equal, prioritize more reactant matches
        final aReactantMatches = int.tryParse(a['reactantMatches'] ?? '0') ?? 0;
        final bReactantMatches = int.tryParse(b['reactantMatches'] ?? '0') ?? 0;

        return bReactantMatches.compareTo(aReactantMatches);
      });

      // Limit to top 20 suggestions for performance
      // if (_suggestions.length > 20) {
      //   _suggestions = _suggestions.sublist(0, 20);
      // }
    } catch (e) {
      debugPrint('Error updating suggestions: $e');
    }

    notifyListeners();
  }

  Future<List<Map<String, String>>> _generatePredictions(String input) async {
    final predictions = <Map<String, String>>[];

    String reactantsInput = input.split('->')[0].trim();
    if (reactantsInput.isEmpty) return predictions;

    final reactantList = reactantsInput
        .split('+')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (reactantList.isEmpty) return predictions;

    final reactantElements = _extractElements(reactantsInput);
    if (reactantElements.length < 2) return predictions;

    if (reactantElements.contains('O') &&
        reactantList.any((r) => r.contains('O2'))) {
      for (final reactant in reactantList) {
        if (!reactant.contains('O')) {
          final metal = reactant.replaceAll(RegExp(r'\d+'), '');
          if (_isMetalElement(metal)) {
            final predicted = _predictMetalOxide(reactantsInput, metal);
            if (predicted != null) predictions.add(predicted);
          }
        }
      }
    }

    if (reactantElements.contains('C') &&
        reactantElements.contains('H') &&
        reactantElements.contains('O') &&
        reactantList.any((r) => r.contains('O2'))) {
      final predicted = _predictCombustion(reactantsInput);
      if (predicted != null) predictions.add(predicted);
    }

    if (reactantElements.contains('H') && reactantElements.contains('Cl')) {
      for (final reactant in reactantList) {
        if (!reactant.contains('H') && !reactant.contains('Cl')) {
          final metal = reactant.replaceAll(RegExp(r'\d+'), '');
          if (_isMetalElement(metal)) {
            final predicted = _predictMetalAcid(reactantsInput, metal);
            if (predicted != null) predictions.add(predicted);
          }
        }
      }
    }

    if (reactantList.length == 2 &&
        !reactantList.any((r) => r.contains('O2'))) {
      final predicted = _predictDoubleReplacement(reactantsInput, reactantList);
      if (predicted != null) predictions.add(predicted);
    }

    if (reactantList.length == 1 && reactantElements.length >= 2) {
      final predicted = _predictDecomposition(reactantsInput);
      if (predicted != null) predictions.add(predicted);
    }

    return predictions;
  }

  bool _isMetalElement(String symbol) {
    final element = findElement(symbol);
    if (element == null) return false;

    final metalCategories = [
      'Alkali Metal',
      'Alkaline Earth',
      'Transition Metal',
      'Post-transition Metal',
    ];

    return metalCategories.contains(element.category);
  }

  Map<String, String>? _predictMetalOxide(String reactants, String metal) {
    try {
      final element = findElement(metal);
      if (element == null) return null;

      String oxidationState =
          element.oxidationStates?.split(',')[0].replaceAll('+', '') ?? '2';
      int charge = int.tryParse(oxidationState) ?? 2;

      String product;
      if (charge == 1) {
        product = '${metal}2O';
      } else if (charge == 2) {
        product = '${metal}O';
      } else if (charge == 3) {
        product = '${metal}2O3';
      } else {
        product = '${metal}O';
      }

      final fullEquation = '$reactants->$product';
      final balanced = _tryBalance(fullEquation);

      return {
        'original': fullEquation,
        'balanced': balanced ?? '$reactants→$product',
        'type': 'Predicted: Synthesis',
        'matchScore': '100',
      };
    } catch (e) {
      return null;
    }
  }

  Map<String, String>? _predictCombustion(String reactants) {
    try {
      final product = 'CO2+H2O';
      final fullEquation = '$reactants->$product';
      final balanced = _tryBalance(fullEquation);

      return {
        'original': fullEquation,
        'balanced': balanced ?? '$reactants→$product',
        'type': 'Predicted: Combustion',
        'matchScore': '100',
      };
    } catch (e) {
      return null;
    }
  }

  Map<String, String>? _predictMetalAcid(String reactants, String metal) {
    try {
      String salt;
      if (reactants.contains('HCl')) {
        salt = '${metal}Cl2';
      } else if (reactants.contains('H2SO4')) {
        salt = '${metal}SO4';
      } else if (reactants.contains('HNO3')) {
        salt = '${metal}(NO3)2';
      } else {
        return null;
      }

      final product = '$salt+H2';
      final fullEquation = '$reactants->$product';
      final balanced = _tryBalance(fullEquation);

      return {
        'original': fullEquation,
        'balanced': balanced ?? '$reactants→$product',
        'type': 'Predicted: Single Replacement',
        'matchScore': '100',
      };
    } catch (e) {
      return null;
    }
  }

  Map<String, String>? _predictDoubleReplacement(
      String reactants, List<String> compounds) {
    try {
      final product = 'Products will vary';
      return {
        'original': '$reactants->',
        'balanced': '$reactants→',
        'type': 'Predicted: Double Replacement',
        'matchScore': '90',
      };
    } catch (e) {
      return null;
    }
  }

  Map<String, String>? _predictDecomposition(String reactants) {
    try {
      if (reactants.contains('O3')) {
        return {
          'original': '$reactants->',
          'balanced': '$reactants→',
          'type': 'Predicted: Decomposition',
          'matchScore': '90',
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String? _tryBalance(String equation) {
    try {
      final parts = equation.split('->');
      if (parts.length != 2) return null;

      final reactants =
          parts[0].trim().split('+').map((s) => s.trim()).toList();
      final products = parts[1].trim().split('+').map((s) => s.trim()).toList();

      final result = BalancingAlgorithm.balanceEquation(reactants, products);
      if (result != null) {
        return '${result['reactants']}→${result['products']}';
      }
    } catch (e) {
      debugPrint('Error balancing prediction: $e');
    }
    return null;
  }

  Set<String> _extractElements(String input) {
    final elements = <String>{};
    final regex = RegExp(r'([A-Z][a-z]?)');
    final matches = regex.allMatches(input);

    for (final match in matches) {
      elements.add(match.group(1)!);
    }

    return elements;
  }

  Future<void> balanceEquation() async {
    _errorMessage = null;
    _balancedResult = null;
    _suggestions = [];

    if (!_currentEquation.contains('->')) {
      _errorMessage =
          'Please add arrow (->) to separate reactants and products';
      notifyListeners();
      return;
    }

    final parts = _currentEquation.split('->');
    if (parts.length != 2) {
      _errorMessage = 'Invalid equation format';
      notifyListeners();
      return;
    }

    final reactantsStr = parts[0].trim();
    final productsStr = parts[1].trim();

    if (reactantsStr.isEmpty || productsStr.isEmpty) {
      _errorMessage = 'Equation must have both reactants and products';
      notifyListeners();
      return;
    }

    final reactantCompounds =
        reactantsStr.split('+').map((s) => s.trim()).toList();
    final productCompounds =
        productsStr.split('+').map((s) => s.trim()).toList();

    _isLoading = true;
    notifyListeners();

    try {
      final dbReaction = await _db.findReaction(reactantsStr, productsStr);

      if (dbReaction != null) {
        final balancedParts = dbReaction.balancedEquation.split('->');
        _balancedResult = {
          'reactants': balancedParts[0].trim(),
          'products': balancedParts[1].trim(),
          'type': dbReaction.reactionType,
          'fromDatabase': true,
          'description': dbReaction.description,
          'hasAlternatives': dbReaction.hasAlternatives(),
          'alternatives': dbReaction.alternativeProducts ?? '',
        };
      } else {
        final result = BalancingAlgorithm.balanceEquation(
            reactantCompounds, productCompounds);

        if (result != null) {
          final reactionType = BalancingAlgorithm.detectReactionType(
              reactantCompounds, productCompounds);

          _balancedResult = {
            'reactants': result['reactants'],
            'products': result['products'],
            'type': reactionType,
            'fromDatabase': false,
            'hasAlternatives': false,
          };
        } else {
          _errorMessage =
              'Unable to balance equation. Please verify your input.';
        }
      }

      if (_balancedResult != null) {
        final historyItem = HistoryItem(
          originalEquation: _currentEquation,
          balancedEquation:
              '${_balancedResult!['reactants']}->${_balancedResult!['products']}',
          reactionType: _balancedResult!['type'],
          timestamp: DateTime.now().toIso8601String(),
        );

        await _db.insertHistory(historyItem);
        await _loadHistory();
        await _loadSavedHistory();
      }
    } catch (e) {
      _errorMessage = 'An error occurred while balancing: ${e.toString()}';
      debugPrint('Error balancing equation: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    try {
      await _db.clearAllHistory();
      await _loadHistory();
      await _loadSavedHistory();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  Future<void> deleteHistoryItem(int id) async {
    try {
      await _db.deleteHistory(id);
      await _loadHistory();
      await _loadSavedHistory();
    } catch (e) {
      debugPrint('Error deleting history item: $e');
    }
  }

  Future<void> toggleSave(int id, bool isSaved) async {
    try {
      await _db.toggleSaveHistory(id, isSaved);
      await _loadHistory();
      await _loadSavedHistory();
    } catch (e) {
      debugPrint('Error toggling save: $e');
    }
  }

  Element? findElement(String symbol) {
    try {
      return _elements.firstWhere(
        (e) => e.symbol.toLowerCase() == symbol.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  Compound? findCompound(String formula) {
    try {
      return _compounds.firstWhere(
        (c) => c.formula.toLowerCase() == formula.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
