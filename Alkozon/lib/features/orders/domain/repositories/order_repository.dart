import '../entities/order.dart';

abstract class OrderRepository {
  Future<StaffCombinedOrders> getStaffCombinedOrders();
  Future<List<OrderData>> getAllOrders();
  Future<List<OrderData>> getAllCustomOrders();
  Future<CourierCombinedOrders> getCourierCombinedOrders(int courierUserId);
  Future<OrderData> getOrderById(int id, {String? token});
  Future<OrderData> getCustomOrderById(int id, {String? token});
  Future<List<OrderData>> getMyDeliveryOrders({bool onlyInDelivery = true});
  Future<OrderData> patchStatus({required int id, required String status});
  Future<OrderData> patchCustomStatus({required int id, required String status});
}
