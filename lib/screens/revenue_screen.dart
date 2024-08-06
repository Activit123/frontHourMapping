import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pontare/models/revenue.dart';
import 'package:pontare/services/revenue_service.dart';
import 'package:pontare/services/category_service.dart';
import 'package:pontare/models/category.dart';

class RevenueScreen extends StatefulWidget {
  @override
  _RevenueScreenState createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  final RevenueService revenueService = RevenueService();
  final CategoryService categoryService = CategoryService();

  final TextEditingController hoursWorkedController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  String? selectedCurrency;
  List<Category> categories = [];
  Category? selectedCategory;
  List<Revenue> revenues = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRevenues();
  }

  void _loadCategories() async {
    try {
      final fetchedCategories = await categoryService.getCategories();
      setState(() {
        categories = fetchedCategories;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load categories")),
      );
    }
  }

  void _loadRevenues() async {
    try {
      final token = 'YOUR_JWT_TOKEN'; // Replace with actual JWT token
      final fetchedRevenues = await revenueService.getRevenues(token);
      setState(() {
        revenues = fetchedRevenues;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load revenues")),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        dateController.text = DateFormat('yyyy-MM-ddTHH:mm:ss').format(picked);
      });
    }
  }

  void _showCreateRevenueDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create Revenue"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hoursWorkedController,
                decoration: InputDecoration(labelText: "Hours Worked"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: dateController,
                decoration: InputDecoration(labelText: "Current Day"),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              DropdownButton<String>(
                value: selectedCurrency,
                hint: Text("Select Currency"),
                items: ['EUR', 'GBP', 'RON', 'USD'].map((String currency) {
                  return DropdownMenuItem<String>(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCurrency = newValue;
                  });
                },
              ),
              DropdownButton<Category>(
                value: selectedCategory,
                hint: Text("Select Category"),
                items: categories.map((Category category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.categoryName),
                  );
                }).toList(),
                onChanged: (Category? newValue) {
                  setState(() {
                    selectedCategory = newValue;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (selectedCategory == null || selectedCurrency == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please select a category and a currency")),
                  );
                  return;
                }

                final hoursWorked = hoursWorkedController.text;
                final currDay = dateController.text;
                final currency = selectedCurrency!;
                final categoryId = selectedCategory!.id;

                if (double.tryParse(hoursWorked) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a valid number for hours worked")),
                  );
                  return;
                }

                final success = await revenueService.createRevenue(hoursWorked, currDay, currency, categoryId);
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Revenue created successfully")),
                  );
                  _loadRevenues(); // Reload revenues after creation
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to create revenue")),
                  );
                }
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Revenues"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: revenues.length,
              itemBuilder: (context, index) {
                final revenue = revenues[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(revenue.categoryName ?? 'No Category'),
                    subtitle: Text(
                      'Hours Worked: ${revenue.hoursWorked}\n'
                      'Date: ${revenue.currDay}\n'
                      'Currency: ${revenue.currency}',
                    ),
                    contentPadding: EdgeInsets.all(16.0),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _showCreateRevenueDialog,
            child: Text("Create Revenue"),
          ),
        ],
      ),
    );
  }
}
