import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/repositrories/highlight/highlight_provider.dart';
import '../../../core/repositrories/link_providers/link_repository_provider.dart';
import '../../../core/services/reader_prefs.dart';
import '../../../data/models/Highlight/highlight_model.dart';
import '../../../theme/recallr_colors.dart';

class ReReader extends ConsumerStatefulWidget {
  final String url;
  final int? linkId;

  const ReReader({super.key, required this.url, this.linkId});

  @override
  ConsumerState<ReReader> createState() => _ReReaderState();
}

class _ReReaderState extends ConsumerState<ReReader> {
  late final WebViewController _ctrl;

  bool _loading    = true;
  bool _readerMode = false;
  String _pageTitle = '';

  OverlayEntry? _toolbarOverlay;
  String _pendingHighlightText = '';

  // CSS color string  →  swatch color int
  static const List<(String, int)> _highlightColors = [
    ('rgba(251,191,36,0.45)',  0xFFFBBF24),
    ('rgba(52,211,153,0.45)',  0xFF34D399),
    ('rgba(56,189,248,0.45)',  0xFF38BDF8),
    ('rgba(244,114,182,0.45)', 0xFFF472B6),
  ];

  // ── Selection-capture JavaScript ──────────────────────────────────────────
  // Listens on mouseup + selectionchange + touchend for reliable mobile capture.
  static const _selectionJs = r'''
(function() {
  window._savedRange = null;
  var _pendingHighlight = false;
  function tryCapture() {
    if (_pendingHighlight) return;
    var sel = window.getSelection();
    if (!sel || sel.isCollapsed) return;
    var text = sel.toString().trim();
    if (text.length < 3 || text.length > 500) return;
    _pendingHighlight = true;
    window._savedRange = sel.rangeCount > 0 ? sel.getRangeAt(0).cloneRange() : null;
    setTimeout(function() { _pendingHighlight = false; }, 1000);
    HighlightChannel.postMessage(JSON.stringify({ text: text }));
  }
  document.addEventListener('mouseup', tryCapture);
  document.addEventListener('selectionchange', function() {
    setTimeout(tryCapture, 150);
  });
  // touchend is the most reliable trigger on mobile long-press + drag
  document.addEventListener('touchend', function() {
    setTimeout(tryCapture, 300);
  });
})();
''';

