///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsJaJp extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsJaJp({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.jaJp,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja-JP>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsJaJp _root = this; // ignore: unused_field

	@override 
	TranslationsJaJp $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsJaJp(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$ja_JP app = _Translations$app$ja_JP._(_root);
	@override late final _Translations$navigation$ja_JP navigation = _Translations$navigation$ja_JP._(_root);
	@override late final _Translations$common$ja_JP common = _Translations$common$ja_JP._(_root);
	@override late final _Translations$refresh$ja_JP refresh = _Translations$refresh$ja_JP._(_root);
	@override late final _Translations$toast$ja_JP toast = _Translations$toast$ja_JP._(_root);
	@override late final _Translations$login$ja_JP login = _Translations$login$ja_JP._(_root);
	@override late final _Translations$settings$ja_JP settings = _Translations$settings$ja_JP._(_root);
	@override late final _Translations$me$ja_JP me = _Translations$me$ja_JP._(_root);
	@override late final _Translations$home$ja_JP home = _Translations$home$ja_JP._(_root);
	@override late final _Translations$ranking$ja_JP ranking = _Translations$ranking$ja_JP._(_root);
	@override late final _Translations$search$ja_JP search = _Translations$search$ja_JP._(_root);
	@override late final _Translations$user$ja_JP user = _Translations$user$ja_JP._(_root);
	@override late final _Translations$newest$ja_JP newest = _Translations$newest$ja_JP._(_root);
	@override late final _Translations$illust$ja_JP illust = _Translations$illust$ja_JP._(_root);
	@override late final _Translations$novel$ja_JP novel = _Translations$novel$ja_JP._(_root);
	@override late final _Translations$follow$ja_JP follow = _Translations$follow$ja_JP._(_root);
	@override late final _Translations$richText$ja_JP richText = _Translations$richText$ja_JP._(_root);
}

// Path: app
class _Translations$app$ja_JP extends Translations$app$en_US {
	_Translations$app$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get title => 'freepiv';
}

// Path: navigation
class _Translations$navigation$ja_JP extends Translations$navigation$en_US {
	_Translations$navigation$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get home => 'ホーム';
	@override String get search => '検索';
	@override String get newest => '最新';
	@override String get ranking => 'ランキング';
	@override String get me => '自分';
	@override String get settings => '設定';
}

// Path: common
class _Translations$common$ja_JP extends Translations$common$en_US {
	_Translations$common$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get back => '戻る';
	@override String get cancel => 'キャンセル';
	@override String get retry => '再試行';
	@override String get send => '送信';
	@override String get filter => '絞り込み';
	@override String get type => '種類';
	@override String get id => 'ID';
	@override String get error => 'エラー';
	@override String get notFound => '見つかりません';
	@override String copy({required Object label}) => '${label}をコピー';
	@override String labelValue({required Object label, required Object value}) => '${label}：${value}';
	@override String errorWithCause({required Object message, required Object cause}) => '${message}：${cause}';
}

// Path: refresh
class _Translations$refresh$ja_JP extends Translations$refresh$en_US {
	_Translations$refresh$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get pullToRefresh => '引っ張って更新';
	@override String get releaseToRefresh => '離して更新';
	@override String get refreshing => '更新中';
	@override String get refreshComplete => '更新しました';
	@override String get refreshFailed => '更新に失敗しました';
	@override String get pullToLoadMore => '引っ張ってさらに読み込む';
	@override String get releaseToLoad => '離して読み込む';
	@override String get loading => '読み込み中';
	@override String get loadComplete => '読み込みました';
	@override String get noMoreItems => 'これ以上ありません';
	@override String get loadFailed => '読み込みに失敗しました';
	@override String get lastUpdated => '最終更新 %T';
}

// Path: toast
class _Translations$toast$ja_JP extends Translations$toast$en_US {
	_Translations$toast$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get bookmarkFailed => 'ブックマークに失敗しました';
	@override String get followFailed => 'フォローに失敗しました';
}

// Path: login
class _Translations$login$ja_JP extends Translations$login$en_US {
	_Translations$login$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get title => 'ログイン';
	@override String get notSignedIn => 'Pixiv にログインしていません';
	@override String signedInAs({required Object name}) => '${name} としてログイン中';
	@override String get signInToPixiv => 'Pixiv にログイン';
	@override String get signInAgain => '再ログイン';
	@override String get openingBrowser => 'ブラウザを開いています…';
	@override String get apiNotInitialized => 'Pixiv API が初期化されていません。';
	@override String get desktopOnly => 'システムブラウザでのログインは現在 Linux、macOS、Windows のみ対応しています。';
	@override String get openedInBrowser => 'システムブラウザで Pixiv ログインを開きました。ログイン後にアプリへ戻ってください。';
	@override String callbackMissingCode({required Object uri}) => 'Pixiv コールバックに code がありません：${uri}';
	@override String get callbackReceived => 'Pixiv コールバックを受信しました。トークンを取得しています。';
	@override String get browserOpenUnsupported => 'この環境ではシステムブラウザを開く処理が実装されていません。';
	@override String browserOpenFailed({required Object browser, required Object output}) => '${browser} でログインリンクを開けませんでした：${output}';
}

// Path: settings
class _Translations$settings$ja_JP extends Translations$settings$en_US {
	_Translations$settings$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$theme$ja_JP theme = _Translations$settings$theme$ja_JP._(_root);
	@override late final _Translations$settings$language$ja_JP language = _Translations$settings$language$ja_JP._(_root);
	@override late final _Translations$settings$images$ja_JP images = _Translations$settings$images$ja_JP._(_root);
	@override late final _Translations$settings$downloads$ja_JP downloads = _Translations$settings$downloads$ja_JP._(_root);
	@override late final _Translations$settings$account$ja_JP account = _Translations$settings$account$ja_JP._(_root);
}

// Path: me
class _Translations$me$ja_JP extends Translations$me$en_US {
	_Translations$me$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get openProfile => 'プロフィールを開く';
	@override String get following => 'フォロー中';
	@override String get followers => 'フォロワー';
	@override String get emptyFollowing => 'フォロー中のユーザーはいません';
	@override String get emptyFollowers => 'フォロワーはいません';
	@override String get settings => '設定';
	@override String get settingsSubtitle => 'テーマ、言語、画像、ダウンロード';
}

