import 'package:dartrqlite/dartrqlite.dart';

typedef Peer = String;

class RqliteCluster {
  late Peer? leader;
  late List<Peer> otherPeers;
  late List<Peer> peerList;
  late Connection conn;

  RqliteCluster();

  List<Peer> getPeerList() {
    return peerList;
  }
}
