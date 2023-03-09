part of dartrqlite;

enum ConsistencyLevel {
  consistencyLevelNone,
  consistencyLevelWeak,
  consistencyLevelStrong
}

Map<String, ConsistencyLevel> consistencyLevels = {
  "none": ConsistencyLevel.consistencyLevelNone,
  "weak": ConsistencyLevel.consistencyLevelWeak,
  "strong": ConsistencyLevel.consistencyLevelStrong,
};

enum ApiOperation { apiQuery, apiStatus, apiWrite, apiNodes }

ConnectionImpl open(String? connUrl) {
  ConnectionImpl conn = ConnectionImpl(connUrl: connUrl);
  return conn;
}