  // ── Reader-mode JavaScript ─────────────────────────────────────────────────
  // Colors are injected at call time to match the user's current theme.
  static String _buildReaderJs(bool isDark) {
    final bg      = isDark ? '#0F172A' : '#F8FAFC';
    final text    = isDark ? '#E2E8F0' : '#1E293B';
    final heading = isDark ? '#F8FAFC' : '#0F172A';
    final sec     = isDark ? '#CBD5E1' : '#475569';
    final link    = isDark ? '#38BDF8' : '#0EA5E9';
    final codeBg  = isDark ? '#1E293B' : '#F1F5F9';
    final codeTxt = isDark ? '#38BDF8' : '#0369A1';
    final qtBdr   = isDark ? '#38BDF8' : '#0EA5E9';
    final qtTxt   = isDark ? '#94A3B8' : '#64748B';

    // JS template literal \${...} must be escaped in Dart non-raw strings.
    return """
(function() {
  try {
    const title = document.title || '';

    const selectors = [
      'article', '[role="main"]', 'main',
      '.post-content', '.article-body', '.entry-content',
      '.article-content', '.story-body', '.post-body',
      '#article-body', '.content-body', '.single-content',
    ];
    let content = null;
    for (const sel of selectors) {
      const el = document.querySelector(sel);
      if (el && el.innerText.length > 300) { content = el; break; }
    }
    if (!content) {
      let max = 0;
      document.querySelectorAll('div, section').forEach(el => {
        const len = el.innerText.length;
        if (len > max && len < 200000) { max = len; content = el; }
      });
    }
    if (!content) return;

    ['script','style','nav','header','footer','aside','form',
     '[class*="ad-"]','[id*="ad-"]','[class*="social"]',
     '[class*="share"]','[class*="comment"]','[class*="newsletter"]',
     '[class*="subscribe"]','[class*="popup"]','[class*="banner"]',
     '[class*="sticky"]','[class*="related"]',
    ].forEach(sel => {
      try { content.querySelectorAll(sel).forEach(e => e.remove()); } catch(_){}
    });

    document.body.innerHTML =
      '<div style="max-width:680px;margin:0 auto;padding:24px 20px 80px;'
      + 'font-family:-apple-system,Georgia,serif;font-size:18px;line-height:1.75;'
      + 'color:$text;background:$bg;">'
      + '<h1 style="font-size:24px;font-weight:700;margin-bottom:20px;'
      + 'line-height:1.3;color:$heading;">' + title + '</h1>'
      + content.innerHTML
      + '</div>';

    document.querySelectorAll('p,li,h1,h2,h3,h4,h5,h6,span')
      .forEach(el => { el.style.color = '$sec'; });
    document.querySelectorAll('a')
      .forEach(el => { el.style.color = '$link'; el.style.textDecoration = 'none'; });
    document.querySelectorAll('img')
      .forEach(el => { el.style.maxWidth='100%'; el.style.borderRadius='8px';
                       el.style.display='block'; el.style.margin='16px 0'; });
    document.querySelectorAll('pre,code')
      .forEach(el => { el.style.background='$codeBg'; el.style.color='$codeTxt';
                       el.style.padding='4px 8px'; el.style.borderRadius='4px';
                       el.style.fontSize='0.85em'; el.style.overflowX='auto'; });
    document.querySelectorAll('blockquote')
      .forEach(el => { el.style.borderLeft='3px solid $qtBdr';
                       el.style.margin='12px 0'; el.style.paddingLeft='16px';
                       el.style.color='$qtTxt'; });

    document.documentElement.style.background = '$bg';
    document.body.style.background = '$bg';
    document.body.style.margin = '0';
  } catch(e) { console.warn('ReaderMode:', e); }
})();
""";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final def = ref.read(readerModeDefaultProvider);
      if (def && !_readerMode) setState(() => _readerMode = true);
    });
    final uri = Uri.parse(
      widget.url.startsWith('http') ? widget.url : 'https://${widget.url}',
    );

    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (url) async {
          if (!mounted) return;
          final title = await _ctrl.getTitle();
          setState(() {
            _loading   = false;
            _pageTitle = title ?? _domainOf(url);
          });
          if (_readerMode) await _ctrl.runJavaScript(_buildReaderJs(context.isDark));
          await _ctrl.runJavaScript(_selectionJs);
          // Re-paint any previously saved highlights for this link
          await _reinjectSavedHighlights();
          if (widget.linkId != null) {
            ref.read(linkRepositoryProvider).updateLastOpened(widget.linkId!);
          }
        },
        onWebResourceError: (_) => setState(() => _loading = false),
        onNavigationRequest: (request) async {
          final appUri = Uri.tryParse(request.url);
          final scheme = appUri?.scheme ?? '';

          if (scheme == 'http' || scheme == 'https') {
            return NavigationDecision.navigate;
          }

          if (appUri != null) {
            try {
              await launchUrl(appUri, mode: LaunchMode.externalApplication);
            } catch (_) {
              // App not installed — for intent:// links, parse the fallback
              // https URL from the fragment and load it in the WebView.
              if (scheme == 'intent') {
                final fragment = appUri.fragment;
                final fallbackScheme =
                    RegExp(r'scheme=(\w+)').firstMatch(fragment)?.group(1) ??
                        'https';
                final fallbackUrl =
                    '$fallbackScheme://${appUri.host}${appUri.path}'
                    '${appUri.hasQuery ? '?${appUri.query}' : ''}';
                final fallback = Uri.tryParse(fallbackUrl);
                if (fallback != null) {
                  await _ctrl.loadRequest(fallback);
                }
              }
              // For other non-http schemes (mailto:, tel:, etc.) silently ignore.
            }
          }
          return NavigationDecision.prevent;
        },
      ))
      ..addJavaScriptChannel(
        'HighlightChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            final text = data['text'] as String? ?? '';
            if (text.isEmpty) return;
            _showHighlightToolbar(text);
          } catch (_) {
            // Malformed message from JS — ignore silently
          }
        },
      )
      ..loadRequest(uri);
  }

  @override
  void dispose() {
    _removeHighlightToolbar();
    super.dispose();
  }

  String _domainOf(String url) {
    return Uri.tryParse(url)?.host.replaceAll('www.', '') ?? url;
  }

  Future<void> _toggleReaderMode() async {
    final next = !_readerMode;
    setState(() => _readerMode = next);
    if (next) {
      await _ctrl.runJavaScript(_buildReaderJs(context.isDark));
    } else {
      await _ctrl.reload();
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(
      widget.url.startsWith('http') ? widget.url : 'https://${widget.url}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Highlight persistence ─────────────────────────────────────────────────

  /// Re-injects <mark> elements for every saved highlight after page load.
  Future<void> _reinjectSavedHighlights() async {
    if (widget.linkId == null) return;
    final highlights =
        await ref.read(highlightRepositoryProvider).getByLinkId(widget.linkId!);
    if (highlights.isEmpty) return;

    final payload = jsonEncode(highlights
        .map((h) => {
              'text': h.text,
              'color': h.colorHex ?? 'rgba(251,191,36,0.45)',
            })
        .toList());

    // TreeWalker-based text search — skips script/style/already-marked nodes
    await _ctrl.runJavaScript(
      '(function(list){'
      '  list.forEach(function(h){'
      '    var walker=document.createTreeWalker('
      '      document.body,'
      '      NodeFilter.SHOW_TEXT,'
      '      {acceptNode:function(n){'
      '        var tag=(n.parentNode&&n.parentNode.tagName||"").toLowerCase();'
      '        return(tag==="script"||tag==="style"||tag==="mark")'
      '          ?NodeFilter.FILTER_REJECT:NodeFilter.FILTER_ACCEPT;'
      '      }},'
      '      false'
      '    );'
      '    var node;'
      '    while((node=walker.nextNode())){'
      '      var idx=node.nodeValue.indexOf(h.text);'
      '      if(idx===-1)continue;'
      '      var range=document.createRange();'
      '      range.setStart(node,idx);'
      '      range.setEnd(node,idx+h.text.length);'
      '      var mark=document.createElement("mark");'
      '      mark.setAttribute("data-recallr","1");'
      '      mark.style.cssText="background:"+h.color+";border-radius:2px;padding:0 1px;";'
      '      try{range.surroundContents(mark);}catch(e){}'
      '      break;'
      '    }'
      '  });'
      '})($payload)',
    );
  }

  // ── Highlight toolbar ─────────────────────────────────────────────────────

  void _showHighlightToolbar(String selectedText) {
    if (!mounted) return;
    _removeHighlightToolbar();
    _pendingHighlightText = selectedText;
    final safePadding = MediaQuery.of(context).padding.bottom;
    final overlay = Overlay.of(context);
    _toolbarOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removeHighlightToolbar,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            bottom: safePadding + 80,
            left: 32,
            right: 32,
            child: GestureDetector(
              onTap: () {},
              child: _HighlightToolbar(
                colors: _highlightColors,
                onColor: (cssColor) => _applyHighlight(cssColor, null),
                onNote: _promptNote,
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_toolbarOverlay!);
  }

  void _removeHighlightToolbar() {
    _toolbarOverlay?.remove();
    _toolbarOverlay = null;
  }

  Future<void> _applyHighlight(String cssColor, String? note) async {
    _removeHighlightToolbar();
    await _ctrl.runJavaScript(
      '(function(color){'
      '  var range=window._savedRange;'
      '  if(!range)return;'
      '  var mark=document.createElement("mark");'
      '  mark.setAttribute("data-recallr","1");'
      '  mark.style.cssText="background:"+color+";border-radius:2px;padding:0 1px;";'
      '  try{range.surroundContents(mark);}'
      '  catch(e){'
      '    var frag=range.extractContents();'
      '    mark.appendChild(frag);'
      '    range.insertNode(mark);'
      '  }'
      '  window.getSelection().removeAllRanges();'
      '  window._savedRange=null;'
      "})('$cssColor')",
    );
    if (widget.linkId != null) {
      final highlight = HighlightModel()
        ..linkId = widget.linkId!
        ..text = _pendingHighlightText
        ..colorHex = cssColor
        ..note = note;
      await ref.read(highlightRepositoryProvider).saveHighlight(highlight);
    }
  }

  Future<void> _promptNote() async {
    _removeHighlightToolbar();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => _NoteDialog(colors: _highlightColors),
    );
    if (result != null && mounted) {
      final (cssColor, noteText) = result;
      await _applyHighlight(cssColor, noteText.isEmpty ? null : noteText);
    }
  }

  // ── View saved highlights ─────────────────────────────────────────────────

  Future<void> _viewHighlights() async {
    if (widget.linkId == null || !mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.65,
        child: _HighlightsSheet(linkId: widget.linkId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          ReaderTopBar(
            title:            _pageTitle.isEmpty ? _domainOf(widget.url) : _pageTitle,
            loading:          _loading,
            readerMode:       _readerMode,
            c:                c,
            onBack:           () => Navigator.of(context).pop(),
            onToggleReader:   _toggleReaderMode,
            onOpenExternal:   _openExternal,
            onViewHighlights: _viewHighlights,
          ),
          if (_loading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: c.border,
              color: c.accent,
            ),
          Expanded(child: WebViewWidget(controller: _ctrl)),
        ],
      ),
    );
  }
}

// ── Highlight toolbar overlay ─────────────────────────────────────────────────

class _HighlightToolbar extends StatelessWidget {
  const _HighlightToolbar({
    required this.colors,
    required this.onColor,
    required this.onNote,
  });

  final List<(String, int)> colors;
  final void Function(String cssColor) onColor;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (cssColor, colorInt) in colors)
                GestureDetector(
                  onTap: () => onColor(cssColor),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Color(colorInt),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(colorInt).withValues(alpha: 0.45),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Container(width: 1, height: 24, color: const Color(0xFF334155)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onNote,
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Note + colour picker dialog ───────────────────────────────────────────────

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.colors});
  final List<(String, int)> colors;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _noteCtrl = TextEditingController();
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.colors.first.$1;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text('Add note', style: TextStyle(color: Color(0xFFF8FAFC))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _noteCtrl,
            autofocus: true,
            maxLines: 3,
            style: const TextStyle(color: Color(0xFFE2E8F0)),
            decoration: const InputDecoration(
              hintText: 'Note…',
              hintStyle: TextStyle(color: Color(0xFF64748B)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF38BDF8)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (cssColor, colorInt) in widget.colors)
                GestureDetector(
                  onTap: () => setState(() => _selectedColor = cssColor),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Color(colorInt),
                      shape: BoxShape.circle,
                      border: _selectedColor == cssColor
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                      boxShadow: _selectedColor == cssColor
                          ? [
                              BoxShadow(
                                color: Color(colorInt).withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            (_selectedColor, _noteCtrl.text.trim()),
          ),
          child: const Text('Save', style: TextStyle(color: Color(0xFF38BDF8))),
        ),
      ],
    );
  }
}

