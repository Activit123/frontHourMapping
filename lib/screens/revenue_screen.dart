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
  List<Revenue> allRevenues = [];
  List<Revenue> paginatedRevenues = [];

  int currentPage = 1;
  final int itemsPerPage = 4;

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
        allRevenues = fetchedRevenues;
        _updatePaginatedRevenues();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load revenues")),
      );
    }
  }

  void _updatePaginatedRevenues() {
    setState(() {
      final startIndex = (currentPage - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;
      paginatedRevenues = allRevenues.sublist(
        startIndex,
        endIndex > allRevenues.length ? allRevenues.length : endIndex,
      );
    });
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
              categories.isNotEmpty
                  ? DropdownButton<Category>(
                      value: selectedCategory,
                      hint: Text("Select Category"),
                      items: categories.map((Category category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Text(category.categoryName),
                        );
                      }).toList()
                        ..add(
                          DropdownMenuItem<Category>(
                            child: Text("Create New Category"),
                            onTap: () {
                              Navigator.pop(context);
                              _showCreateCategoryDialog();
                            },
                          ),
                        ),
                      onChanged: (Category? newValue) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                    )
                  : TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCreateCategoryDialog();
                      },
                      child: Text("Create New Category"),
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

  void _showUpdateCategoryDialog(Revenue revenue) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Category"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<Category>(
                value: selectedCategory,
                hint: Text("Select Category"),
                items: categories.map((Category category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.categoryName),
                  );
                }).toList()
                  ..add(
                    DropdownMenuItem<Category>(
                      child: Text("Create New Category"),
                      onTap: () {
                        Navigator.pop(context);
                        _showCreateCategoryDialog();
                      },
                    ),
                  ),
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
                if (selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please select or create a category")),
                  );
                  return;
                }

                final success = await revenueService.updateRevenueCategory(
                  revenue.id,
                  selectedCategory!.categoryName,
                );
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Category updated successfully")),
                  );
                  _loadRevenues(); // Reload revenues after update
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update category")),
                  );
                }
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _showCreateCategoryDialog() {
    final TextEditingController categoryNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create New Category"),
          content: TextField(
            controller: categoryNameController,
            decoration: InputDecoration(labelText: "Category Name"),
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
                final categoryName = categoryNameController.text;
                if (categoryName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Category name cannot be empty")),
                  );
                  return;
                }

                final success = await categoryService.createCategory(categoryName);
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Category created successfully")),
                  );
                  // Reload categories and show update category dialog
                  _loadCategories();
                  // Optional: Open the update category dialog if a new category is created
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to create category")),
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

  void _showDeleteConfirmationDialog(Revenue revenue) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Revenue"),
          content: Text("Are you sure you want to delete this revenue?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteRevenue(revenue.id);
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _deleteRevenue(int id) async {
    final success = await revenueService.deleteRevenue(id);
    if (success) {
      setState(() {
        allRevenues.removeWhere((revenue) => revenue.id == id);
        _updatePaginatedRevenues(); // Update paginated list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Revenue deleted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete revenue")),
      );
    }
  }

  void _goToPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
        _updatePaginatedRevenues();
      });
    }
  }

  void _goToNextPage() {
    if ((currentPage * itemsPerPage) < allRevenues.length) {
      setState(() {
        currentPage++;
        _updatePaginatedRevenues();
      });
    }
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
              itemCount: paginatedRevenues.length,
              itemBuilder: (context, index) {
                final revenue = paginatedRevenues[index];
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showUpdateCategoryDialog(revenue),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _showDeleteConfirmationDialog(revenue),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _goToPreviousPage,
                child: Text("Previous"),
              ),
              Text("Page $currentPage"),
              TextButton(
                onPressed: _goToNextPage,
                child: Text("Next"),
              ),
            ],
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
