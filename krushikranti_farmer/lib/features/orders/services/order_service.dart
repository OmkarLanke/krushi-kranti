import '../models/sales_order_model.dart';

class OrderService {
  
  // Simulate Network Delay
  static Future<List<SalesOrderModel>> getOrders() async {
    await Future.delayed(const Duration(seconds: 1)); // Fake loading

    // Return Mock Data
    return [
      SalesOrderModel(
        id: "#90897", 
        date: "October 19 2021", 
        items: 1, 
        weight: "20Kg", 
        status: "Received"
      ),
      SalesOrderModel(
        id: "#90898", 
        date: "October 20 2021", 
        items: 2, 
        weight: "45Kg", 
        status: "Received"
      ),
      SalesOrderModel(
        id: "#90899", 
        date: "October 22 2021", 
        items: 1, 
        weight: "100Kg", 
        status: "Pending"
      ),
      SalesOrderModel(
        id: "#91002", 
        date: "October 25 2021", 
        items: 5, 
        weight: "250Kg", 
        status: "Pending"
      ),
    ];
  }
}