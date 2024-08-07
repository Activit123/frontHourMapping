import 'package:flutter/material.dart';
import 'package:pontare/services/category_service.dart';
import 'package:pontare/models/category.dart';
import 'package:pontare/models/rate.dart';
import 'package:pontare/models/rate_dto.dart';

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryService categoryService = CategoryService();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  List<Category> allCategories = [];
  List<Category> paginatedCategories = [];
  Map<int, Rate?> categoryRates = {}; // Store rates for categories
  bool isLoading = true;
  String? errorMessage;

  int currentPage = 1;
  final int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final loadedCategories = await categoryService.getCategories();
      setState(() {
        allCategories = loadedCategories;
        isLoading = false;
        _updatePaginatedCategories();
      });

      // Fetch rates for each category
      for (var category in loadedCategories) {
        final rate = await categoryService.getRateForCategory(category.id);
        setState(() {
          categoryRates[category.id] = rate;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _updatePaginatedCategories() {
    setState(() {
      final startIndex = (currentPage - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;
      paginatedCategories = allCategories.sublist(
        startIndex,
        endIndex > allCategories.length ? allCategories.length : endIndex,
      );
    });
  }

  void _showCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create Category"),
          content: TextField(
            controller: categoryController,
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
                final categoryName = categoryController.text;
                final success = await categoryService.createCategory(categoryName);
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Category created successfully")),
                  );
                  _loadCategories();
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

  void _showEditCategoryDialog(Category category) {
    categoryController.text = category.categoryName;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Category"),
          content: TextField(
            controller: categoryController,
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
                final newCategoryName = categoryController.text;
                final success = await categoryService.updateCategory(category.id, newCategoryName);
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Category updated successfully")),
                  );
                  _loadCategories();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update category")),
                  );
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showSetRateDialog(Category category) {
    rateController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Set Rate for ${category.categoryName}"),
          content: TextField(
            controller: rateController,
            decoration: InputDecoration(labelText: "Rate"),
            keyboardType: TextInputType.number,
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
                final rate = double.tryParse(rateController.text);
                if (rate != null) {
                  final rateDTO = RateDTO(rate: rate, categoryId: category.id);
                  final success = await categoryService.setRateForCategory(rateDTO);
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Rate set successfully")),
                    );
                    setState(() {
                      categoryRates[category.id] = Rate(id: 0, rate: rate); // Update local state
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to set rate")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid rate value")),
                  );
                }
              },
              child: Text("Set Rate"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Category"),
          content: Text("Are you sure you want to delete this category?"),
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
                _deleteCategory(category.id);
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(int id) async {
    final success = await categoryService.deleteCategory(id);
    if (success) {
      setState(() {
        allCategories.removeWhere((category) => category.id == id);
        categoryRates.remove(id); // Remove rate from local state
        _updatePaginatedCategories();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Category deleted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete category")),
      );
    }
  }

  void _goToPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
        _updatePaginatedCategories();
      });
    }
  }

  void _goToNextPage() {
    if ((currentPage * itemsPerPage) < allCategories.length) {
      setState(() {
        currentPage++;
        _updatePaginatedCategories();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Categories"),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(child: Text(errorMessage!))
                    : ListView.builder(
                        itemCount: paginatedCategories.length,
                        itemBuilder: (context, index) {
                          final category = paginatedCategories[index];
                          final rate = categoryRates[category.id]?.rate;

                          return Card(
                            margin: EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text(category.categoryName),
                              subtitle: rate != null
                                  ? Text('Rate: $rate')
                                  : Text('Rate: Not set'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () => _showEditCategoryDialog(category),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () => _showDeleteConfirmationDialog(category),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.attach_money),
                                    onPressed: () => _showSetRateDialog(category),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCategoryDialog,
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
