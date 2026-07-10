class LayoutRegistry {
  static const fallback = 'layout_06';
  static const supported = <String>{
    'layout_02',
    'layout_03',
    'layout_04',
    'layout_05',
    'layout_06'
  };

  static String normalize(String? layout) =>
      supported.contains(layout) ? layout! : fallback;
}