// Path: home
class _Translations$home$ja_JP extends Translations$home$en_US {
	_Translations$home$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get emptyTitle => 'おすすめはまだありません';
	@override String get emptyMessage => '下に引っ張るとおすすめを再取得できます。';
	@override String get rankings => 'ランキング';
	@override String get seeMore => 'もっと見る';
	@override String get recommended => 'おすすめ';
	@override String get illustrations => 'イラスト';
	@override String get manga => 'マンガ';
	@override String get novels => '小説';
	@override String get users => 'ユーザー';
}

// Path: ranking
class _Translations$ranking$ja_JP extends Translations$ranking$en_US {
	_Translations$ranking$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get emptyTitle => 'ランキング作品はまだありません';
	@override String get emptyMessage => '下に引っ張るとランキングを再取得できます。';
	@override late final _Translations$ranking$types$ja_JP types = _Translations$ranking$types$ja_JP._(_root);
	@override late final _Translations$ranking$modes$ja_JP modes = _Translations$ranking$modes$ja_JP._(_root);
}

// Path: search
class _Translations$search$ja_JP extends Translations$search$en_US {
	_Translations$search$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'タグ、作品 ID、ユーザー ID を検索';
	@override String get submit => '検索';
	@override String get trendingTags => '人気タグ';
	@override String get emptyTrendingTitle => '人気タグはありません';
	@override String get emptyTrendingMessage => '下に引っ張ると人気タグを再取得できます。';
	@override String get noSuggestions => '候補はありません';
	@override late final _Translations$search$filters$ja_JP filters = _Translations$search$filters$ja_JP._(_root);
	@override late final _Translations$search$type$ja_JP type = _Translations$search$type$ja_JP._(_root);
	@override late final _Translations$search$sort$ja_JP sort = _Translations$search$sort$ja_JP._(_root);
	@override late final _Translations$search$target$ja_JP target = _Translations$search$target$ja_JP._(_root);
	@override late final _Translations$search$date$ja_JP date = _Translations$search$date$ja_JP._(_root);
	@override late final _Translations$search$bookmarks$ja_JP bookmarks = _Translations$search$bookmarks$ja_JP._(_root);
	@override late final _Translations$search$direct$ja_JP direct = _Translations$search$direct$ja_JP._(_root);
	@override late final _Translations$search$empty$ja_JP empty = _Translations$search$empty$ja_JP._(_root);
}

// Path: user
class _Translations$user$ja_JP extends Translations$user$en_US {
	_Translations$user$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override late final _Translations$user$tabs$ja_JP tabs = _Translations$user$tabs$ja_JP._(_root);
	@override late final _Translations$user$stats$ja_JP stats = _Translations$user$stats$ja_JP._(_root);
	@override late final _Translations$user$bookmarks$ja_JP bookmarks = _Translations$user$bookmarks$ja_JP._(_root);
	@override late final _Translations$user$empty$ja_JP empty = _Translations$user$empty$ja_JP._(_root);
	@override late final _Translations$user$profile$ja_JP profile = _Translations$user$profile$ja_JP._(_root);
	@override late final _Translations$user$meta$ja_JP meta = _Translations$user$meta$ja_JP._(_root);
	@override late final _Translations$user$error$ja_JP error = _Translations$user$error$ja_JP._(_root);
}

// Path: newest
class _Translations$newest$ja_JP extends Translations$newest$en_US {
	_Translations$newest$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override late final _Translations$newest$audience$ja_JP audience = _Translations$newest$audience$ja_JP._(_root);
	@override late final _Translations$newest$workType$ja_JP workType = _Translations$newest$workType$ja_JP._(_root);
	@override late final _Translations$newest$followScope$ja_JP followScope = _Translations$newest$followScope$ja_JP._(_root);
	@override String get emptyTitle => '最新作品はありません';
	@override String compactFilter({required Object workType, required Object scope}) => '${workType} · ${scope}';
	@override String novelChars({required Object count}) => '${count} 文字';
	@override String novelPages({required Object count}) => '${count} ページ';
}

// Path: illust
class _Translations$illust$ja_JP extends Translations$illust$en_US {
	_Translations$illust$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override late final _Translations$illust$contextMenu$ja_JP contextMenu = _Translations$illust$contextMenu$ja_JP._(_root);
	@override late final _Translations$illust$imageLabels$ja_JP imageLabels = _Translations$illust$imageLabels$ja_JP._(_root);
	@override late final _Translations$illust$toast$ja_JP toast = _Translations$illust$toast$ja_JP._(_root);
	@override late final _Translations$illust$tooltip$ja_JP tooltip = _Translations$illust$tooltip$ja_JP._(_root);
	@override late final _Translations$illust$section$ja_JP section = _Translations$illust$section$ja_JP._(_root);
	@override late final _Translations$illust$metadata$ja_JP metadata = _Translations$illust$metadata$ja_JP._(_root);
	@override late final _Translations$illust$badge$ja_JP badge = _Translations$illust$badge$ja_JP._(_root);
	@override late final _Translations$illust$stats$ja_JP stats = _Translations$illust$stats$ja_JP._(_root);
	@override late final _Translations$illust$tags$ja_JP tags = _Translations$illust$tags$ja_JP._(_root);
	@override late final _Translations$illust$comments$ja_JP comments = _Translations$illust$comments$ja_JP._(_root);
	@override late final _Translations$illust$works$ja_JP works = _Translations$illust$works$ja_JP._(_root);
	@override late final _Translations$illust$related$ja_JP related = _Translations$illust$related$ja_JP._(_root);
}

// Path: novel
class _Translations$novel$ja_JP extends Translations$novel$en_US {
	_Translations$novel$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override late final _Translations$novel$detail$ja_JP detail = _Translations$novel$detail$ja_JP._(_root);
	@override late final _Translations$novel$reader$ja_JP reader = _Translations$novel$reader$ja_JP._(_root);
}

