import 'package:dartrqlite/dartrqlite.dart';
import 'package:dartrqlite/src/connection/conn_impl.dart';
import 'package:dartrqlite/src/query/query_result.dart';

class Queryer {
  late Connection currentConn;

  /// QueryOne wraps Query into a single-statement method.
  Future<QueryResult> queryOne(List<dynamic> sqlStatements) async {
    return (await query(sqlStatements))[0];
  }

  /// Query for sqlStatements
  Future<List<QueryResult>> query(List<dynamic> sqlStatements) async {
    if (currentConn.hasBeenClosed) {
      throw errorCloseMsg;
    }
    var res =
        await currentConn.rqliteApiPost(ApiOperation.apiQuery, sqlStatements);

    var id = currentConn.id;
    currentConn.logger.d('$id query() OK');

    // TODO:become a list of QueryResult,now just a String
    return [QueryResult(res)];
  }

  Queryer(Connection conn) {
    currentConn = conn;
  }
}
