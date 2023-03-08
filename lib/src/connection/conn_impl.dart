import 'package:dartrqlite/dartrqlite.dart';
import 'package:flutter_snowflake/flutter_snowflake.dart';
import 'package:format/format.dart';
import 'package:logger/logger.dart';

class ConnectionImpl extends Connection {
  late Logger logger;
  // generated in ConnectionImpl
  late final int id;

  ConnectionImpl({String? connUrl, Logger? logger}) {
    logger = logger ?? Logger(level: Level.info);
    id = -(Snowflake(2, 3).getId());
    logger.d(format('your id is {}', id.toInt()));
  }

  Logger getLogger() {
    return logger;
  }

  void setLogger(Logger newLogger) {
    logger = newLogger;
  }
}
