import 'package:pontare/models/category.dart';

class Rate {
  final int id;
  final double rate;
  final Category? category;

  Rate({required this.id, required this.rate, this.category});

  factory Rate.fromJson(Map<String, dynamic> json) {
    return Rate(
      id: json['id'] as int,
      rate: json['rate'] as double,
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
    );
  }
}