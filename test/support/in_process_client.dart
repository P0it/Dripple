import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;

/// An http client that hands requests straight to a shelf handler.
///
/// Widget tests run under a binding that intercepts real sockets and answers
/// every request with a 400, so a lobby cannot talk to a server on localhost.
/// Going in-process keeps the test honest — this is the actual server code,
/// not a stub of it — and removes the socket that the binding objects to.
class InProcessClient extends http.BaseClient {
  final shelf.Handler _handler;

  InProcessClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? request.body : '';
    final response = await _handler(shelf.Request(
      request.method,
      request.url,
      headers: request.headers,
      body: body.isEmpty ? null : body,
    ));
    final bytes = utf8.encode(await response.readAsString());
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: response.headers,
      contentLength: bytes.length,
      request: request,
    );
  }
}
