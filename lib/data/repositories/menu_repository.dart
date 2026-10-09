import '../../models/dish.dart';

abstract class MenuRepository {
  Future<List<Dish>> getDishes();
  Future<Dish?> getDishById(String id);
  Future<List<String>> getCategories();
  Future<List<Dish>> searchDishes(String query, {String? category});
}
