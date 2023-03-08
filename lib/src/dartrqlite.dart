part of dartrqlite;

enum ConsistencyLevel {
  consistencyLevelNone,
  consistencyLevelWeak,
  consistencyLevelStrong
}

enum ApiOperation { apiQuery, apiStatus, apiWrite, apiNodes }

ConnectionImpl open(String? connUrl) {
  ConnectionImpl conn = ConnectionImpl(connUrl: connUrl);
  return conn;
}
