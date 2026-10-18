// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/mjpeg_view.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Live MJPEG picture from HYDRA-UMC-SERVER's GET /api/camera/:id/stream (a
// multipart/x-mixed-replace stream of JPEG frames). The frames are found by
// scanning for the JPEG start/end markers, which works whatever the exact
// multipart framing is.
//
//  - [headers] carry the client identity and the bearer token: a server run
//    with HYDRA_UMC_CAMERA_AUTH=required refuses the picture without them.
//  - Only an HTTP 200 is a stream; any other answer is shown as "unavailable"
//    with its reason instead of being parsed as if it were video.
//  - When frames arrive faster than they are drawn the NEWEST complete frame
//    is shown, not the oldest, so the picture never lags further behind.
//  - The pending bytes are capped, so a stream that never produces a frame
//    end (corrupt, or an error page) cannot grow the buffer without limit.
//  - Every connection attempt carries a generation number: the answer of an
//    attempt that was replaced (the address changed, the widget was disposed)
//    is dropped instead of leaving a second stream running.
// =============================================================================

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../l10n/app_localizations.dart';

/// Upper bound for the bytes waiting for a frame end.
const int mjpegMaxBufferBytes = 4 * 1024 * 1024;

/// The newest complete JPEG in [bytes] as (start, endExclusive), or null when
/// there is none yet. Used by the view, and testable on its own.
({int start, int end})? findLastJpegFrame(Uint8List bytes) {
  // Last end-of-image marker, then the closest start-of-image before it.
  var end = -1;
  for (var i = bytes.length - 2; i >= 0; i--) {
    if (bytes[i] == 0xFF && bytes[i + 1] == 0xD9) {
      end = i;
      break;
    }
  }
  if (end < 0) return null;
  for (var i = end - 2; i >= 0; i--) {
    if (bytes[i] == 0xFF && bytes[i + 1] == 0xD8) {
      return (start: i, end: end + 2);
    }
  }
  return null;
}

class MjpegView extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  const MjpegView({super.key, required this.url, this.headers});

  @override
  State<MjpegView> createState() => _MjpegViewState();
}

class _MjpegViewState extends State<MjpegView> {
  Uint8List? _frame;
  StreamSubscription<List<int>>? _sub;
  http.Client? _client;
  bool _hasError = false;
  String? _reason;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant MjpegView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _stop();
      _frame = null;
      _hasError = false;
      _reason = null;
      _start();
    }
  }

  Future<void> _start() async {
    final generation = ++_generation;
    final client = http.Client();
    _client = client;
    var pending = BytesBuilder(copy: false);
    try {
      final request = http.Request('GET', Uri.parse(widget.url));
      if (widget.headers != null) request.headers.addAll(widget.headers!);
      final response = await client.send(request);
      if (generation != _generation) {
        client.close();
        return; // replaced while connecting: this answer belongs to nobody
      }
      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _reason = 'HTTP ${response.statusCode}';
          });
        }
        client.close();
        return;
      }
      _sub = response.stream.listen(
        (chunk) {
          if (generation != _generation) return;
          pending.add(chunk);
          if (pending.length > mjpegMaxBufferBytes) {
            pending = BytesBuilder(copy: false); // never produced a frame end: start over
            return;
          }
          final bytes = pending.toBytes();
          final found = findLastJpegFrame(bytes);
          if (found == null) return;
          final frame = Uint8List.fromList(Uint8List.sublistView(bytes, found.start, found.end));
          pending = BytesBuilder(copy: false);
          if (found.end < bytes.length) pending.add(Uint8List.sublistView(bytes, found.end));
          if (mounted) {
            setState(() {
              _frame = frame;
              _hasError = false;
              _reason = null;
            });
          }
        },
        onError: (Object _) {
          if (mounted && generation == _generation) setState(() => _hasError = true);
        },
        onDone: () {
          if (mounted && generation == _generation) setState(() => _hasError = true);
        },
        cancelOnError: true,
      );
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _hasError = true);
    }
  }

  void _stop() {
    _generation++;
    _sub?.cancel();
    _sub = null;
    _client?.close();
    _client = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frame == null) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: _hasError
            ? Text(
                _reason == null ? l10n.cameraStreamUnavailable : l10n.errCameraUnavailable(_reason!),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              )
            : const CircularProgressIndicator(),
      );
    }
    return Image.memory(_frame!, gaplessPlayback: true, fit: BoxFit.contain);
  }
}
