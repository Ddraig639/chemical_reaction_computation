class HistoryItem {
  final int? id;
  final String originalEquation;
  final String balancedEquation;
  final String reactionType;
  final String timestamp;
  final String? verificationData;

  HistoryItem({
    this.id,
    required this.originalEquation,
    required this.balancedEquation,
    required this.reactionType,
    required this.timestamp,
    this.verificationData,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as int?,
      originalEquation: json['original_equation'] as String,
      balancedEquation: json['balanced_equation'] as String,
      reactionType: json['reaction_type'] as String,
      timestamp: json['timestamp'] as String,
      verificationData: json['verification_data'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original_equation': originalEquation,
      'balanced_equation': balancedEquation,
      'reaction_type': reactionType,
      'timestamp': timestamp,
      'verification_data': verificationData,
    };
  }

  String getFormattedTimestamp() {
    final dt = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