// Path: follow
class _Translations$follow$ja_JP extends Translations$follow$en_US {
	_Translations$follow$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get tooltipFollow => 'ユーザーをフォロー';
	@override String get tooltipUnfollow => 'フォロー解除';
	@override String get followed => 'フォロー中';
	@override String get notFollowed => '未フォロー';
}

// Path: richText
class _Translations$richText$ja_JP extends Translations$richText$en_US {
	_Translations$richText$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String twitterUser({required Object username}) => 'Twitter：${username}';
	@override String illustId({required Object id}) => 'イラスト ID：${id}';
	@override String userId({required Object id}) => 'ユーザー ID：${id}';
}

// Path: settings.theme
class _Translations$settings$theme$ja_JP extends Translations$settings$theme$en_US {
	_Translations$settings$theme$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get title => 'テーマ';
	@override String get system => '自動';
	@override String get light => 'ライト';
	@override String get dark => 'ダーク';
}

// Path: settings.language
class _Translations$settings$language$ja_JP extends Translations$settings$language$en_US {
	_Translations$settings$language$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get title => '言語';
	@override String get systemDefault => 'システム設定';
	@override String get enUs => 'English (United States)';
	@override String get zhCn => '简体中文';
	@override String get zhTw => '繁體中文';
	@override String get jaJp => '日本語';
}

// Path: settings.images
class _Translations$settings$images$ja_JP extends Translations$settings$images$en_US {
	_Translations$settings$images$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get title => '画像';
	@override String get previewQuality => 'プレビュー品質';
	@override String get viewerQuality => '表示品質';
	@override String get medium => '中';
	@override String get large => '大';
	@override String get original => 'オリジナル';
}

// Path: settings.downloads
class _Translations$settings$downloads$ja_JP extends Translations$settings$downloads$en_US {
	_Translations$settings$downloads$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get title => 'ダウンロード';
	@override String get savePath => '保存先';
	@override String get chooseFolder => 'フォルダーを選択';
	@override String get dialogTitle => 'ダウンロード保存先';
	@override String get defaultPath => '既定';
	@override String get customPath => 'カスタム';
	@override String get systemDownloadsFolder => 'システムのダウンロードフォルダー';
	@override String get noFolderSelected => 'フォルダーが選択されていません';
	@override String directorySet({required Object path}) => 'ダウンロード先を設定しました：${path}';
	@override String get directoryUnavailable => 'ダウンロード先を使用できません';
	@override String get tasksTitle => 'ダウンロードタスク';
	@override String get openTasks => 'ダウンロードタスク';
	@override String get openTasksSubtitle => '進捗、失敗、保存済みファイルを確認';
	@override String get noTasks => 'ダウンロードタスクはありません';
	@override String get noTasksMessage => 'ダウンロードした画像がここに表示されます。';
	@override String get total => '合計';
	@override String get active => '進行中';
	@override String get saved => '保存済み';
	@override String get failed => '失敗';
	@override String get downloading => 'ダウンロード中';
	@override String get needsAttention => '確認が必要';
	@override String get completed => '完了';
	@override String get queued => '待機中';
	@override String get running => 'ダウンロード中';
	@override String get paused => '一時停止';
	@override String get downloaded => 'ダウンロード済み';
	@override String get cancelled => 'キャンセル済み';
	@override String get savePending => '保存待ち';
	@override String get saving => '保存中';
	@override String get saveFailed => '保存失敗';
	@override String get retrySave => '保存を再試行';
	@override String get cancel => 'キャンセル';
	@override String get sync => '同期';
	@override String get syncFailed => 'ダウンロード状態の同期に失敗しました';
	@override String get actionFailed => 'ダウンロード操作に失敗しました';
	@override String get expand => '展開';
	@override String get collapse => '折りたたむ';
}

// Path: settings.account
class _Translations$settings$account$ja_JP extends Translations$settings$account$en_US {
	_Translations$settings$account$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get title => 'アカウント';
	@override String get signedOutSubtitle => 'ログインすると Pixiv アカウントが表示されます';
	@override String get notSignedIn => '未ログイン';
	@override String get signOut => 'ログアウト';
}

// Path: ranking.types
class _Translations$ranking$types$ja_JP extends Translations$ranking$types$en_US {
	_Translations$ranking$types$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get illustrations => 'イラスト';
	@override String get manga => 'マンガ';
	@override String get novels => '小説';
}

// Path: ranking.modes
class _Translations$ranking$modes$ja_JP extends Translations$ranking$modes$en_US {
	_Translations$ranking$modes$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get day => 'デイリー';
	@override String get dayR18 => 'デイリー R-18';
	@override String get dayMale => '男性向けデイリー';
	@override String get dayMaleR18 => '男性向けデイリー R-18';
	@override String get dayFemale => '女性向けデイリー';
	@override String get dayFemaleR18 => '女性向けデイリー R-18';
	@override String get dayAi => 'AI生成';
	@override String get dayR18Ai => 'AI生成 R-18';
	@override String get week => 'ウィークリー';
	@override String get weekR18 => 'ウィークリー R-18';
	@override String get weekOriginal => 'オリジナル';
	@override String get weekRookie => 'ルーキー';
	@override String get month => 'マンスリー';
}

// Path: search.filters
class _Translations$search$filters$ja_JP extends Translations$search$filters$en_US {
	_Translations$search$filters$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get title => '検索フィルター';
	@override String get sort => '並び替え';
	@override String get target => '対象';
	@override String get date => '日付';
	@override String get bookmarks => 'ブックマーク数';
}

// Path: search.type
class _Translations$search$type$ja_JP extends Translations$search$type$en_US {
	_Translations$search$type$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get illustManga => 'イラスト・マンガ';
	@override String get novel => '小説';
	@override String get user => 'ユーザー';
}

// Path: search.sort
class _Translations$search$sort$ja_JP extends Translations$search$sort$en_US {
	_Translations$search$sort$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get newest => '新しい順';
	@override String get oldest => '古い順';
	@override String get popular => '人気順';
}

