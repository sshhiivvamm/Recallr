typedef CategoryMeta = ({String icon, String color});

/// Suggests a tag name based on the URL's domain.
/// Returns null if no confident match is found.
class AutoCategorizer {
  AutoCategorizer._();

  static const _meta = <String, CategoryMeta>{
    'Videos':   (icon: 'video',   color: '#EF4444'),
    'Dev':      (icon: 'code',    color: '#06B6D4'),
    'Design':   (icon: 'design',  color: '#8B5CF6'),
    'Articles': (icon: 'article', color: '#F59E0B'),
    'Social':   (icon: 'social',  color: '#EC4899'),
    'Tools':    (icon: 'tool',    color: '#10B981'),
    'Learning': (icon: 'study',   color: '#3B82F6'),
  };

  static CategoryMeta? metadata(String categoryName) => _meta[categoryName];

  static String? suggest(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';

    if (_any(host, ['youtube.com', 'youtu.be', 'vimeo.com', 'twitch.tv', 'dailymotion.com'])) {
      return 'Videos';
    }
    if (_any(host, ['github.com', 'gitlab.com', 'stackoverflow.com', 'dev.to',
        'hackernews.com', 'news.ycombinator.com', 'npmjs.com', 'pub.dev'])) {
      return 'Dev';
    }
    if (_any(host, ['figma.com', 'dribbble.com', 'behance.net', 'awwwards.com',
        'mobbin.com', 'designspiration.com'])) {
      return 'Design';
    }
    if (_any(host, ['medium.com', 'substack.com', 'hashnode.dev', 'dev.to',
        'notion.so', 'readwise.io', 'instapaper.com'])) {
      return 'Articles';
    }
    if (_any(host, ['twitter.com', 'x.com', 'instagram.com', 'linkedin.com',
        'threads.net', 'reddit.com', 'facebook.com'])) {
      return 'Social';
    }
    if (_any(host, ['producthunt.com', 'alternativeto.net', 'toolbox.com',
        'gumroad.com', 'paddle.com'])) {
      return 'Tools';
    }
    if (_any(host, ['udemy.com', 'coursera.org', 'edx.org', 'khanacademy.org',
        'freecodecamp.org', 'pluralsight.com', 'egghead.io'])) {
      return 'Learning';
    }

    return null;
  }

  static bool _any(String host, List<String> domains) =>
      domains.any((d) => host.contains(d));
}
