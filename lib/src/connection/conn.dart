part of dartrqlite;

abstract class Connection {
  void close();
  List<Peer> peers();
  Peer leader();
  void setExecutionWithTransaction(bool state);
  Future<String> rqliteApiGet(ApiOperation apiOp);
  Future<String> rqliteApiPost(ApiOperation apiOp, dynamic body);

  late bool hasBeenClosed;
  late Logger logger;
  late final int id;
  late bool wantsQueueing;
}
