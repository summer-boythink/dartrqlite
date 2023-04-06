import 'package:dartrqlite/dartrqlite.dart';
import 'package:dartrqlite/src/connection/conn_impl.dart';
import 'package:dartrqlite/src/write/write_result.dart';

class Writer {
  late Connection currentConn;

  /// WriteOne wraps Write() into a single-statement
  Future<WriteResult> writeOne(List<dynamic> sqlStatements) async {
    return (await write(sqlStatements))[0];
  }

  /// Write sqlStatements
  Future<List<WriteResult>> write(List<dynamic> sqlStatements) async {
    if (currentConn.hasBeenClosed) {
      throw errorCloseMsg;
    }
    var res =
        await currentConn.rqliteApiPost(ApiOperation.apiWrite, sqlStatements);

    var id = currentConn.id;
    currentConn.logger.d('$id write() OK');

    // TODO:become a list of QueryResult,now just a String
    return [WriteResult(res)];
  }

  /// QueueOne is a convenience method that wraps Queue into a single-statement.
  Future<WriteResult> queueOne(List<dynamic> sqlStatements) async {
    return (await queue(sqlStatements))[0];
  }

  /// Queue sqlStatements
  Future<List<WriteResult>> queue(List<dynamic> sqlStatements) async {
    if (currentConn.hasBeenClosed) {
      throw errorCloseMsg;
    }

    currentConn.wantsQueueing = true;
    var res =
        await currentConn.rqliteApiPost(ApiOperation.apiWrite, sqlStatements);

    var id = currentConn.id;
    currentConn.logger.d('$id queue() OK');
    currentConn.wantsQueueing = false;
    // TODO:become a list of QueryResult,now just a String
    return [WriteResult(res)];
  }

  Writer(Connection conn) {
    currentConn = conn;
  }
}
