class Revenue {
  final int id;
  final String hoursWorked;
  final String currDay;
  final String currency;
  final String? categoryName;

  Revenue({
    required this.id,
    required this.hoursWorked,
    required this.currDay,
    required this.currency,
    this.categoryName,
  });

  factory Revenue.fromJson(Map<String, dynamic> json) {
    return Revenue(
      id: json['id'],
      hoursWorked: json['hoursWorked'],
      currDay: json['currDay'],
      currency: json['currency'],
      categoryName: json['categoryName'],
    );
  }
}
