import 'package:dartrqlite/dartrqlite.dart';
import 'package:dartrqlite/src/cluster/cluster.dart';
import 'package:flutter_snowflake/flutter_snowflake.dart';
import 'package:format/format.dart';
import 'package:logger/logger.dart';
import 'package:requests/requests.dart';

class ConnectionImpl implements Connection {
  /// Connect to the cluster
  RqliteCluster cluster = RqliteCluster();
  // Some properties of the connection
  String user = "";
  String pass = "";
  bool wantHTTPS = false;
  late bool hasBeenClosed;

  /// Output connection logs, which are displayed on the command line by default
  late Logger logger;

  /// generated in ConnectionImpl
  late final int id;

  /// Initialize http client for connection
  Requests client = Requests();

  /// Some properties from `url.parse()`
  ConsistencyLevel consistencyLevel = ConsistencyLevel.consistencyLevelWeak;
  bool disableClusterDiscovery = false;
  int timeout = 10;

  ConnectionImpl({String? connUrl, Logger? initLogger}) {
    logger = initLogger ?? Logger(level: Level.info);
    id = -(Snowflake(2, 3).getId());
    logger.d(format('your id is {}', id.toInt()));
    connUrl = connUrl ?? "http://localhost:4001";
    _initconnection(connUrl);
  }

  Logger getLogger() {
    return logger;
  }

  void setLogger(Logger newLogger) {
    logger = newLogger;
  }

  /// TODO:leader() tells the current leader of the cluster
  Peer leader() {
    return "";
  }

  /// Peers tells the current peers of the cluster
  @override
  List<Peer> peers() {
    if (hasBeenClosed) {
      throw "connection is closed";
    }
    List<String> plist = [];
    if (disableClusterDiscovery) {
      for (var element in cluster.peerList) {
        plist.add(element);
      }
      return plist;
    }
    logger.d(format("{}: Peers(), calling updateClusterInfo()", id));
    _updateClusterInfo();
    cluster.leader ?? plist.add(cluster.leader!);
    for (var element in cluster.otherPeers) {
      plist.add(element);
    }
    return plist;
  }

  /// Close will mark the connection as closed.
  @override
  void close() {
    hasBeenClosed = true;
    logger.d("conn closing");
  }

  void _initconnection(String connUrl) {
    if (connUrl.length < 7) {
      throw 'url specified is impossibly short';
    }
    if (connUrl.indexOf('http') != 0) {
      throw 'url does not start with "http"';
    }

    final u = Uri.parse(connUrl);
    logger.d(format('{} Uri.parse() OK', id));

    // set wantHTTPS
    if (u.scheme == "https") {
      wantHTTPS = true;
    }

    // set user and pass
    List<String> userInfo = u.userInfo.split(':');
    if (userInfo.length == 1 && userInfo[0] == "") {
      user = "";
      pass = "";
    } else if (userInfo.length == 1 && userInfo[0] != "") {
      user = userInfo[0];
      pass = "";
    } else {
      user = userInfo[0];
      pass = userInfo[1];
    }

    // TODO:set cluster leader by u.host

    /**
     * parse query params
     */
    Map<String, String> query = u.queryParameters;
    if (query.containsKey("level")) {
      if (consistencyLevels.containsKey(query["level"])) {
        consistencyLevel = consistencyLevels[query["level"]]!;
      } else {
        throw format(
            "invalid consistency level:{}", query.containsKey("level"));
      }
    }

    if (query.containsKey("disableClusterDiscovery")) {
      if (query["disableClusterDiscovery"]!.toLowerCase() == "true") {
        disableClusterDiscovery = true;
      } else if (query["disableClusterDiscovery"]!.toLowerCase() == "false") {
        disableClusterDiscovery = false;
      } else {
        throw "invalid disableClusterDiscovery value";
      }
    }

    if (query.containsKey("timeout")) {
      try {
        timeout = int.parse(query["timeout"]!);
      } catch (e) {
        throw "invalid timeout specified";
      }
    }
  }

  // TODO: Returns an api address for rqlite
  String _assembleUrl(ApiOperation apiOp, Peer p) {
    return "";
  }

  void _updateClusterInfo() {
    logger.d('$id _updateClusterInfo() called');
    cluster.conn = this;
  }

  dynamic _rqliteApiCall(ApiOperation apiOp, String method,
      [dynamic requestBody]) {
    var peers = cluster.getPeerList();
    if (peers.length < 1) {
      throw "don't have any cluster info";
    }
    logger.d('$id : I have a peer list $peers peers long');

    // Keep list of failed requests to each peer, return in case all peers fail to answer
    List<String> failLogs = [];
    for (var peer in peers) {
      var url = _assembleUrl(apiOp, peer);
    }
  }

  String _rqliteApiGet(ApiOperation apiOp) {
    logger.d('$id rqliteApiGet() called');
    if (apiOp != ApiOperation.apiStatus && apiOp != ApiOperation.apiNodes) {
      throw "rqliteApiGet() called for invalid api operation";
    }
    return _rqliteApiCall(apiOp, "GET");
  }
}
