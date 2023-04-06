import 'package:dartrqlite/src/connection/conn_impl.dart';

void main() async {
  var conn = ConnectionImpl();
  var queryResult = await conn.queryer.queryOne(["SELECT * FROM foo"]);
  print(queryResult.result);
}
