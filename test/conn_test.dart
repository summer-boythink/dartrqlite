import 'package:dartrqlite/dartrqlite.dart';
import 'package:dartrqlite/src/connection/conn_impl.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  group("#connTest", () {
    test("simple conn", () {
      ConnectionImpl(initLogger: Logger(level: Level.info));
    });

    test("error url", () {
      try {
        ConnectionImpl(connUrl: "httw://wwe.o");
      } catch (e) {
        assert(e == 'url does not start with "http"');
      }
    });

    test("parse url", () {
      var testUrls = [
        "https://mary:secret2@localhost:4001/db",
        "",
        "https://mary@localhost:4001/db"
      ];
      for (var url in testUrls) {
        var res = Uri.parse(url);
        var info = res.userInfo.split(":");
        assert(info.length <= 2 && info.isNotEmpty);
      }
    });

    test("query params", () {
      var conn = ConnectionImpl(
          connUrl:
              "https://mary:secret2@server2.example.com:4001/db?level=weak&&timeout=2&&disableClusterDiscovery=true");
      assert(conn.timeout == 2 &&
          conn.disableClusterDiscovery == true &&
          conn.consistencyLevel == ConsistencyLevel.consistencyLevelWeak);
    });
  });
}
