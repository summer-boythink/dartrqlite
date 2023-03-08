import 'package:dartrqlite/src/connection/conn_impl.dart';
import 'package:logger/logger.dart';
import 'package:test/scaffolding.dart';

void main() {
  group("connTest", () {
    test("test conn", () {
      ConnectionImpl(logger: Logger(level: Level.debug));
    });
  });
}
