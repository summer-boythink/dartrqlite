import 'package:dartrqlite/src/connection/conn_impl.dart';

void main() async {
  var conn = ConnectionImpl();
  var delRes = await conn.writer.writeOne(["DROP TABLE foo"]);
  print(delRes.result);
}
