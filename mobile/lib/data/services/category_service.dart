import 'package:expense_tracker_mobile/core/network/api_client.dart';
import 'package:expense_tracker_mobile/data/models/category.dart';

class CategoryService {
  final ApiClient _apiClient;

  CategoryService(this._apiClient);

  Future<List<Category>> getCategories() async {
    try {
      // Add user-specific parameter to ensure proper filtering
      final response = await _apiClient.get('/categories');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Category.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<Category> getCategoryById(int id) async {
    try {
      final response = await _apiClient.get('/categories/$id');

      if (response.statusCode == 200) {
        return Category.fromJson(response.data['data'] ?? response.data);
      }
      throw Exception('Category not found');
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  Future<Category> createCategory(Category category) async {
    try {
      Map<String, dynamic> categoryData = category.toJson();
      categoryData.remove('id'); // Remove ID for creation
      categoryData.remove('created_at');
      categoryData.remove('updated_at');

      final response = await _apiClient.post('/categories', data: categoryData);

      if (response.statusCode == 201) {
        return Category.fromJson(response.data['data'] ?? response.data);
      }

      throw Exception('Failed to create category');
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<Category> updateCategory(int id, Category category) async {
    try {
      Map<String, dynamic> categoryData = category.toJson();
      categoryData.remove('id');
      categoryData.remove('created_at');
      categoryData.remove('updated_at');

      final response = await _apiClient.put('/categories/$id', data: categoryData);

      if (response.statusCode == 200) {
        return Category.fromJson(response.data['data'] ?? response.data);
      }

      throw Exception('Failed to update category');
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _apiClient.delete('/categories/$id');
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}