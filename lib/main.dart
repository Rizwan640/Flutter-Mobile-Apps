import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const AurixApp());

class AurixApp extends StatelessWidget {
  const AurixApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF090A0C);
    return MaterialApp(
      title: 'AURIX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8E8E8),
          secondary: Color(0xFF9CA3AF),
          surface: Color(0xFF15171B),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AurixHomePage(),
    );
  }
}

class AurixHomePage extends StatefulWidget {
  const AurixHomePage({super.key});

  @override
  State<AurixHomePage> createState() => _AurixHomePageState();
}

class _AurixHomePageState extends State<AurixHomePage> {
  static const _modelUrl =
      'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q3_k_m.gguf';
  static const _modelName = 'qwen2.5-0.5b-instruct-q3_k_m.gguf';
  static const _expectedBytes = 432 * 1024 * 1024;

  final LlamaController _llama = LlamaController();
  final TextEditingController _promptController = TextEditingController();
  final List<_ChatLine> _messages = [];
  bool _modelPresent = false;
  bool _modelReady = false;
  bool _busy = false;
  bool _generating = false;
  double _downloadProgress = 0;
  double _modelLoadProgress = 0;
  String _status = 'MODEL NOT DOWNLOADED';
  int? _availableRamMb;
  StreamSubscription<double>? _modelLoadSubscription;
  String? _error;
  StreamSubscription<String>? _generationSubscription;

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  Future<File> _modelFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/$_modelName');
  }

  Future<void> _checkModel() async {
    try {
      final file = await _modelFile();
      final exists = await file.exists() && await file.length() > 300 * 1024 * 1024;
      if (!mounted) return;
      setState(() {
        _modelPresent = exists;
        _status = exists ? 'MODEL DOWNLOADED • READY TO LOAD' : 'MODEL NOT DOWNLOADED';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Storage check failed: $error');
    }
  }

  Future<void> _downloadAndLoad() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _downloadProgress = 0;
      _status = 'DOWNLOADING MODEL';
    });

    try {
      final file = await _modelFile();
      final partial = File('${file.path}.part');
      if (await partial.exists()) await partial.delete();

      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(_modelUrl));
        request.headers['User-Agent'] = 'AURIX-Android/1.0';
        final response = await client.send(request).timeout(const Duration(minutes: 2));
        if (response.statusCode != 200) {
          throw HttpException('Model server returned HTTP ${response.statusCode}');
        }

        final total = response.contentLength ?? _expectedBytes;
        var received = 0;
        final sink = partial.openWrite();
        try {
          await for (final chunk in response.stream) {
            sink.add(chunk);
            received += chunk.length;
            if (mounted && total > 0) {
              setState(() => _downloadProgress = (received / total).clamp(0.0, 1.0));
            }
          }
        } finally {
          await sink.flush();
          await sink.close();
        }

        if (received < 300 * 1024 * 1024) {
          throw const FormatException('Downloaded model is incomplete. Please retry.');
        }
        if (await file.exists()) await file.delete();
        await partial.rename(file.path);
      } finally {
        client.close();
      }

      if (!mounted) return;
      setState(() {
        _modelPresent = true;
        _status = 'DOWNLOAD COMPLETE • LOADING AI';
      });
      await _loadModel(file.path);
    } catch (error) {
      final file = await _modelFile();
      final partial = File('${file.path}.part');
      if (await partial.exists()) await partial.delete();
      if (mounted) {
        setState(() {
          _error = 'Setup failed: $error';
          _status = 'SETUP NEEDS ATTENTION';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadModel([String? knownPath]) async {
    if (_busy && knownPath == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _status = 'CHECKING MEMORY • PREPARING LOCAL AI';
      _modelLoadProgress = 0;
    });
    try {
      final file = knownPath == null ? await _modelFile() : File(knownPath);
      if (!await file.exists()) {
        throw StateError('Model file not found. Download it first.');
      }
      // Check available system memory before entering native llama.cpp code.
      // A low-memory native allocation can terminate Android without a Dart exception.
      final gpuInfo = await _llama.detectGpu();
      final freeRamMb = gpuInfo.freeRamBytes ~/ (1024 * 1024);
      if (mounted) setState(() => _availableRamMb = freeRamMb);
      if (freeRamMb < 800) {
        throw StateError(
          'Only $freeRamMb MB RAM is currently free. Close other apps, restart the phone, and try again when at least 800 MB is free.',
        );
      }

      // Keep the first load conservative for a 4 GB phone.
      _modelLoadSubscription?.cancel();
      _modelLoadSubscription = _llama.loadProgress.listen((progress) {
        if (!mounted) return;
        setState(() => _modelLoadProgress = progress.clamp(0.0, 1.0));
      });
      await _llama.loadModel(
        modelPath: file.path,
        threads: 2,
        contextSize: 512,
        gpuLayers: 0,
      );
      if (!mounted) return;
      setState(() {
        _modelReady = true;
        _modelPresent = true;
        _status = 'LOCAL AI ONLINE';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _modelReady = false;
          _error = 'Could not load model: $error';
          _status = 'MODEL LOAD FAILED';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendMessage() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || !_modelReady || _generating) return;

    _promptController.clear();
    setState(() {
      _messages.add(_ChatLine(prompt, true));
      _messages.add(_ChatLine('', false));
      _generating = true;
      _error = null;
    });

    final previousMessages = _messages.sublist(0, _messages.length - 2);
    final history = previousMessages.length > 8
        ? previousMessages.sublist(previousMessages.length - 8)
        : previousMessages;
    final chat = <ChatMessage>[
      ChatMessage(
        role: 'system',
        content: 'You are AURIX, a helpful personal assistant. Reply naturally in the same language as the user. The user may speak Hindi, Hinglish, or English. Keep answers clear and concise. You are running offline and must not claim to access the internet.',
      ),
      ...history.map((line) => ChatMessage(
            role: line.isUser ? 'user' : 'assistant',
            content: line.text,
          )),
      ChatMessage(role: 'user', content: prompt),
    ];

    final answerIndex = _messages.length - 1;
    try {
      _generationSubscription = _llama
          .generateChat(
            messages: chat,
            template: 'chatml',
            maxTokens: 180,
            temperature: 0.65,
            topP: 0.9,
          )
          .listen(
        (token) {
          if (!mounted) return;
          setState(() => _messages[answerIndex].text += token);
        },
        onError: (Object error) {
          if (mounted) setState(() => _error = 'AI response error: $error');
        },
        onDone: () {
          if (mounted) setState(() => _generating = false);
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = 'Could not generate response: $error';
        });
      }
    }
  }

  Future<void> _stopGeneration() async {
    await _llama.stop();
    await _generationSubscription?.cancel();
    if (mounted) setState(() => _generating = false);
  }

  @override
  void dispose() {
    _generationSubscription?.cancel();
    _modelLoadSubscription?.cancel();
    _llama.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _BrandMark(),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AURIX', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 3.2)),
                      SizedBox(height: 3),
                      Text('PERSONAL AI', style: TextStyle(color: Color(0xFF858991), fontSize: 9, letterSpacing: 2.4)),
                    ],
                  ),
                  const Spacer(),
                  _StatusPill(ready: _modelReady),
                ],
              ),
              const SizedBox(height: 28),
              const Center(child: _AurixOrb()),
              const SizedBox(height: 28),
              const Center(
                child: Column(
                  children: [
                    Text('Hello, Rizwan.', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w500, letterSpacing: -0.8)),
                    SizedBox(height: 8),
                    Text('Your private AI assistant.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF92969E), fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFF141619),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF292D32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.memory_rounded, size: 18, color: Color(0xFFD6D8DC)),
                        SizedBox(width: 9),
                        Text('LOCAL AI ENGINE', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_status, style: const TextStyle(fontSize: 10, letterSpacing: 1.1, color: Color(0xFFD0C1A2))),
                    const SizedBox(height: 10),
                    const Text(
                      'Qwen2.5 0.5B Instruct • GGUF Q3_K_M\nApprox. 432 MB • Stored on this phone',
                      style: TextStyle(height: 1.5, fontSize: 12, color: Color(0xFF9A9EA6)),
                    ),
                    if (_busy && _downloadProgress > 0 && !_modelPresent) ...[
                      const SizedBox(height: 14),
                      LinearProgressIndicator(value: _downloadProgress, minHeight: 5, borderRadius: BorderRadius.circular(8)),
                      const SizedBox(height: 7),
                      Text('${(_downloadProgress * 100).toStringAsFixed(1)}% downloaded', style: const TextStyle(fontSize: 11, color: Color(0xFFB9BEC7))),
                    ],
                    if (_busy && _modelPresent && _status.contains('LOCAL AI')) ...[
                      const SizedBox(height: 14),
                      LinearProgressIndicator(value: _modelLoadProgress > 0 ? _modelLoadProgress : null, minHeight: 5, borderRadius: BorderRadius.circular(8)),
                      const SizedBox(height: 7),
                      Text(
                        _availableRamMb == null ? 'Checking available memory...' : 'Free RAM: $_availableRamMb MB • Loading with low-memory settings',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFB9BEC7)),
                      ),
                    ],
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : (_modelPresent ? () => _loadModel() : _downloadAndLoad),
                        icon: Icon(_modelReady ? Icons.check_circle_outline : (_modelPresent ? Icons.play_arrow_rounded : Icons.download_rounded), size: 18),
                        label: Text(
                          _modelReady ? 'AI ENGINE READY' : (_modelPresent ? 'LOAD LOCAL AI MODEL' : 'DOWNLOAD LOCAL AI MODEL'),
                          style: const TextStyle(letterSpacing: 1.1, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE3E5E8),
                          side: const BorderSide(color: Color(0xFF454A52)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: Color(0xFFE5A5A5), fontSize: 11)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (_modelReady) ...[
                const Text('TALK TO AURIX', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_messages.isEmpty)
                  const Text('Model is running on your phone. Ask your first question.', style: TextStyle(color: Color(0xFF92969E), fontSize: 13)),
                ..._messages.map((line) => _MessageBubble(line: line)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Message AURIX...',
                          filled: true,
                          fillColor: const Color(0xFF141619),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF343941))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF343941))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _generating ? _stopGeneration : _sendMessage,
                      icon: Icon(_generating ? Icons.stop_rounded : Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ] else
                const Center(child: Text('Download the model once. After setup, chat works offline.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF777D86), fontSize: 11))),
              const SizedBox(height: 24),
              const Center(
                child: Text('PRIVATE BY DESIGN  •  ON-DEVICE INFERENCE', style: TextStyle(color: Color(0xFF686D75), fontSize: 9, letterSpacing: 1.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatLine {
  _ChatLine(this.text, this.isUser);
  String text;
  final bool isUser;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.line});
  final _ChatLine line;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: line.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: line.isUser ? const Color(0xFF343941) : const Color(0xFF171A1F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(line.text.isEmpty && !line.isUser ? 'Thinking...' : line.text, style: const TextStyle(fontSize: 13, height: 1.45)),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.ready});
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFF171A1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF292D33))),
      child: Row(
        children: [
          Icon(Icons.circle, size: 7, color: ready ? const Color(0xFF9BC7A3) : const Color(0xFFB9A987)),
          const SizedBox(width: 7),
          Text(ready ? 'AI READY' : 'OFFLINE', style: const TextStyle(fontSize: 9, letterSpacing: 1.1, color: Color(0xFFD4D8D4))),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: const Color(0xFFE7E9EC), borderRadius: BorderRadius.circular(14)),
      child: const Icon(Icons.bubble_chart_rounded, color: Color(0xFF101216), size: 26),
    );
  }
}

class _AurixOrb extends StatelessWidget {
  const _AurixOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 174,
      height: 174,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF656B74), Color(0xFF343941), Color(0xFF171A1F), Color(0xFF0B0C0E)],
          stops: [0, 0.38, 0.72, 1],
        ),
        border: Border.all(color: const Color(0xFF444A53)),
        boxShadow: const [BoxShadow(color: Color(0x332B3038), blurRadius: 42, spreadRadius: 7)],
      ),
      child: Center(
        child: Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(colors: [Color(0xFFF1F2F4), Color(0xFF9DA3AC), Color(0xFF515862)]),
            boxShadow: [BoxShadow(color: const Color(0xFFB9C0CA).withValues(alpha: 0.22), blurRadius: 30, spreadRadius: 4)],
          ),
          child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF171A1F), size: 38),
        ),
      ),
    );
  }
}
