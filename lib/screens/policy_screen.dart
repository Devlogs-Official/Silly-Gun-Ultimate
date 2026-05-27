import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import '../core/app_logger.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_typography.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  static const Duration _timeout = Duration(seconds: 20);

  List<_PolicyBlock>? _blocks;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await http.get(Uri.parse(widget.url)).timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Server returned ${response.statusCode}');
      }

      final blocks = _PolicyHtmlParser.parse(response.body);

      if (!mounted) return;
      setState(() {
        _blocks = blocks;
        _loading = false;
        _error = blocks.isEmpty ? 'No content available.' : null;
      });
    } on TimeoutException {
      _showError('The request timed out. Please try again.');
    } on SocketException {
      _showError('No internet connection. Please try again.');
    } on http.ClientException {
      _showError('Network error. Please try again.');
    } catch (error, stackTrace) {
      AppLogger.error('Policy fetch failed', error: error, stackTrace: stackTrace);
      _showError('Unable to load this page right now.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: Text(
          widget.title.toUpperCase(),
          style: AppText.button(color: AppColors.bone, size: 13),
        ),
      ),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const _PolicyShimmer();

    if (_error != null) {
      return _PolicyError(message: _error!, onRetry: _fetch);
    }

    final blocks = _blocks ?? const <_PolicyBlock>[];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 22, height: 2, color: AppColors.crimson),
                    const SizedBox(width: 10),
                    Text('LEGAL · DEVLOGS', style: AppText.eyebrow()),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.title.toUpperCase(),
                  style: AppText.display(
                    size: 44,
                    letterSpacing: 1.2,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: AppColors.hairline),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 60),
          sliver: SliverList.separated(
            itemCount: blocks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) =>
                _PolicyBlockView(block: blocks[index]),
          ),
        ),
      ],
    );
  }
}

class _PolicyBlockView extends StatelessWidget {
  const _PolicyBlockView({required this.block});

  final _PolicyBlock block;

  @override
  Widget build(BuildContext context) {
    switch (block.kind) {
      case _PolicyBlockKind.h1:
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(
            block.text.toUpperCase(),
            style: AppText.display(size: 30, letterSpacing: 1.2),
          ),
        );
      case _PolicyBlockKind.h2:
        return Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(width: 14, height: 2, color: AppColors.crimson),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  block.text.toUpperCase(),
                  style: AppText.headline(size: 18, color: AppColors.bone),
                ),
              ),
            ],
          ),
        );
      case _PolicyBlockKind.h3:
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            block.text,
            style: AppText.headline(size: 15, color: AppColors.bone),
          ),
        );
      case _PolicyBlockKind.paragraph:
        return Text(
          block.text,
          style: AppText.body(size: 14.5, height: 1.62),
        );
      case _PolicyBlockKind.bullet:
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 9, right: 12),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.crimson,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  block.text,
                  style: AppText.body(size: 14.5, height: 1.55),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _PolicyShimmer extends StatelessWidget {
  const _PolicyShimmer();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: AppColors.obsidian,
      highlightColor: AppColors.graphite,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 60),
        children: [
          bar(120, 11),
          const SizedBox(height: 14),
          bar(MediaQuery.sizeOf(context).width * 0.7, 38),
          const SizedBox(height: 8),
          bar(MediaQuery.sizeOf(context).width * 0.45, 38),
          const SizedBox(height: 22),
          bar(double.infinity, 14),
          const SizedBox(height: 8),
          bar(double.infinity, 14),
          const SizedBox(height: 8),
          bar(MediaQuery.sizeOf(context).width * 0.7, 14),
          const SizedBox(height: 26),
          bar(160, 18),
          const SizedBox(height: 14),
          bar(double.infinity, 14),
          const SizedBox(height: 8),
          bar(double.infinity, 14),
          const SizedBox(height: 8),
          bar(double.infinity, 14),
          const SizedBox(height: 8),
          bar(MediaQuery.sizeOf(context).width * 0.55, 14),
        ],
      ),
    );
  }
}

class _PolicyError extends StatelessWidget {
  const _PolicyError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.crimson,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'COULD NOT LOAD',
              textAlign: TextAlign.center,
              style: AppText.display(size: 26, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body(),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PolicyBlockKind { h1, h2, h3, paragraph, bullet }

class _PolicyBlock {
  const _PolicyBlock(this.kind, this.text);

  final _PolicyBlockKind kind;
  final String text;
}

class _PolicyHtmlParser {
  static final RegExp _scriptOrStyle = RegExp(
    r'<(script|style|noscript)[^>]*>[\s\S]*?</\1>',
    caseSensitive: false,
  );
  static final RegExp _commentRegex = RegExp(r'<!--[\s\S]*?-->');
  static final RegExp _headRegex = RegExp(
    r'<head[^>]*>[\s\S]*?</head>',
    caseSensitive: false,
  );
  static final RegExp _tagRegex = RegExp(r'<[^>]+>');
  static final RegExp _wsRegex = RegExp(r'[ \t ]+');

  static List<_PolicyBlock> parse(String html) {
    if (html.trim().isEmpty) return const [];

    var body = _extractBody(html);
    body = body
        .replaceAll(_scriptOrStyle, '')
        .replaceAll(_commentRegex, '');

    final blocks = <_PolicyBlock>[];

    final blockRegex = RegExp(
      r'<(h1|h2|h3|h4|h5|h6|p|li)([^>]*)>([\s\S]*?)</\1>',
      caseSensitive: false,
    );

    for (final match in blockRegex.allMatches(body)) {
      final tag = match.group(1)!.toLowerCase();
      final raw = match.group(3) ?? '';
      final text = _normalize(raw);
      if (text.isEmpty) continue;

      switch (tag) {
        case 'h1':
          blocks.add(_PolicyBlock(_PolicyBlockKind.h1, text));
          break;
        case 'h2':
          blocks.add(_PolicyBlock(_PolicyBlockKind.h2, text));
          break;
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          blocks.add(_PolicyBlock(_PolicyBlockKind.h3, text));
          break;
        case 'li':
          blocks.add(_PolicyBlock(_PolicyBlockKind.bullet, text));
          break;
        case 'p':
          blocks.add(_PolicyBlock(_PolicyBlockKind.paragraph, text));
          break;
      }
    }

    if (blocks.isNotEmpty) return blocks;

    final fallback = _normalize(body);
    if (fallback.isEmpty) return const [];
    return [_PolicyBlock(_PolicyBlockKind.paragraph, fallback)];
  }

  static String _extractBody(String html) {
    final lower = html.toLowerCase();
    final bodyStart = lower.indexOf('<body');
    if (bodyStart < 0) return html.replaceAll(_headRegex, '');
    final openEnd = lower.indexOf('>', bodyStart);
    final closeStart = lower.lastIndexOf('</body>');
    if (openEnd < 0) return html.replaceAll(_headRegex, '');
    final endIndex = closeStart > openEnd ? closeStart : html.length;
    return html.substring(openEnd + 1, endIndex);
  }

  static String _normalize(String raw) {
    var text = raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(_tagRegex, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', '\'')
        .replaceAll('&apos;', '\'')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&hellip;', '…')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&rsquo;', '’')
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&ldquo;', '“');

    text = text.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) {
        final code = int.tryParse(m.group(1) ?? '');
        if (code == null) return '';
        return String.fromCharCode(code);
      },
    );

    text = text.replaceAll(_wsRegex, ' ');
    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    return text.trim();
  }
}
