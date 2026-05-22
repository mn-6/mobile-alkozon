abstract class StartupRepository {
  Future<void> waitForServerReady({Duration? timeout});
}
