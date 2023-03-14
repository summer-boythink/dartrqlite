part of dartrqlite;

abstract class Connection {
  void close();
  List<Peer> peers();
}
