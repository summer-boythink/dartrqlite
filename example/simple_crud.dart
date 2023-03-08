import 'package:requests/requests.dart';

Future<String> excute(dynamic bodys, String url) async {
  var r = await Requests.post(url,
      body: bodys, bodyEncoding: RequestBodyEncoding.JSON);
  r.raiseForStatus();
  String body = r.content();
  return body;
}

void main(List<String> arguments) async {
  print(await excute([
    "CREATE TABLE foo (id INTEGER NOT NULL PRIMARY KEY, name TEXT, age INTEGER)",
    "INSERT INTO foo(name, age) VALUES('fiona', 20)",
    "INSERT INTO foo(name, age) VALUES('fiona', 20)"
  ], 'http://127.0.0.1:4001/db/execute?pretty&timings'));
  print(await excute(
      ["SELECT * FROM foo"], 'http://127.0.0.1:4001/db/query?pretty&timings'));
  print(await excute(
      ["DROP TABLE foo"], 'http://127.0.0.1:4001/db/execute?pretty&timings'));
}
