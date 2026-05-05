// lib/utils/constants.dart

class AppConstants {
  // Admin credentials
  static const String adminEmail = 'canteen@admin.com';

  // Firestore collection names
  static const String ordersCollection = 'orders';
  static const String menuCollection = 'menu';
  static const String usersCollection = 'users';

  // Order statuses
  static const String statusWaiting = 'waiting';
  static const String statusPreparing = 'preparing';
  static const String statusReady = 'ready';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Menu categories
 static const List<String> categories = [
    'All',
    'Starters',
    'Biryani',
    'Curries',
    'Rotis',
    'Snacks',
    'Drinks',
    'Sweets',
    'Ice Creams',
  ];

  // Default menu items (used if Firestore menu is empty)
static const List<Map<String, dynamic>> defaultMenu = [
    {"name": "Samosa", "price": 20, "category": "Starters", "image": "https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400", "available": true},
    {"name": "Veg Cutlet", "price": 25, "category": "Starters", "image": "https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=400", "available": true},
    {"name": "Spring Roll", "price": 30, "category": "Starters", "image": "https://images.unsplash.com/photo-1544025162-d76594e8f7dc?w=400", "available": true},
    {"name": "Veg Biryani", "price": 80, "category": "Biryani", "image": "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400", "available": true},
    {"name": "Chicken Biryani", "price": 120, "category": "Biryani", "image": "https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=400", "available": true},
    {"name": "Egg Biryani", "price": 100, "category": "Biryani", "image": "https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400", "available": true},
    {"name": "Paneer Curry", "price": 70, "category": "Curries", "image": "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400", "available": true},
    {"name": "Dal Tadka", "price": 50, "category": "Curries", "image": "https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400", "available": true},
    {"name": "Chicken Curry", "price": 100, "category": "Curries", "image": "https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400", "available": true},
    {"name": "Chapati", "price": 10, "category": "Rotis", "image": "https://images.unsplash.com/photo-1606676539940-12768ce0e762?w=400", "available": true},
    {"name": "Parotta", "price": 15, "category": "Rotis", "image": "https://images.unsplash.com/photo-1565183997392-2f6f122e5912?w=400", "available": true},
    {"name": "Naan", "price": 20, "category": "Rotis", "image": "https://images.unsplash.com/photo-1601050690117-94f5f7fa8b94?w=400", "available": true},
    {"name": "Burger", "price": 50, "category": "Snacks", "image": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400", "available": true},
    {"name": "Sandwich", "price": 40, "category": "Snacks", "image": "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400", "available": true},
    {"name": "Noodles", "price": 55, "category": "Snacks", "image": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400", "available": true},
    {"name": "Tea", "price": 10, "category": "Drinks", "image": "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400", "available": true},
    {"name": "Coffee", "price": 20, "category": "Drinks", "image": "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400", "available": true},
    {"name": "Cold Drink", "price": 30, "category": "Drinks", "image": "https://images.unsplash.com/photo-1527960471264-932f39eb5846?w=400", "available": true},
    {"name": "Lassi", "price": 35, "category": "Drinks", "image": "https://images.unsplash.com/photo-1571805529673-0f56b922b359?w=400", "available": true},
    {"name": "Gulab Jamun", "price": 25, "category": "Sweets", "image": "https://images.unsplash.com/photo-1606491956689-2ea866880c84?w=400", "available": true},
    {"name": "Halwa", "price": 30, "category": "Sweets", "image": "https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400", "available": true},
    {"name": "Kheer", "price": 35, "category": "Sweets", "image": "https://images.unsplash.com/photo-1571197119738-4b9e61fba1f4?w=400", "available": true},
    {"name": "Vanilla Ice Cream", "price": 30, "category": "Ice Creams", "image": "https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=400", "available": true},
    {"name": "Chocolate Ice Cream", "price": 35, "category": "Ice Creams", "image": "https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400", "available": true},
    {"name": "Mango Ice Cream", "price": 35, "category": "Ice Creams", "image": "https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=400", "available": true},
  ];

}