// Path: search.target
class _Translations$search$target$ja_JP extends Translations$search$target$en_US {
	_Translations$search$target$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get tags => 'タグ';
	@override String get exactTags => '完全一致タグ';
	@override String get titleAndCaption => 'タイトル・説明文';
}

// Path: search.date
class _Translations$search$date$ja_JP extends Translations$search$date$en_US {
	_Translations$search$date$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get any => '指定なし';
	@override String get today => '今日';
	@override String get days7 => '7日';
	@override String get month1 => '1か月';
	@override String get months6 => '6か月';
	@override String get year1 => '1年';
	@override String get custom => 'カスタム';
}

// Path: search.bookmarks
class _Translations$search$bookmarks$ja_JP extends Translations$search$bookmarks$en_US {
	_Translations$search$bookmarks$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get any => '指定なし';
	@override String atLeast({required Object count}) => '${count}+ ブックマーク';
}

// Path: search.direct
class _Translations$search$direct$ja_JP extends Translations$search$direct$en_US {
	_Translations$search$direct$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String illust({required Object id}) => 'イラスト：${id}';
	@override String user({required Object id}) => 'ユーザー：${id}';
	@override String novel({required Object id}) => '小説：${id}';
}

// Path: search.empty
class _Translations$search$empty$ja_JP extends Translations$search$empty$en_US {
	_Translations$search$empty$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get illustrations => 'イラストは見つかりません';
	@override String get novels => '小説は見つかりません';
	@override String get users => 'ユーザーは見つかりません';
}

// Path: user.tabs
class _Translations$user$tabs$ja_JP extends Translations$user$tabs$en_US {
	_Translations$user$tabs$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get illustrations => 'イラスト';
	@override String get manga => 'マンガ';
	@override String get novels => '小説';
	@override String get bookmarks => 'ブックマーク';
	@override String get following => 'フォロー';
	@override String get profile => '詳細';
}

// Path: user.stats
class _Translations$user$stats$ja_JP extends Translations$user$stats$en_US {
	_Translations$user$stats$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get illustrations => 'イラスト';
	@override String get manga => 'マンガ';
	@override String get novels => '小説';
	@override String get following => 'フォロー';
}

// Path: user.bookmarks
class _Translations$user$bookmarks$ja_JP extends Translations$user$bookmarks$en_US {
	_Translations$user$bookmarks$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get illustManga => 'イラスト・マンガ';
	@override String get novels => '小説';
}

// Path: user.empty
class _Translations$user$empty$ja_JP extends Translations$user$empty$en_US {
	_Translations$user$empty$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get illustrations => 'イラストはありません';
	@override String get manga => 'マンガはありません';
	@override String get novels => '小説はありません';
	@override String get bookmarkIllustrations => '公開イラスト・マンガブックマークはありません';
	@override String get bookmarkNovels => '公開小説ブックマークはありません';
	@override String get following => 'フォロー中のユーザーはいません';
	@override String get profile => '公開プロフィール詳細はありません';
}

// Path: user.profile
class _Translations$user$profile$ja_JP extends Translations$user$profile$en_US {
	_Translations$user$profile$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get birthday => '誕生日';
	@override String get region => '地域';
	@override String get job => '職業';
	@override String get webpage => 'Web サイト';
	@override String get twitter => 'Twitter';
	@override String get pawoo => 'Pawoo';
	@override String get openLink => 'リンクを開く';
}

// Path: user.meta
class _Translations$user$meta$ja_JP extends Translations$user$meta$en_US {
	_Translations$user$meta$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String novelChars({required Object count}) => '${count} 文字';
	@override String novelPages({required Object count}) => '${count} ページ';
}

// Path: user.error
class _Translations$user$error$ja_JP extends Translations$user$error$en_US {
	_Translations$user$error$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get missingUser => 'ユーザー ID またはユーザー詳細がありません。';
}

// Path: newest.audience
class _Translations$newest$audience$ja_JP extends Translations$newest$audience$en_US {
	_Translations$newest$audience$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get following => 'フォロー中';
	@override String get mypixiv => 'マイピク';
	@override String get everyone => 'みんな';
}

// Path: newest.workType
class _Translations$newest$workType$ja_JP extends Translations$newest$workType$en_US {
	_Translations$newest$workType$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get illustManga => 'イラスト・マンガ';
	@override String get illust => 'イラスト';
	@override String get manga => 'マンガ';
	@override String get novel => '小説';
	@override String get compactArt => '作品';
	@override String get compactIllust => 'イラスト';
	@override String get compactManga => 'マンガ';
	@override String get compactNovel => '小説';
}

// Path: newest.followScope
class _Translations$newest$followScope$ja_JP extends Translations$newest$followScope$en_US {
	_Translations$newest$followScope$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get title => 'フォロー範囲';
	@override String get all => 'すべてのフォロー';
	@override String get private => '非公開フォロー';
	@override String get public => '公開フォロー';
	@override String get compactAll => 'すべて';
	@override String get compactPrivate => '非公開';
	@override String get compactPublic => '公開';
}

// Path: illust.contextMenu
class _Translations$illust$contextMenu$ja_JP extends Translations$illust$contextMenu$en_US {
	_Translations$illust$contextMenu$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get download => 'ダウンロード';
	@override String get copyImage => '画像をコピーする';
}

// Path: illust.imageLabels
class _Translations$illust$imageLabels$ja_JP extends Translations$illust$imageLabels$en_US {
	_Translations$illust$imageLabels$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get original => 'オリジナル画像';
	@override String get large => '大きい画像';
}

// Path: illust.toast
class _Translations$illust$toast$ja_JP extends Translations$illust$toast$en_US {
	_Translations$illust$toast$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get downloadStarted => '画像をダウンロードしています';
	@override String downloadComplete({required Object path}) => 'ダウンロード完了：${path}';
	@override String get downloadFailed => 'ダウンロードに失敗しました';
	@override String copying({required Object label}) => '${label}をコピーしています';
	@override String copied({required Object label}) => '${label}をコピーしました';
	@override String copiedValue({required Object label, required Object value}) => '${label}をコピーしました：${value}';
	@override String copyFailed({required Object label}) => '${label}のコピーに失敗しました';
}

