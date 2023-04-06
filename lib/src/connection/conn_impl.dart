import 'package:dartrqlite/dartrqlite.dart';
import 'package:dartrqlite/src/cluster/cluster.dart';
import 'package:dartrqlite/src/query/queryer.dart';
import 'package:dartrqlite/src/write/writer.dart';
import 'package:flutter_snowflake/flutter_snowflake.dart';
import 'package:format/format.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';
import 'package:requests/requests.dart';

const errorCloseMsg = "connection is closed";

class ConnectionImpl implements Connection {
  /// Connect to the cluster
  RqliteCluster cluster = RqliteCluster();
  // Some properties of the connection
  String user = "";
  String pass = "";
  bool wantHTTPS = false;
  @override
  late bool hasBeenClosed;
  bool wantTransactions = true;
  @override
  late bool wantsQueueing = false;

  /// Output connection logs, which are displayed on the command line by default
  @override
  late Logger logger;

  /// generated in ConnectionImpl
  @override
  late final int id;

  /// Initialize http client for connection
  Requests client = Requests();

  /// Some properties from `url.parse()`
  ConsistencyLevel consistencyLevel = ConsistencyLevel.consistencyLevelWeak;
  bool disableClusterDiscovery = false;
  int timeout = 10;

  /// Queryer is used to perform SELECT operations in the database.
  late Queryer queryer;

  /// Write is used to perform DDL/DML in the database synchronously without parameters.
  late Writer writer;

  ConnectionImpl({String? connUrl, Logger? initLogger}) {
    logger = initLogger ?? Logger(level: Level.info);
    id = -(Snowflake(2, 3).getId());
    logger.d(format('your id is {}', id.toInt()));
    connUrl = connUrl ?? "http://localhost:4001";
    queryer = Queryer(this);
    writer = Writer(this);
    hasBeenClosed = false;
    _initconnection(connUrl);
  }

  Logger getLogger() {
    return logger;
  }

  void setLogger(Logger newLogger) {
    logger = newLogger;
  }

  /// set state for `wantsTransactions`
  @override
  void setExecutionWithTransaction(bool state) {
    if (hasBeenClosed) {
      throw errorCloseMsg;
    }
    wantTransactions = state;
  }

  /// TODO:leader() tells the current leader of the cluster
  Peer leader() {
    if (hasBeenClosed) {
      throw errorCloseMsg;
    }
    if (disableClusterDiscovery) {
      return cluster.leader!;
    }
    logger.i('$id :Leader(), calling updateClusterInfo()');
    _updateClusterInfo();
    // TODO: cluster
    return "";
  }

  /// Peers tells the current peers of the cluster
  @override
  List<Peer> peers() {
    if (hasBeenClosed) {
      throw errorCloseMsg;
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

    // cluster.leader = connUrl;
    if (u.authority.isEmpty) {
      cluster.leader = "localhost:4001";
    } else {
      cluster.leader = u.authority;
    }
    cluster.peerList = [cluster.leader!];
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

  String _assembleUrl(ApiOperation apiOp, Peer p) {
    var res = "";
    if (wantHTTPS) {
      res += "https";
    } else {
      res += "http";
    }
    res += "://";
    if (user.isNotEmpty && pass.isNotEmpty) {
      res += '$user:$pass@';
    }
    res += p;

    switch (apiOp) {
      case ApiOperation.apiStatus:
        res += '/status';
        break;
      case ApiOperation.apiNodes:
        res += '/nodes';
        break;
      case ApiOperation.apiQuery:
        res += '/db/query';
        break;
      case ApiOperation.apiWrite:
        res += '/db/execute';
        break;
    }

    if (apiOp == ApiOperation.apiQuery || apiOp == ApiOperation.apiWrite) {
      res += '?timings&level=';
      consistencyLevels.map((key, value) {
        if (value == consistencyLevel) {
          res += key.toString();
        }
        return MapEntry(key, value);
      });
      if (wantTransactions) {
        res += '&transactions';
      }
      if (apiOp == ApiOperation.apiWrite && wantsQueueing) {
        res += '&queue';
      }
    }
    return res;
  }

  void _updateClusterInfo() {
    logger.d('$id _updateClusterInfo() called');
    //TODO:rqliteApiGet
    cluster.conn = this;
  }

  Future<dynamic> _rqliteApiCall(ApiOperation apiOp, String method,
      [dynamic requestBody]) async {
    var peers = cluster.getPeerList();
    if (peers.isEmpty) {
      throw "don't have any cluster info";
    }
    logger.d('$id : I have a peer list $peers peers long');

    // Keep list of failed requests to each peer, return in case all peers fail to answer
    List<String> failLogs = [];
    for (var peer in peers) {
      var url = _assembleUrl(apiOp, peer);

      // prepare request
      method = method.toUpperCase();
      late Response req;
      switch (method) {
        case "GET":
          req = await Requests.get(url,
              body: requestBody, bodyEncoding: RequestBodyEncoding.JSON);
          break;
        case "POST":
          req = await Requests.post(url,
              body: requestBody, bodyEncoding: RequestBodyEncoding.JSON);
          break;
        default:
          logger.e('current no support $method');
      }
      try {
        req.raiseForStatus();
      } catch (e) {
        failLogs.add(e.toString());
        rethrow;
        // return null;
      }
      String responseBody = req.content();
      return responseBody;
    }
  }

  Future<String> rqliteApiGet(ApiOperation apiOp) async {
    logger.d('$id rqliteApiGet() called');
    if (apiOp != ApiOperation.apiStatus && apiOp != ApiOperation.apiNodes) {
      throw "rqliteApiGet() called for invalid api operation";
    }
    return await _rqliteApiCall(apiOp, "GET");
  }

  Future<String> rqliteApiPost(ApiOperation apiOp, dynamic body) async {
    logger.d('$id rqliteApiPost() called');
    if (apiOp != ApiOperation.apiQuery && apiOp != ApiOperation.apiWrite) {
      throw "rqliteApiPost() called for invalid api operation";
    }
    return await _rqliteApiCall(apiOp, "POST", body);
  }
}
