import '../Tag/tag_model.dart';
import '../collection_model.dart';

class LinkSearchParams {
  final String? query;
  final TagModel? tag;
  final FolderModel? folder;
  final bool? isFavorite;
  final bool? isRead;
  final LinkSort sort;

  LinkSearchParams({
    this.query,
    this.tag,
    this.folder,
    this.isFavorite,
    this.isRead,
    this.sort = LinkSort.newest,
  });

  static const Object _sentinel = Object();

  LinkSearchParams copyWith({
    Object? query = _sentinel,
    Object? tag = _sentinel,
    Object? folder = _sentinel,
    Object? isFavorite = _sentinel,
    Object? isRead = _sentinel,
    LinkSort? sort,
  }) {
    return LinkSearchParams(
      query: query == _sentinel ? this.query : query as String?,
      tag: tag == _sentinel ? this.tag : tag as TagModel?,
      folder: folder == _sentinel ? this.folder : folder as FolderModel?,
      isFavorite: isFavorite == _sentinel
          ? this.isFavorite
          : isFavorite as bool?,
      isRead: isRead == _sentinel ? this.isRead : isRead as bool?,
      sort: sort ?? this.sort,
    );
  }
}

enum LinkSort { newest, oldest, lastOpened }
