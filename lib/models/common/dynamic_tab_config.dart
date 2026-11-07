class DynamicTabConfig {
  static const ids = ['all', 'video', 'pgc', 'article', 'up'];
  static const labels = {
    'all': '全部',
    'video': '投稿',
    'pgc': '番剧',
    'article': '专栏',
    'up': 'Up'
  };
  static List<String> normalize(dynamic value) {
    if (value is! List) return List.of(ids);
    final result =
        value.whereType<String>().where(ids.contains).toSet().toList();
    return result;
  }

  static String defaultId(dynamic value, dynamic legacy, List<String> visible) {
    final id = value is String
        ? value
        : legacy is int && legacy >= 0 && legacy < ids.length
            ? ids[legacy]
            : 'all';
    if (visible.isEmpty) return ids.contains(id) ? id : 'all';
    return visible.contains(id) ? id : visible.first;
  }
}