// ── Highlights bottom sheet ───────────────────────────────────────────────────

class _HighlightsSheet extends ConsumerStatefulWidget {
  const _HighlightsSheet({required this.linkId});
  final int linkId;

  @override
  ConsumerState<_HighlightsSheet> createState() => _HighlightsSheetState();
}

class _HighlightsSheetState extends ConsumerState<_HighlightsSheet> {
  List<HighlightModel> _highlights = [];
  StreamSubscription<List<HighlightModel>>? _highlightSub;

  // ordered color groups
  static const _colorOrder = [
    'rgba(251,191,36,0.45)',
    'rgba(52,211,153,0.45)',
    'rgba(56,189,248,0.45)',
    'rgba(244,114,182,0.45)',
  ];
  static const _colorMeta = {
    'rgba(251,191,36,0.45)': ('Yellow', 0xFFFBBF24),
    'rgba(52,211,153,0.45)': ('Green',  0xFF34D399),
    'rgba(56,189,248,0.45)': ('Blue',   0xFF38BDF8),
    'rgba(244,114,182,0.45)': ('Pink',  0xFFF472B6),
  };

  @override
  void initState() {
    super.initState();
    _highlightSub = ref
        .read(highlightRepositoryProvider)
        .watchByLinkId(widget.linkId)
        .listen((list) {
      if (mounted) setState(() => _highlights = list);
    });
  }