// Path: illust.tooltip
class _Translations$illust$tooltip$ja_JP extends Translations$illust$tooltip$en_US {
	_Translations$illust$tooltip$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get previousImage => '前の画像';
	@override String get nextImage => '次の画像';
	@override String get backToDetail => '画像詳細に戻る';
	@override String get removeBookmark => 'ブックマークを解除';
	@override String get addBookmark => 'ブックマークに追加';
}

// Path: illust.section
class _Translations$illust$section$ja_JP extends Translations$illust$section$en_US {
	_Translations$illust$section$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get tags => 'タグ';
	@override String get caption => 'キャプション';
	@override String get details => '詳細';
	@override String get creator => '作者';
	@override String get recentWorks => '最近の作品';
	@override String get comments => 'コメント';
	@override String commentsWithCount({required Object count}) => 'コメント（${count}）';
	@override String get relatedWorks => '関連作品';
}

// Path: illust.metadata
class _Translations$illust$metadata$ja_JP extends Translations$illust$metadata$en_US {
	_Translations$illust$metadata$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get type => '種類';
	@override String get created => '作成日時';
}

// Path: illust.badge
class _Translations$illust$badge$ja_JP extends Translations$illust$badge$en_US {
	_Translations$illust$badge$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get aiArtwork => 'AI 作品';
	@override String get original => 'オリジナル';
}

// Path: illust.stats
class _Translations$illust$stats$ja_JP extends Translations$illust$stats$en_US {
	_Translations$illust$stats$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get size => 'サイズ';
	@override String get views => '閲覧';
	@override String get bookmarks => 'ブックマーク';
	@override String get pages => 'ページ';
}

// Path: illust.tags
class _Translations$illust$tags$ja_JP extends Translations$illust$tags$en_US {
	_Translations$illust$tags$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get none => 'タグはありません';
	@override String get tag => 'タグ';
}

// Path: illust.comments
class _Translations$illust$comments$ja_JP extends Translations$illust$comments$en_US {
	_Translations$illust$comments$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get failed => 'コメントを読み込めませんでした';
	@override String get empty => 'コメントはまだありません';
	@override String get moreAvailable => 'さらにコメントがあります';
	@override String get hasReplies => '返信があります';
	@override String get open => 'コメントを開く';
	@override String get reply => '返信';
	@override String replyingTo({required Object name}) => '${name} に返信中';
	@override String get loadReplies => '返信を読み込む';
	@override String get loadMoreReplies => 'さらに返信を読み込む';
	@override String get repliesFailed => '返信を読み込めませんでした';
	@override String get sendFailed => 'コメントの送信に失敗しました';
	@override String get delete => '削除';
	@override String get deleteFailed => 'コメントの削除に失敗しました';
	@override String get inputHint => 'コメントを書く';
	@override String replyInputHint({required Object name}) => '${name} に返信';
	@override String get emoji => '絵文字';
	@override String get stamp => 'スタンプ';
}

// Path: illust.works
class _Translations$illust$works$ja_JP extends Translations$illust$works$en_US {
	_Translations$illust$works$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get failed => '作品を読み込めませんでした';
	@override String get empty => '表示できる作品はありません';
}

// Path: illust.related
class _Translations$illust$related$ja_JP extends Translations$illust$related$en_US {
	_Translations$illust$related$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get failed => '関連作品を読み込めませんでした';
	@override String get empty => '関連作品はありません';
	@override String get viewMore => '関連作品をもっと見る';
}

// Path: novel.detail
class _Translations$novel$detail$ja_JP extends Translations$novel$detail$en_US {
	_Translations$novel$detail$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get images => '画像';
	@override String get series => 'シリーズ';
	@override String get content => '本文';
	@override String get startReading => '読み始める';
	@override String totalChars({required Object count}) => '全 ${count} 文字';
	@override String paragraphCount({required Object count}) => '${count} 段落';
	@override String segmentCount({required Object count}) => '${count} ページ';
}

// Path: novel.reader
class _Translations$novel$reader$ja_JP extends Translations$novel$reader$en_US {
	_Translations$novel$reader$ja_JP._(TranslationsJaJp root) : this._root = root, super.internal(root);

	final TranslationsJaJp _root; // ignore: unused_field

	// Translations
	@override String get title => '読書';
	@override String get body => '本文';
	@override String get chapters => '章';
	@override String get settings => '読書設定';
	@override String get emptyBody => '本文がありません';
	@override String totalChars({required Object count}) => '全 ${count} 文字';
	@override String pagePosition({required Object current, required Object total}) => '${current} / ${total} ページ';
	@override String pageTotal({required Object total}) => '${total} ページ';
	@override String currentPage({required Object page}) => '${page} ページ目';
	@override String get readingProgress => '読書進捗';
	@override String get previousPage => '前のページ';
	@override String get nextPage => '次のページ';
	@override String get display => '表示';
	@override String get fontSize => '文字サイズ';
	@override String get lineHeight => '行間';
	@override String get noChapterMarkers => '章マーカーはありません';
	@override String get close => '閉じる';
	@override String get decrease => '小さくする';
	@override String get increase => '大きくする';
	@override String get shortcutsTitle => 'ショートカット';
	@override String get shortcutsHelp => '左右キーまたは A/D でページ移動、上下キーまたは W/S でスクロール';
}

