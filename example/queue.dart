import 'package:dartrqlite/src/connection/conn_impl.dart';

void main() async {
  var conn = ConnectionImpl();
  var writeRes = await conn.writer.queue([
    "CREATE TABLE foo2 (id INTEGER NOT NULL PRIMARY KEY, name TEXT, age INTEGER)",
    "INSERT INTO foo2(name, age) VALUES('fiona', 20)",
    "INSERT INTO foo2(name, age) VALUES('fiona', 20)"
  ]);
  for (var res in writeRes) {
    print(res.result);
  }
}
