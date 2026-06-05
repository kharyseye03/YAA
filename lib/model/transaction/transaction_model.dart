/// Réponse de POST /transactions
class TransactionModel {
  final int    id;
  final String reference;
  final String statut;
  final double montant;

  const TransactionModel({
    required this.id,
    required this.reference,
    required this.statut,
    required this.montant,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return TransactionModel(
      id        : (data['id']      as num).toInt(),
      reference : data['reference'] as String,
      statut    : data['statut']    as String? ?? '',
      montant   : (data['montant'] as num).toDouble(),
    );
  }
}
