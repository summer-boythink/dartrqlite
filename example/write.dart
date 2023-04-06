import 'package:dartrqlite/src/connection/conn_impl.dart';

void main() async {
  var conn = ConnectionImpl();
  var writeRes = await conn.writer.write([
    "CREATE TABLE foo (id INTEGER NOT NULL PRIMARY KEY, name TEXT, age INTEGER)",
    "INSERT INTO foo(name, age) VALUES('fiona', 20)",
    "INSERT INTO foo(name, age) VALUES('fiona', 20)"
  ]);
  for (var res in writeRes) {
    print(res.result);
  }
}
