import '../repositories/device_security_repository.dart';

class CheckDeviceSecurityUseCase {
  const CheckDeviceSecurityUseCase(this._repository);

  final DeviceSecurityRepository _repository;

  Future<void> call() => _repository.checkDeviceSecurity();
}