  @override
  void dispose() {
    _highlightSub?.cancel();
    super.dispose();
  }

  Future<void> _delete(HighlightModel h) async {
    // Optimistic removal for smooth Dismissible animation
    setState(() => _highlights.removeWhere((x) => x.id == h.id));
    await ref.read(highlightRepositoryProvider).deleteHighlight(h.id);
  }

  @override
  Widget build(BuildContext context) {
    // Group by color in defined order
    final grouped = <String, List<HighlightModel>>{};
    for (final h in _highlights) {
      grouped.putIfAbsent(h.colorHex ?? _colorOrder.first, () => []).add(h);
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.format_color_text, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 8),
              Text(
                'Highlights (${_highlights.length})',
                style: const TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_highlights.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'No highlights yet.\nLong-press text in the article to highlight.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                for (final cssColor in _colorOrder) ...[
                  if (grouped.containsKey(cssColor)) ...[
                    // Color group header
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Color(_colorMeta[cssColor]!.$2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            _colorMeta[cssColor]!.$1,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final h in grouped[cssColor]!) ...[
                      Dismissible(
                        key: ValueKey(h.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 22),
                        ),
                        onDismissed: (_) => _delete(h),
                        child: _HighlightTile(h: h),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.h});
  final HighlightModel h;

  Color _swatchColor() {
    final css = h.colorHex ?? '';
    final m = RegExp(r'rgba\((\d+),(\d+),(\d+)').firstMatch(css);
    if (m == null) return const Color(0xFFFBBF24);
    return Color.fromARGB(
      255,
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _swatchColor();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            h.text,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (h.note != null && h.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sticky_note_2_outlined,
                    size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    h.note!,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

/// Public (unlike its sibling private widgets in this file) so golden tests
/// can render the reader's chrome without needing a real `WebViewController`
/// — see `test/golden/re_reader_golden_test.dart`.
class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.title,
    required this.loading,
    required this.readerMode,
    required this.c,
    required this.onBack,
    required this.onToggleReader,
    required this.onOpenExternal,
    required this.onViewHighlights,
  });

  final String title;
  final bool loading;
  final bool readerMode;
  final AppColorScheme c;
  final VoidCallback onBack;
  final VoidCallback onToggleReader;
  final VoidCallback onOpenExternal;
  final VoidCallback onViewHighlights;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.border, width: 0.5)),
        ),
        child: Row(
          children: [
            _BarBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack, c: c),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily:  'SpaceGrotesk',
                  fontSize:    13,
                  fontWeight:  FontWeight.w600,
                  color:       c.textPrimary,
                  overflow:    TextOverflow.ellipsis,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
            _BarBtn(
              icon:   Icons.format_color_text,
              onTap:  onViewHighlights,
              c:      c,
              active: true,
            ),
            _BarBtn(
              icon:   Icons.article_rounded,
              onTap:  onToggleReader,
              c:      c,
              active: readerMode,
            ),
            _BarBtn(icon: Icons.open_in_new_rounded, onTap: onOpenExternal, c: c),
          ],
        ),
      ),
    );
  }
}

class _BarBtn extends StatelessWidget {
  const _BarBtn({
    required this.icon,
    required this.onTap,
    required this.c,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final AppColorScheme c;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: active
            ? BoxDecoration(
                color:        AppColors.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        child: Icon(
          icon,
          size:  20,
          color: active ? AppColors.cyan : c.textSecondary,
        ),
      ),
    );
  }
}