/// The flat map containing all translations for locale <ja-JP>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJaJp {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'freepiv',
			'navigation.home' => 'ホーム',
			'navigation.search' => '検索',
			'navigation.newest' => '最新',
			'navigation.ranking' => 'ランキング',
			'navigation.me' => '自分',
			'navigation.settings' => '設定',
			'common.back' => '戻る',
			'common.cancel' => 'キャンセル',
			'common.retry' => '再試行',
			'common.send' => '送信',
			'common.filter' => '絞り込み',
			'common.type' => '種類',
			'common.id' => 'ID',
			'common.error' => 'エラー',
			'common.notFound' => '見つかりません',
			'common.copy' => ({required Object label}) => '${label}をコピー',
			'common.labelValue' => ({required Object label, required Object value}) => '${label}：${value}',
			'common.errorWithCause' => ({required Object message, required Object cause}) => '${message}：${cause}',
			'refresh.pullToRefresh' => '引っ張って更新',
			'refresh.releaseToRefresh' => '離して更新',
			'refresh.refreshing' => '更新中',
			'refresh.refreshComplete' => '更新しました',
			'refresh.refreshFailed' => '更新に失敗しました',
			'refresh.pullToLoadMore' => '引っ張ってさらに読み込む',
			'refresh.releaseToLoad' => '離して読み込む',
			'refresh.loading' => '読み込み中',
			'refresh.loadComplete' => '読み込みました',
			'refresh.noMoreItems' => 'これ以上ありません',
			'refresh.loadFailed' => '読み込みに失敗しました',
			'refresh.lastUpdated' => '最終更新 %T',
			'toast.bookmarkFailed' => 'ブックマークに失敗しました',
			'toast.followFailed' => 'フォローに失敗しました',
			'login.title' => 'ログイン',
			'login.notSignedIn' => 'Pixiv にログインしていません',
			'login.signedInAs' => ({required Object name}) => '${name} としてログイン中',
			'login.signInToPixiv' => 'Pixiv にログイン',
			'login.signInAgain' => '再ログイン',
			'login.openingBrowser' => 'ブラウザを開いています…',
			'login.apiNotInitialized' => 'Pixiv API が初期化されていません。',
			'login.desktopOnly' => 'システムブラウザでのログインは現在 Linux、macOS、Windows のみ対応しています。',
			'login.openedInBrowser' => 'システムブラウザで Pixiv ログインを開きました。ログイン後にアプリへ戻ってください。',
			'login.callbackMissingCode' => ({required Object uri}) => 'Pixiv コールバックに code がありません：${uri}',
			'login.callbackReceived' => 'Pixiv コールバックを受信しました。トークンを取得しています。',
			'login.browserOpenUnsupported' => 'この環境ではシステムブラウザを開く処理が実装されていません。',
			'login.browserOpenFailed' => ({required Object browser, required Object output}) => '${browser} でログインリンクを開けませんでした：${output}',
			'settings.theme.title' => 'テーマ',
			'settings.theme.system' => '自動',
			'settings.theme.light' => 'ライト',
			'settings.theme.dark' => 'ダーク',
			'settings.language.title' => '言語',
			'settings.language.systemDefault' => 'システム設定',
			'settings.language.enUs' => 'English (United States)',
			'settings.language.zhCn' => '简体中文',
			'settings.language.zhTw' => '繁體中文',
			'settings.language.jaJp' => '日本語',
			'settings.images.title' => '画像',
			'settings.images.previewQuality' => 'プレビュー品質',
			'settings.images.viewerQuality' => '表示品質',
			'settings.images.medium' => '中',
			'settings.images.large' => '大',
			'settings.images.original' => 'オリジナル',
			'settings.downloads.title' => 'ダウンロード',
			'settings.downloads.savePath' => '保存先',
			'settings.downloads.chooseFolder' => 'フォルダーを選択',
			'settings.downloads.dialogTitle' => 'ダウンロード保存先',
			'settings.downloads.defaultPath' => '既定',
			'settings.downloads.customPath' => 'カスタム',
			'settings.downloads.systemDownloadsFolder' => 'システムのダウンロードフォルダー',
			'settings.downloads.noFolderSelected' => 'フォルダーが選択されていません',
			'settings.downloads.directorySet' => ({required Object path}) => 'ダウンロード先を設定しました：${path}',
			'settings.downloads.directoryUnavailable' => 'ダウンロード先を使用できません',
			'settings.downloads.tasksTitle' => 'ダウンロードタスク',
			'settings.downloads.openTasks' => 'ダウンロードタスク',
			'settings.downloads.openTasksSubtitle' => '進捗、失敗、保存済みファイルを確認',
			'settings.downloads.noTasks' => 'ダウンロードタスクはありません',
			'settings.downloads.noTasksMessage' => 'ダウンロードした画像がここに表示されます。',
			'settings.downloads.total' => '合計',
			'settings.downloads.active' => '進行中',
			'settings.downloads.saved' => '保存済み',
			'settings.downloads.failed' => '失敗',
			'settings.downloads.downloading' => 'ダウンロード中',
			'settings.downloads.needsAttention' => '確認が必要',
			'settings.downloads.completed' => '完了',
			'settings.downloads.queued' => '待機中',
			'settings.downloads.running' => 'ダウンロード中',
			'settings.downloads.paused' => '一時停止',
			'settings.downloads.downloaded' => 'ダウンロード済み',
			'settings.downloads.cancelled' => 'キャンセル済み',
			'settings.downloads.savePending' => '保存待ち',
			'settings.downloads.saving' => '保存中',
			'settings.downloads.saveFailed' => '保存失敗',
			'settings.downloads.retrySave' => '保存を再試行',
			'settings.downloads.cancel' => 'キャンセル',
			'settings.downloads.sync' => '同期',
			'settings.downloads.syncFailed' => 'ダウンロード状態の同期に失敗しました',
			'settings.downloads.actionFailed' => 'ダウンロード操作に失敗しました',
			'settings.downloads.expand' => '展開',
			'settings.downloads.collapse' => '折りたたむ',
			'settings.account.title' => 'アカウント',
			'settings.account.signedOutSubtitle' => 'ログインすると Pixiv アカウントが表示されます',
			'settings.account.notSignedIn' => '未ログイン',
			'settings.account.signOut' => 'ログアウト',
			'me.openProfile' => 'プロフィールを開く',
			'me.following' => 'フォロー中',
			'me.followers' => 'フォロワー',
			'me.emptyFollowing' => 'フォロー中のユーザーはいません',
			'me.emptyFollowers' => 'フォロワーはいません',
			'me.settings' => '設定',
			'me.settingsSubtitle' => 'テーマ、言語、画像、ダウンロード',
			'home.emptyTitle' => 'おすすめはまだありません',
			'home.emptyMessage' => '下に引っ張るとおすすめを再取得できます。',
			'home.rankings' => 'ランキング',
			'home.seeMore' => 'もっと見る',
			'home.recommended' => 'おすすめ',
			'home.illustrations' => 'イラスト',
			'home.manga' => 'マンガ',
			'home.novels' => '小説',
			'home.users' => 'ユーザー',
			'ranking.emptyTitle' => 'ランキング作品はまだありません',
			'ranking.emptyMessage' => '下に引っ張るとランキングを再取得できます。',
			'ranking.types.illustrations' => 'イラスト',
			'ranking.types.manga' => 'マンガ',
			'ranking.types.novels' => '小説',
			'ranking.modes.day' => 'デイリー',
			'ranking.modes.dayR18' => 'デイリー R-18',
			'ranking.modes.dayMale' => '男性向けデイリー',
			'ranking.modes.dayMaleR18' => '男性向けデイリー R-18',
			'ranking.modes.dayFemale' => '女性向けデイリー',
			'ranking.modes.dayFemaleR18' => '女性向けデイリー R-18',
			'ranking.modes.dayAi' => 'AI生成',
			'ranking.modes.dayR18Ai' => 'AI生成 R-18',
			'ranking.modes.week' => 'ウィークリー',
			'ranking.modes.weekR18' => 'ウィークリー R-18',
			'ranking.modes.weekOriginal' => 'オリジナル',
			'ranking.modes.weekRookie' => 'ルーキー',
			'ranking.modes.month' => 'マンスリー',
			'search.placeholder' => 'タグ、作品 ID、ユーザー ID を検索',
			'search.submit' => '検索',
			'search.trendingTags' => '人気タグ',
			'search.emptyTrendingTitle' => '人気タグはありません',
			'search.emptyTrendingMessage' => '下に引っ張ると人気タグを再取得できます。',
			'search.noSuggestions' => '候補はありません',
			'search.filters.title' => '検索フィルター',
			'search.filters.sort' => '並び替え',
			'search.filters.target' => '対象',
			'search.filters.date' => '日付',
			'search.filters.bookmarks' => 'ブックマーク数',
			'search.type.illustManga' => 'イラスト・マンガ',
			'search.type.novel' => '小説',
			'search.type.user' => 'ユーザー',
			'search.sort.newest' => '新しい順',
			'search.sort.oldest' => '古い順',
			'search.sort.popular' => '人気順',
			'search.target.tags' => 'タグ',
			'search.target.exactTags' => '完全一致タグ',
			'search.target.titleAndCaption' => 'タイトル・説明文',
			'search.date.any' => '指定なし',
			'search.date.today' => '今日',
			'search.date.days7' => '7日',
			'search.date.month1' => '1か月',
			'search.date.months6' => '6か月',
			'search.date.year1' => '1年',
			'search.date.custom' => 'カスタム',
			'search.bookmarks.any' => '指定なし',
			'search.bookmarks.atLeast' => ({required Object count}) => '${count}+ ブックマーク',
			'search.direct.illust' => ({required Object id}) => 'イラスト：${id}',
			'search.direct.user' => ({required Object id}) => 'ユーザー：${id}',
			'search.direct.novel' => ({required Object id}) => '小説：${id}',
			'search.empty.illustrations' => 'イラストは見つかりません',
			'search.empty.novels' => '小説は見つかりません',
			'search.empty.users' => 'ユーザーは見つかりません',
			'user.tabs.illustrations' => 'イラスト',
			'user.tabs.manga' => 'マンガ',
			'user.tabs.novels' => '小説',
			'user.tabs.bookmarks' => 'ブックマーク',
			'user.tabs.following' => 'フォロー',
			'user.tabs.profile' => '詳細',
			'user.stats.illustrations' => 'イラスト',
			'user.stats.manga' => 'マンガ',
			'user.stats.novels' => '小説',
			'user.stats.following' => 'フォロー',
			'user.bookmarks.illustManga' => 'イラスト・マンガ',
			'user.bookmarks.novels' => '小説',
			'user.empty.illustrations' => 'イラストはありません',
			'user.empty.manga' => 'マンガはありません',
			'user.empty.novels' => '小説はありません',
			'user.empty.bookmarkIllustrations' => '公開イラスト・マンガブックマークはありません',
			'user.empty.bookmarkNovels' => '公開小説ブックマークはありません',
			'user.empty.following' => 'フォロー中のユーザーはいません',
			'user.empty.profile' => '公開プロフィール詳細はありません',
			'user.profile.birthday' => '誕生日',
			'user.profile.region' => '地域',
			'user.profile.job' => '職業',
			'user.profile.webpage' => 'Web サイト',
			'user.profile.twitter' => 'Twitter',
			'user.profile.pawoo' => 'Pawoo',
			'user.profile.openLink' => 'リンクを開く',
			'user.meta.novelChars' => ({required Object count}) => '${count} 文字',
			'user.meta.novelPages' => ({required Object count}) => '${count} ページ',
			'user.error.missingUser' => 'ユーザー ID またはユーザー詳細がありません。',
			'newest.audience.following' => 'フォロー中',
			'newest.audience.mypixiv' => 'マイピク',
			'newest.audience.everyone' => 'みんな',
			'newest.workType.illustManga' => 'イラスト・マンガ',
			'newest.workType.illust' => 'イラスト',
			'newest.workType.manga' => 'マンガ',
			'newest.workType.novel' => '小説',
			'newest.workType.compactArt' => '作品',
			'newest.workType.compactIllust' => 'イラスト',
			'newest.workType.compactManga' => 'マンガ',
			'newest.workType.compactNovel' => '小説',
			'newest.followScope.title' => 'フォロー範囲',
			'newest.followScope.all' => 'すべてのフォロー',
			'newest.followScope.private' => '非公開フォロー',
			'newest.followScope.public' => '公開フォロー',
			'newest.followScope.compactAll' => 'すべて',
			'newest.followScope.compactPrivate' => '非公開',
			'newest.followScope.compactPublic' => '公開',
			'newest.emptyTitle' => '最新作品はありません',
			'newest.compactFilter' => ({required Object workType, required Object scope}) => '${workType} · ${scope}',
			'newest.novelChars' => ({required Object count}) => '${count} 文字',
			'newest.novelPages' => ({required Object count}) => '${count} ページ',
			'illust.contextMenu.download' => 'ダウンロード',
			'illust.contextMenu.copyImage' => '画像をコピーする',
			'illust.imageLabels.original' => 'オリジナル画像',
			'illust.imageLabels.large' => '大きい画像',
			'illust.toast.downloadStarted' => '画像をダウンロードしています',
			'illust.toast.downloadComplete' => ({required Object path}) => 'ダウンロード完了：${path}',
			'illust.toast.downloadFailed' => 'ダウンロードに失敗しました',
			'illust.toast.copying' => ({required Object label}) => '${label}をコピーしています',
			'illust.toast.copied' => ({required Object label}) => '${label}をコピーしました',
			'illust.toast.copiedValue' => ({required Object label, required Object value}) => '${label}をコピーしました：${value}',
			'illust.toast.copyFailed' => ({required Object label}) => '${label}のコピーに失敗しました',
			'illust.tooltip.previousImage' => '前の画像',
			'illust.tooltip.nextImage' => '次の画像',
			'illust.tooltip.backToDetail' => '画像詳細に戻る',
			'illust.tooltip.removeBookmark' => 'ブックマークを解除',
			'illust.tooltip.addBookmark' => 'ブックマークに追加',
			'illust.section.tags' => 'タグ',
			'illust.section.caption' => 'キャプション',
			'illust.section.details' => '詳細',
			'illust.section.creator' => '作者',
			'illust.section.recentWorks' => '最近の作品',
			'illust.section.comments' => 'コメント',
			'illust.section.commentsWithCount' => ({required Object count}) => 'コメント（${count}）',
			'illust.section.relatedWorks' => '関連作品',
			'illust.metadata.type' => '種類',
			'illust.metadata.created' => '作成日時',
			'illust.badge.aiArtwork' => 'AI 作品',
			'illust.badge.original' => 'オリジナル',
			'illust.stats.size' => 'サイズ',
			'illust.stats.views' => '閲覧',
			'illust.stats.bookmarks' => 'ブックマーク',
			'illust.stats.pages' => 'ページ',
			'illust.tags.none' => 'タグはありません',
			'illust.tags.tag' => 'タグ',
			'illust.comments.failed' => 'コメントを読み込めませんでした',
			'illust.comments.empty' => 'コメントはまだありません',
			'illust.comments.moreAvailable' => 'さらにコメントがあります',
			'illust.comments.hasReplies' => '返信があります',
			'illust.comments.open' => 'コメントを開く',
			'illust.comments.reply' => '返信',
			'illust.comments.replyingTo' => ({required Object name}) => '${name} に返信中',
			'illust.comments.loadReplies' => '返信を読み込む',
			'illust.comments.loadMoreReplies' => 'さらに返信を読み込む',
			'illust.comments.repliesFailed' => '返信を読み込めませんでした',
			'illust.comments.sendFailed' => 'コメントの送信に失敗しました',
			'illust.comments.delete' => '削除',
			'illust.comments.deleteFailed' => 'コメントの削除に失敗しました',
			'illust.comments.inputHint' => 'コメントを書く',
			'illust.comments.replyInputHint' => ({required Object name}) => '${name} に返信',
			'illust.comments.emoji' => '絵文字',
			'illust.comments.stamp' => 'スタンプ',
			'illust.works.failed' => '作品を読み込めませんでした',
			'illust.works.empty' => '表示できる作品はありません',
			'illust.related.failed' => '関連作品を読み込めませんでした',
			'illust.related.empty' => '関連作品はありません',
			'illust.related.viewMore' => '関連作品をもっと見る',
			'novel.detail.images' => '画像',
			'novel.detail.series' => 'シリーズ',
			'novel.detail.content' => '本文',
			'novel.detail.startReading' => '読み始める',
			'novel.detail.totalChars' => ({required Object count}) => '全 ${count} 文字',
			'novel.detail.paragraphCount' => ({required Object count}) => '${count} 段落',
			'novel.detail.segmentCount' => ({required Object count}) => '${count} ページ',
			'novel.reader.title' => '読書',
			'novel.reader.body' => '本文',
			'novel.reader.chapters' => '章',
			'novel.reader.settings' => '読書設定',
			'novel.reader.emptyBody' => '本文がありません',
			'novel.reader.totalChars' => ({required Object count}) => '全 ${count} 文字',
			'novel.reader.pagePosition' => ({required Object current, required Object total}) => '${current} / ${total} ページ',
			'novel.reader.pageTotal' => ({required Object total}) => '${total} ページ',
			'novel.reader.currentPage' => ({required Object page}) => '${page} ページ目',
			'novel.reader.readingProgress' => '読書進捗',
			'novel.reader.previousPage' => '前のページ',
			'novel.reader.nextPage' => '次のページ',
			'novel.reader.display' => '表示',
			'novel.reader.fontSize' => '文字サイズ',
			'novel.reader.lineHeight' => '行間',
			'novel.reader.noChapterMarkers' => '章マーカーはありません',
			'novel.reader.close' => '閉じる',
			'novel.reader.decrease' => '小さくする',
			'novel.reader.increase' => '大きくする',
			'novel.reader.shortcutsTitle' => 'ショートカット',
			'novel.reader.shortcutsHelp' => '左右キーまたは A/D でページ移動、上下キーまたは W/S でスクロール',
			'follow.tooltipFollow' => 'ユーザーをフォロー',
			'follow.tooltipUnfollow' => 'フォロー解除',
			'follow.followed' => 'フォロー中',
			'follow.notFollowed' => '未フォロー',
			'richText.twitterUser' => ({required Object username}) => 'Twitter：${username}',
			'richText.illustId' => ({required Object id}) => 'イラスト ID：${id}',
			'richText.userId' => ({required Object id}) => 'ユーザー ID：${id}',
			_ => null,
		};
	}
}
