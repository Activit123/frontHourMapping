import 'package:flutter/material.dart';
import 'package:pontare/services/category_service.dart';
import 'package:pontare/models/category.dart';

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryService categoryService = CategoryService();
  final TextEditingController categoryController = TextEditingController();
  List<Category> categories = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final loadedCategories = await categoryService.getCategories();
      setState(() {
        categories = loadedCategories;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
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
    print("Attempting to delete category with id: $id");
    final success = await categoryService.deleteCategory(id);
    if (success) {
      setState(() {
        categories.removeWhere((category) => category.id == id);
      });
      print("Category deleted successfully");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Category deleted successfully")),
      );
    } else {
      print("Failed to delete category");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete category")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Categories"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(category.categoryName),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _showDeleteConfirmationDialog(category),
                        ),
                        onTap: () => _showEditCategoryDialog(category),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCategoryDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
