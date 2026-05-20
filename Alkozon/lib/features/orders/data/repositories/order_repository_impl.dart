import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remoteDataSource);

  final OrderRemoteDataSource _remoteDataSource;

  @override
  Future<StaffCombinedOrders> getStaffCombinedOrders() =>
      _remoteDataSource.getStaffCombinedOrders();

  @override
  Future<List<OrderData>> getAllOrders() => _remoteDataSource.getAllOrders();

  @override
  Future<List<OrderData>> getAllCustomOrders() =>
      _remoteDataSource.getAllCustomOrders();

  @override
  Future<CourierCombinedOrders> getCourierCombinedOrders(int courierUserId) =>
      _remoteDataSource.getCourierCombinedOrders(courierUserId);

  @override
  Future<OrderData> getOrderById(int id, {String? token}) =>
      _remoteDataSource.getOrderById(id, token: token);

  @override
  Future<OrderData> getCustomOrderById(int id, {String? token}) =>
      _remoteDataSource.getCustomOrderById(id, token: token);

  @override
  Future<List<OrderData>> getMyDeliveryOrders({bool onlyInDelivery = true}) =>
      _remoteDataSource.getMyDeliveryOrders(onlyInDelivery: onlyInDelivery);

  @override
  Future<OrderData> patchStatus({required int id, required String status}) =>
      _remoteDataSource.patchStatus(id: id, status: status);

  @override
  Future<OrderData> patchCustomStatus({
    required int id,
    required String status,
  }) => _remoteDataSource.patchCustomStatus(id: id, status: status);
}
