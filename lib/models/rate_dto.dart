class RateDTO {
  final double rate;
  final int categoryId;

  RateDTO({
    required this.rate,
    required this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'rate': rate,
      'categoryId': categoryId,
    };
  }
}
