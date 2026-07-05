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
class TranslationsZhHantTw extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZhHantTw({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhHantTw,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh-Hant-TW>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsZhHantTw _root = this; // ignore: unused_field

	@override 
	TranslationsZhHantTw $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZhHantTw(meta: meta ?? this.$meta);

	// Translations
	@override late final Translations$app$zh_Hant_TW app = Translations$app$zh_Hant_TW.internal(_root);
	@override late final Translations$navigation$zh_Hant_TW navigation = Translations$navigation$zh_Hant_TW.internal(_root);
	@override late final Translations$common$zh_Hant_TW common = Translations$common$zh_Hant_TW.internal(_root);
	@override late final Translations$refresh$zh_Hant_TW refresh = Translations$refresh$zh_Hant_TW.internal(_root);
	@override late final Translations$toast$zh_Hant_TW toast = Translations$toast$zh_Hant_TW.internal(_root);
	@override late final Translations$login$zh_Hant_TW login = Translations$login$zh_Hant_TW.internal(_root);
	@override late final Translations$settings$zh_Hant_TW settings = Translations$settings$zh_Hant_TW.internal(_root);
	@override late final Translations$me$zh_Hant_TW me = Translations$me$zh_Hant_TW.internal(_root);
	@override late final Translations$about$zh_Hant_TW about = Translations$about$zh_Hant_TW.internal(_root);
	@override late final Translations$home$zh_Hant_TW home = Translations$home$zh_Hant_TW.internal(_root);
	@override late final Translations$ranking$zh_Hant_TW ranking = Translations$ranking$zh_Hant_TW.internal(_root);
	@override late final Translations$search$zh_Hant_TW search = Translations$search$zh_Hant_TW.internal(_root);
	@override late final Translations$user$zh_Hant_TW user = Translations$user$zh_Hant_TW.internal(_root);
	@override late final Translations$newest$zh_Hant_TW newest = Translations$newest$zh_Hant_TW.internal(_root);
	@override late final Translations$illust$zh_Hant_TW illust = Translations$illust$zh_Hant_TW.internal(_root);
	@override late final Translations$novel$zh_Hant_TW novel = Translations$novel$zh_Hant_TW.internal(_root);
	@override late final Translations$follow$zh_Hant_TW follow = Translations$follow$zh_Hant_TW.internal(_root);
	@override late final Translations$richText$zh_Hant_TW richText = Translations$richText$zh_Hant_TW.internal(_root);
}

// Path: app
class Translations$app$zh_Hant_TW extends Translations$app$en_US {
	Translations$app$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get title => 'freepiv';
}

// Path: navigation
class Translations$navigation$zh_Hant_TW extends Translations$navigation$en_US {
	Translations$navigation$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get home => '首頁';
	@override String get search => '搜尋';
	@override String get newest => '最新';
	@override String get ranking => '排行榜';
	@override String get me => '我的';
	@override String get settings => '設定';
}

// Path: common
class Translations$common$zh_Hant_TW extends Translations$common$en_US {
	Translations$common$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get back => '返回';
	@override String get cancel => '取消';
	@override String get retry => '重試';
	@override String get send => '傳送';
	@override String get filter => '篩選';
	@override String get type => '類型';
	@override String get id => 'ID';
	@override String get error => '錯誤';
	@override String get notFound => '找不到';
	@override String copy({required Object label}) => '複製${label}';
	@override String labelValue({required Object label, required Object value}) => '${label}：${value}';
	@override String errorWithCause({required Object message, required Object cause}) => '${message}：${cause}';
}

// Path: refresh
class Translations$refresh$zh_Hant_TW extends Translations$refresh$en_US {
	Translations$refresh$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get pullToRefresh => '下拉重新整理';
	@override String get releaseToRefresh => '放開重新整理';
	@override String get refreshing => '正在重新整理';
	@override String get refreshComplete => '重新整理完成';
	@override String get refreshFailed => '重新整理失敗';
	@override String get pullToLoadMore => '上拉載入更多';
	@override String get releaseToLoad => '放開載入';
	@override String get loading => '載入中';
	@override String get loadComplete => '載入完成';
	@override String get noMoreItems => '沒有更多內容';
	@override String get loadFailed => '載入失敗';
	@override String get lastUpdated => '最後更新 %T';
}

// Path: toast
class Translations$toast$zh_Hant_TW extends Translations$toast$en_US {
	Translations$toast$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get bookmarkFailed => '收藏失敗';
	@override String get followFailed => '關注失敗';
}

// Path: login
class Translations$login$zh_Hant_TW extends Translations$login$en_US {
	Translations$login$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get title => '登入';
	@override String get notSignedIn => '尚未登入 Pixiv';
	@override String signedInAs({required Object name}) => '已登入為 ${name}';
	@override String get signInToPixiv => '登入 Pixiv';
	@override String get signInAgain => '重新登入';
	@override String get openingBrowser => '正在開啟瀏覽器…';
	@override String get apiNotInitialized => 'Pixiv API 尚未初始化。';
	@override String get desktopOnly => '系統瀏覽器登入目前僅支援 Linux、macOS 與 Windows。';
	@override String get openedInBrowser => '已在系統瀏覽器開啟 Pixiv 登入。完成登入後請返回應用程式。';
	@override String callbackMissingCode({required Object uri}) => 'Pixiv 回呼缺少 code：${uri}';
	@override String get callbackReceived => '已收到 Pixiv 回呼，正在取得權杖。';
	@override String get browserOpenUnsupported => '目前環境尚未實作系統瀏覽器開啟功能。';
	@override String browserOpenFailed({required Object browser, required Object output}) => '${browser} 無法開啟登入連結：${output}';
	@override String get proxyHint => '如果你使用了網路代理，請在此設定代理地址再進行登入。';
}

// Path: settings
class Translations$settings$zh_Hant_TW extends Translations$settings$en_US {
	Translations$settings$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override late final Translations$settings$theme$zh_Hant_TW theme = Translations$settings$theme$zh_Hant_TW.internal(_root);
	@override late final Translations$settings$language$zh_Hant_TW language = Translations$settings$language$zh_Hant_TW.internal(_root);
	@override late final Translations$settings$images$zh_Hant_TW images = Translations$settings$images$zh_Hant_TW.internal(_root);
	@override late final Translations$settings$downloads$zh_Hant_TW downloads = Translations$settings$downloads$zh_Hant_TW.internal(_root);
	@override late final Translations$settings$proxy$zh_Hant_TW proxy = Translations$settings$proxy$zh_Hant_TW.internal(_root);
	@override late final Translations$settings$account$zh_Hant_TW account = Translations$settings$account$zh_Hant_TW.internal(_root);
}

// Path: me
class Translations$me$zh_Hant_TW extends Translations$me$en_US {
	Translations$me$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get openProfile => '開啟個人頁';
	@override String get following => '我的關注';
	@override String get followers => '我的粉絲';
	@override String get emptyFollowing => '尚無關注使用者';
	@override String get emptyFollowers => '尚無粉絲';
	@override String get about => '關於';
	@override String get aboutSubtitle => '版本、更新和專案連結';
	@override String get settings => '設定';
	@override String get settingsSubtitle => '主題、語言、圖片和下載';
}

// Path: about
class Translations$about$zh_Hant_TW extends Translations$about$en_US {
	Translations$about$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get title => '關於';
	@override String get appName => 'freepiv';
	@override String get subtitle => '用於瀏覽 Pixiv 內容的輕量客戶端。你可以在這裡查看目前版本、檢查更新並開啟專案下載頁面。';
	@override String get project => '專案';
	@override String get projectPage => '專案首頁';
	@override String get releasePage => '發布頁面';
	@override String get versionInfo => '版本資訊';
	@override String get appVersion => '應用程式版本';
	@override String get latestVersion => '最新版本';
	@override String currentVersion({required Object version, required Object buildNumber}) => '目前版本 ${version}+${buildNumber}';
	@override String get noCachedUpdate => '暫無可用更新';
	@override String get loading => '載入中';
	@override String get community => '社群';
	@override String get telegram => 'Telegram';
	@override String get discord => 'Discord';
	@override String get checkUpdate => '檢查更新';
	@override String get checkingUpdateShort => '檢查中';
	@override String get checkingUpdate => '正在檢查更新…';
	@override String get noUpdate => '目前已是最新版本';
	@override String updateAvailable({required Object version, required Object buildNumber}) => '發現新版本 ${version}+${buildNumber}';
	@override String get checkUpdateFailed => '檢查更新失敗';
	@override String get downloadPage => '下載頁面';
	@override String get downloadAssetUnavailable => '找不到適合目前平台的下載項目，已開啟發布頁面。';
	@override String get openDownloadFailed => '開啟下載頁面失敗';
	@override String get openLinkFailed => '開啟連結失敗';
}

// Path: home
class Translations$home$zh_Hant_TW extends Translations$home$en_US {
	Translations$home$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get emptyTitle => '尚無推薦';
	@override String get emptyMessage => '下拉即可重新取得推薦。';
	@override String get rankings => '排行榜';
	@override String get seeMore => '查看更多';
	@override String get recommended => '推薦';
	@override String get illustrations => '插畫';
	@override String get manga => '漫畫';
	@override String get novels => '小說';
	@override String get users => '使用者';
}

// Path: ranking
class Translations$ranking$zh_Hant_TW extends Translations$ranking$en_US {
	Translations$ranking$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get emptyTitle => '暫無排行榜作品';
	@override String get emptyMessage => '下拉即可重新取得排行榜。';
	@override late final Translations$ranking$types$zh_Hant_TW types = Translations$ranking$types$zh_Hant_TW.internal(_root);
	@override late final Translations$ranking$modes$zh_Hant_TW modes = Translations$ranking$modes$zh_Hant_TW.internal(_root);
}

// Path: search
class Translations$search$zh_Hant_TW extends Translations$search$en_US {
	Translations$search$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get placeholder => '搜尋標籤、作品 ID 或使用者 ID';
	@override String get submit => '搜尋';
	@override String get trendingTags => '熱門標籤';
	@override String get emptyTrendingTitle => '尚無熱門標籤';
	@override String get emptyTrendingMessage => '下拉即可重新取得熱門標籤。';
	@override String get noSuggestions => '沒有候選詞';
	@override late final Translations$search$filters$zh_Hant_TW filters = Translations$search$filters$zh_Hant_TW.internal(_root);
	@override late final Translations$search$type$zh_Hant_TW type = Translations$search$type$zh_Hant_TW.internal(_root);
	@override late final Translations$search$sort$zh_Hant_TW sort = Translations$search$sort$zh_Hant_TW.internal(_root);
	@override late final Translations$search$target$zh_Hant_TW target = Translations$search$target$zh_Hant_TW.internal(_root);
	@override late final Translations$search$date$zh_Hant_TW date = Translations$search$date$zh_Hant_TW.internal(_root);
	@override late final Translations$search$bookmarks$zh_Hant_TW bookmarks = Translations$search$bookmarks$zh_Hant_TW.internal(_root);
	@override late final Translations$search$direct$zh_Hant_TW direct = Translations$search$direct$zh_Hant_TW.internal(_root);
	@override late final Translations$search$empty$zh_Hant_TW empty = Translations$search$empty$zh_Hant_TW.internal(_root);
}

// Path: user
class Translations$user$zh_Hant_TW extends Translations$user$en_US {
	Translations$user$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override late final Translations$user$tabs$zh_Hant_TW tabs = Translations$user$tabs$zh_Hant_TW.internal(_root);
	@override late final Translations$user$stats$zh_Hant_TW stats = Translations$user$stats$zh_Hant_TW.internal(_root);
	@override late final Translations$user$bookmarks$zh_Hant_TW bookmarks = Translations$user$bookmarks$zh_Hant_TW.internal(_root);
	@override late final Translations$user$empty$zh_Hant_TW empty = Translations$user$empty$zh_Hant_TW.internal(_root);
	@override late final Translations$user$profile$zh_Hant_TW profile = Translations$user$profile$zh_Hant_TW.internal(_root);
	@override late final Translations$user$meta$zh_Hant_TW meta = Translations$user$meta$zh_Hant_TW.internal(_root);
	@override late final Translations$user$error$zh_Hant_TW error = Translations$user$error$zh_Hant_TW.internal(_root);
}

// Path: newest
class Translations$newest$zh_Hant_TW extends Translations$newest$en_US {
	Translations$newest$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override late final Translations$newest$audience$zh_Hant_TW audience = Translations$newest$audience$zh_Hant_TW.internal(_root);
	@override late final Translations$newest$workType$zh_Hant_TW workType = Translations$newest$workType$zh_Hant_TW.internal(_root);
	@override late final Translations$newest$followScope$zh_Hant_TW followScope = Translations$newest$followScope$zh_Hant_TW.internal(_root);
	@override String get emptyTitle => '尚無最新作品';
	@override String compactFilter({required Object workType, required Object scope}) => '${workType} · ${scope}';
	@override String novelChars({required Object count}) => '${count} 字';
	@override String novelPages({required Object count}) => '${count} 頁';
}

// Path: illust
class Translations$illust$zh_Hant_TW extends Translations$illust$en_US {
	Translations$illust$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override late final Translations$illust$contextMenu$zh_Hant_TW contextMenu = Translations$illust$contextMenu$zh_Hant_TW.internal(_root);
	@override late final Translations$illust$imageLabels$zh_Hant_TW imageLabels = Translations$illust$imageLabels$zh_Hant_TW.internal(_root);
	@override late final Translations$illust$toast$zh_Hant_TW toast = Translations$illust$toast$zh_Hant_TW.internal(_root);
	@override late final Translations$illust$tooltip$zh_Hant_TW tooltip = Translations$illust$tooltip$zh_Hant_TW.internal(_root);
	@override late final Translations$illust$section$zh_Hant_TW section = Translations$illust$section$zh_Hant_TW.internal(_root);
	@override late final Translations$illust$metadata$zh_Hant_TW metadata = Translations$illust$metadata$zh_Hant_TW.internal(_root);
	@override late final Translations$illust$badge$zh_Hant_TW badge = Translations$illust$badge$zh_Hant_TW.internal(_root);
	@override late final Translations$illust$stats$zh_Hant_TW stats = Translations$illust$stats$zh_Hant_TW.internal(_root);
	@override late final Translations$illust$tags$zh_Hant_TW tags = Translations$illust$tags$zh_Hant_TW.internal(_root);
	@override late final Translations$illust$comments$zh_Hant_TW comments = Translations$illust$comments$zh_Hant_TW.internal(_root);
	@override late final Translations$illust$works$zh_Hant_TW works = Translations$illust$works$zh_Hant_TW.internal(_root);
	@override late final Translations$illust$related$zh_Hant_TW related = Translations$illust$related$zh_Hant_TW.internal(_root);
}

// Path: novel
class Translations$novel$zh_Hant_TW extends Translations$novel$en_US {
	Translations$novel$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override late final Translations$novel$detail$zh_Hant_TW detail = Translations$novel$detail$zh_Hant_TW.internal(_root);
	@override late final Translations$novel$reader$zh_Hant_TW reader = Translations$novel$reader$zh_Hant_TW.internal(_root);
}

// Path: follow
class Translations$follow$zh_Hant_TW extends Translations$follow$en_US {
	Translations$follow$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get tooltipFollow => '關注使用者';
	@override String get tooltipUnfollow => '取消關注';
	@override String get followed => '已關注';
	@override String get notFollowed => '未關注';
}

// Path: richText
class Translations$richText$zh_Hant_TW extends Translations$richText$en_US {
	Translations$richText$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String twitterUser({required Object username}) => 'Twitter：${username}';
	@override String illustId({required Object id}) => '插畫 ID：${id}';
	@override String userId({required Object id}) => '使用者 ID：${id}';
}

// Path: settings.theme
class Translations$settings$theme$zh_Hant_TW extends Translations$settings$theme$en_US {
	Translations$settings$theme$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get title => '主題';
	@override String get system => '跟隨系統';
	@override String get light => '淺色';
	@override String get dark => '深色';
}

// Path: settings.language
class Translations$settings$language$zh_Hant_TW extends Translations$settings$language$en_US {
	Translations$settings$language$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get title => '語言';
	@override String get systemDefault => '跟隨系統';
	@override String get enUs => 'English (United States)';
	@override String get zhCn => '简体中文';
	@override String get zhTw => '繁體中文';
	@override String get jaJp => '日本語';
}

// Path: settings.images
class Translations$settings$images$zh_Hant_TW extends Translations$settings$images$en_US {
	Translations$settings$images$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get title => '圖片';
	@override String get previewQuality => '預覽品質';
	@override String get viewerQuality => '檢視品質';
	@override String get medium => '中等';
	@override String get large => '大圖';
	@override String get original => '原圖';
}

// Path: settings.downloads
class Translations$settings$downloads$zh_Hant_TW extends Translations$settings$downloads$en_US {
	Translations$settings$downloads$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get title => '下載';
	@override String get savePath => '儲存路徑';
	@override String get chooseFolder => '選擇資料夾';
	@override String get dialogTitle => '下載儲存路徑';
	@override String get defaultPath => '預設';
	@override String get customPath => '自訂';
	@override String get systemDownloadsFolder => '系統下載資料夾';
	@override String get noFolderSelected => '尚未選擇資料夾';
	@override String directorySet({required Object path}) => '下載目錄已設定：${path}';
	@override String get directoryUnavailable => '下載目錄不可用';
	@override String get maxConcurrentDownloads => '最大同時下載數量';
	@override String maxConcurrentDownloadsSubtitle({required Object count}) => '目前最多同時下載 ${count} 個任務，後續任務會排隊等待。';
	@override String get tasksTitle => '下載任務';
	@override String get openTasks => '下載任務';
	@override String get openTasksSubtitle => '檢視進度、失敗項目和已儲存檔案';
	@override String get noTasks => '尚無下載任務';
	@override String get noTasksMessage => '下載的圖片會顯示在這裡。';
	@override String get total => '總數';
	@override String get active => '進行中';
	@override String get saved => '已儲存';
	@override String get failed => '失敗';
	@override String get downloading => '正在下載';
	@override String get needsAttention => '需要處理';
	@override String get completed => '已完成';
	@override String get queued => '佇列中';
	@override String get running => '正在下載';
	@override String get paused => '已暫停';
	@override String get downloaded => '已下載';
	@override String get cancelled => '已取消';
	@override String get savePending => '等待儲存';
	@override String get saving => '正在儲存';
	@override String get saveFailed => '儲存失敗';
	@override String get retrySave => '重試儲存';
	@override String get cancel => '取消';
	@override String get deleteTask => '刪除任務';
	@override String get sync => '同步';
	@override String get syncFailed => '下載狀態同步失敗';
	@override String get actionFailed => '下載操作失敗';
	@override String get expand => '展開';
	@override String get collapse => '收合';
}

// Path: settings.proxy
class Translations$settings$proxy$zh_Hant_TW extends Translations$settings$proxy$en_US {
	Translations$settings$proxy$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get title => '網路代理';
	@override String get shortTitle => '代理';
	@override String get subtitle => '儲存後 Pixiv API 和圖片請求會使用所選代理。';
	@override String get open => '設定代理';
	@override String get enabled => '啟用代理';
	@override String get enabledStatus => '代理已開啟';
	@override String get disabledStatus => '直連';
	@override String get protocol => '代理協定';
	@override String get protocolHttp => 'HTTP';
	@override String get protocolSocks => 'SOCKS';
	@override String get address => 'IP 位址';
	@override String get addressHint => '127.0.0.1';
	@override String get port => '連接埠';
	@override String get portHint => '7890';
	@override String get helper => 'IP 和連接埠分開填寫，例如 127.0.0.1 和 7890。';
	@override String get save => '儲存';
	@override String get saved => '代理設定已儲存';
	@override String get required => '啟用代理前需要填寫 IP 和連接埠。';
	@override String get invalid => '請輸入有效的 IP 和連接埠。';
	@override String get hostRequired => '請輸入 IP。';
	@override String get portRequired => '請輸入連接埠。';
	@override String get invalidHost => '請輸入有效的 IP 或主機名稱。';
	@override String get invalidPort => '連接埠範圍為 1-65535。';
	@override String get loadSystem => '取得系統代理';
	@override String get systemLoaded => '已取得系統代理';
	@override String get systemNotFound => '未偵測到系統代理';
	@override String get systemUnsupported => '僅桌面端支援取得系統代理';
	@override String get systemLoadFailed => '取得系統代理失敗';
	@override String entrySubtitleOn({required Object url}) => '已開啟：${url}';
	@override String get entrySubtitleOff => '未開啟';
}

// Path: settings.account
class Translations$settings$account$zh_Hant_TW extends Translations$settings$account$en_US {
	Translations$settings$account$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get title => '帳號';
	@override String get signedOutSubtitle => '登入後顯示 Pixiv 帳號';
	@override String get notSignedIn => '尚未登入';
	@override String get signOut => '登出';
}

// Path: ranking.types
class Translations$ranking$types$zh_Hant_TW extends Translations$ranking$types$en_US {
	Translations$ranking$types$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get illustrations => '插畫';
	@override String get manga => '漫畫';
	@override String get novels => '小說';
}

// Path: ranking.modes
class Translations$ranking$modes$zh_Hant_TW extends Translations$ranking$modes$en_US {
	Translations$ranking$modes$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get day => '每日';
	@override String get dayR18 => '每日 R-18';
	@override String get dayMale => '男性每日';
	@override String get dayMaleR18 => '男性每日 R-18';
	@override String get dayFemale => '女性每日';
	@override String get dayFemaleR18 => '女性每日 R-18';
	@override String get dayAi => 'AI 生成';
	@override String get dayR18Ai => 'AI 生成 R-18';
	@override String get week => '每週';
	@override String get weekR18 => '每週 R-18';
	@override String get weekOriginal => '原創每週';
	@override String get weekRookie => '新人每週';
	@override String get month => '每月';
}

// Path: search.filters
class Translations$search$filters$zh_Hant_TW extends Translations$search$filters$en_US {
	Translations$search$filters$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get title => '搜尋篩選';
	@override String get sort => '排序';
	@override String get target => '目標';
	@override String get date => '日期';
	@override String get bookmarks => '收藏數';
}

// Path: search.type
class Translations$search$type$zh_Hant_TW extends Translations$search$type$en_US {
	Translations$search$type$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get illustManga => '插畫&漫畫';
	@override String get novel => '小說';
	@override String get user => '使用者';
}

// Path: search.sort
class Translations$search$sort$zh_Hant_TW extends Translations$search$sort$en_US {
	Translations$search$sort$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get newest => '最新';
	@override String get oldest => '最舊';
	@override String get popular => '熱門';
}

// Path: search.target
class Translations$search$target$zh_Hant_TW extends Translations$search$target$en_US {
	Translations$search$target$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get tags => '標籤';
	@override String get exactTags => '精確標籤';
	@override String get titleAndCaption => '標題與說明';
}

// Path: search.date
class Translations$search$date$zh_Hant_TW extends Translations$search$date$en_US {
	Translations$search$date$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get any => '任意日期';
	@override String get today => '今天';
	@override String get days7 => '7 天';
	@override String get month1 => '1 個月';
	@override String get months6 => '6 個月';
	@override String get year1 => '1 年';
	@override String get custom => '自訂';
}

// Path: search.bookmarks
class Translations$search$bookmarks$zh_Hant_TW extends Translations$search$bookmarks$en_US {
	Translations$search$bookmarks$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get any => '任意收藏數';
	@override String atLeast({required Object count}) => '${count}+ 收藏';
}

// Path: search.direct
class Translations$search$direct$zh_Hant_TW extends Translations$search$direct$en_US {
	Translations$search$direct$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String illust({required Object id}) => '插畫：${id}';
	@override String user({required Object id}) => '使用者：${id}';
	@override String novel({required Object id}) => '小說：${id}';
}

// Path: search.empty
class Translations$search$empty$zh_Hant_TW extends Translations$search$empty$en_US {
	Translations$search$empty$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get illustrations => '找不到插畫';
	@override String get novels => '找不到小說';
	@override String get users => '找不到使用者';
}

// Path: user.tabs
class Translations$user$tabs$zh_Hant_TW extends Translations$user$tabs$en_US {
	Translations$user$tabs$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get illustrations => '插畫';
	@override String get manga => '漫畫';
	@override String get novels => '小說';
	@override String get bookmarks => '收藏';
	@override String get following => '關注';
	@override String get profile => '詳細資訊';
}

// Path: user.stats
class Translations$user$stats$zh_Hant_TW extends Translations$user$stats$en_US {
	Translations$user$stats$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get illustrations => '插畫';
	@override String get manga => '漫畫';
	@override String get novels => '小說';
	@override String get following => '關注';
}

// Path: user.bookmarks
class Translations$user$bookmarks$zh_Hant_TW extends Translations$user$bookmarks$en_US {
	Translations$user$bookmarks$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get illustManga => '插畫&漫畫';
	@override String get novels => '小說';
}

// Path: user.empty
class Translations$user$empty$zh_Hant_TW extends Translations$user$empty$en_US {
	Translations$user$empty$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get illustrations => '尚無插畫';
	@override String get manga => '尚無漫畫';
	@override String get novels => '尚無小說';
	@override String get bookmarkIllustrations => '尚無公開插畫或漫畫收藏';
	@override String get bookmarkNovels => '尚無公開小說收藏';
	@override String get following => '尚無關注使用者';
	@override String get profile => '尚無公開詳細資訊';
}

// Path: user.profile
class Translations$user$profile$zh_Hant_TW extends Translations$user$profile$en_US {
	Translations$user$profile$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get birthday => '生日';
	@override String get region => '地區';
	@override String get job => '職業';
	@override String get webpage => '主頁';
	@override String get twitter => 'Twitter';
	@override String get pawoo => 'Pawoo';
	@override String get openLink => '開啟連結';
}

// Path: user.meta
class Translations$user$meta$zh_Hant_TW extends Translations$user$meta$en_US {
	Translations$user$meta$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String novelChars({required Object count}) => '${count} 字';
	@override String novelPages({required Object count}) => '${count} 頁';
}

// Path: user.error
class Translations$user$error$zh_Hant_TW extends Translations$user$error$en_US {
	Translations$user$error$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get missingUser => '缺少使用者 ID 或使用者詳細資訊。';
}

// Path: newest.audience
class Translations$newest$audience$zh_Hant_TW extends Translations$newest$audience$en_US {
	Translations$newest$audience$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get following => '關注';
	@override String get mypixiv => '好P友';
	@override String get everyone => '所有人';
}

// Path: newest.workType
class Translations$newest$workType$zh_Hant_TW extends Translations$newest$workType$en_US {
	Translations$newest$workType$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get illustManga => '插畫&漫畫';
	@override String get illust => '插畫';
	@override String get manga => '漫畫';
	@override String get novel => '小說';
	@override String get compactArt => '作品';
	@override String get compactIllust => '插畫';
	@override String get compactManga => '漫畫';
	@override String get compactNovel => '小說';
}

// Path: newest.followScope
class Translations$newest$followScope$zh_Hant_TW extends Translations$newest$followScope$en_US {
	Translations$newest$followScope$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get title => '關注範圍';
	@override String get all => '全部關注';
	@override String get private => '私人關注';
	@override String get public => '公開關注';
	@override String get compactAll => '全部';
	@override String get compactPrivate => '私人';
	@override String get compactPublic => '公開';
}

// Path: illust.contextMenu
class Translations$illust$contextMenu$zh_Hant_TW extends Translations$illust$contextMenu$en_US {
	Translations$illust$contextMenu$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get download => '下載';
	@override String get downloadAll => '下載全部';
	@override String get copyImage => '複製圖像';
}

// Path: illust.imageLabels
class Translations$illust$imageLabels$zh_Hant_TW extends Translations$illust$imageLabels$en_US {
	Translations$illust$imageLabels$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get original => '原圖';
	@override String get large => '大圖';
}

// Path: illust.toast
class Translations$illust$toast$zh_Hant_TW extends Translations$illust$toast$en_US {
	Translations$illust$toast$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get downloadStarted => '開始下載圖片';
	@override String downloadAllQueued({required Object count}) => '已加入下載佇列：${count} 張圖片';
	@override String downloadComplete({required Object path}) => '下載完成：${path}';
	@override String get downloadFailed => '下載失敗';
	@override String copying({required Object label}) => '正在複製${label}';
	@override String copied({required Object label}) => '已複製${label}';
	@override String copiedValue({required Object label, required Object value}) => '已複製${label}：${value}';
	@override String copyFailed({required Object label}) => '複製${label}失敗';
}

// Path: illust.tooltip
class Translations$illust$tooltip$zh_Hant_TW extends Translations$illust$tooltip$en_US {
	Translations$illust$tooltip$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get previousImage => '上一張圖片';
	@override String get nextImage => '下一張圖片';
	@override String get backToDetail => '回到圖片詳細資訊';
	@override String get removeBookmark => '移除收藏';
	@override String get addBookmark => '加入收藏';
}

// Path: illust.section
class Translations$illust$section$zh_Hant_TW extends Translations$illust$section$en_US {
	Translations$illust$section$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get tags => '標籤';
	@override String get caption => '說明';
	@override String get details => '詳細資訊';
	@override String get creator => '作者';
	@override String get recentWorks => '近期作品';
	@override String get comments => '留言';
	@override String commentsWithCount({required Object count}) => '留言（${count}）';
	@override String get relatedWorks => '相似作品';
}

// Path: illust.metadata
class Translations$illust$metadata$zh_Hant_TW extends Translations$illust$metadata$en_US {
	Translations$illust$metadata$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get type => '類型';
	@override String get created => '建立時間';
}

// Path: illust.badge
class Translations$illust$badge$zh_Hant_TW extends Translations$illust$badge$en_US {
	Translations$illust$badge$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get aiArtwork => 'AI 作品';
	@override String get original => '原創';
}

// Path: illust.stats
class Translations$illust$stats$zh_Hant_TW extends Translations$illust$stats$en_US {
	Translations$illust$stats$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get size => '尺寸';
	@override String get views => '瀏覽';
	@override String get bookmarks => '收藏';
	@override String get pages => '頁數';
}

// Path: illust.tags
class Translations$illust$tags$zh_Hant_TW extends Translations$illust$tags$en_US {
	Translations$illust$tags$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get none => '沒有標籤';
	@override String get tag => '標籤';
}

// Path: illust.comments
class Translations$illust$comments$zh_Hant_TW extends Translations$illust$comments$en_US {
	Translations$illust$comments$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get failed => '留言載入失敗';
	@override String get empty => '尚無留言';
	@override String get moreAvailable => '還有更多留言';
	@override String get hasReplies => '有回覆';
	@override String get open => '開啟留言';
	@override String get reply => '回覆';
	@override String replyingTo({required Object name}) => '正在回覆 ${name}';
	@override String get loadReplies => '載入回覆';
	@override String get loadMoreReplies => '載入更多回覆';
	@override String get repliesFailed => '回覆載入失敗';
	@override String get sendFailed => '留言傳送失敗';
	@override String get delete => '刪除';
	@override String get deleteFailed => '留言刪除失敗';
	@override String get inputHint => '寫下留言';
	@override String replyInputHint({required Object name}) => '回覆 ${name}';
	@override String get emoji => '表情';
	@override String get stamp => '貼圖';
}

// Path: illust.works
class Translations$illust$works$zh_Hant_TW extends Translations$illust$works$en_US {
	Translations$illust$works$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get failed => '作品載入失敗';
	@override String get empty => '暫無可顯示作品';
}

// Path: illust.related
class Translations$illust$related$zh_Hant_TW extends Translations$illust$related$en_US {
	Translations$illust$related$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get failed => '相似作品載入失敗';
	@override String get empty => '暫無相似作品';
	@override String get viewMore => '查看更多相似作品';
}

// Path: novel.detail
class Translations$novel$detail$zh_Hant_TW extends Translations$novel$detail$en_US {
	Translations$novel$detail$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get images => '圖片';
	@override String get series => '系列';
	@override String get content => '正文';
	@override String get startReading => '開始閱讀';
	@override String totalChars({required Object count}) => '共 ${count} 字';
	@override String paragraphCount({required Object count}) => '${count} 段';
	@override String segmentCount({required Object count}) => '${count} 頁';
}

// Path: novel.reader
class Translations$novel$reader$zh_Hant_TW extends Translations$novel$reader$en_US {
	Translations$novel$reader$zh_Hant_TW.internal(TranslationsZhHantTw root) : this._root = root, super.internal(root);

	final TranslationsZhHantTw _root; // ignore: unused_field

	// Translations
	@override String get title => '閱讀';
	@override String get body => '正文';
	@override String get chapters => '章節';
	@override String get settings => '閱讀設定';
	@override String get emptyBody => '正文為空';
	@override String totalChars({required Object count}) => '共 ${count} 字';
	@override String pagePosition({required Object current, required Object total}) => '${current} / ${total} 頁';
	@override String pageTotal({required Object total}) => '${total} 頁';
	@override String currentPage({required Object page}) => '第 ${page} 頁';
	@override String get readingProgress => '閱讀進度';
	@override String get previousPage => '上一頁';
	@override String get nextPage => '下一頁';
	@override String get display => '顯示';
	@override String get fontSize => '字號';
	@override String get lineHeight => '行距';
	@override String get noChapterMarkers => '沒有章節標記';
	@override String get close => '關閉';
	@override String get decrease => '減小';
	@override String get increase => '增大';
	@override String get shortcutsTitle => '快捷鍵';
	@override String get shortcutsHelp => '左右鍵或 A/D 翻頁，上下鍵或 W/S 捲動';
}

/// The flat map containing all translations for locale <zh-Hant-TW>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZhHantTw {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'freepiv',
			'navigation.home' => '首頁',
			'navigation.search' => '搜尋',
			'navigation.newest' => '最新',
			'navigation.ranking' => '排行榜',
			'navigation.me' => '我的',
			'navigation.settings' => '設定',
			'common.back' => '返回',
			'common.cancel' => '取消',
			'common.retry' => '重試',
			'common.send' => '傳送',
			'common.filter' => '篩選',
			'common.type' => '類型',
			'common.id' => 'ID',
			'common.error' => '錯誤',
			'common.notFound' => '找不到',
			'common.copy' => ({required Object label}) => '複製${label}',
			'common.labelValue' => ({required Object label, required Object value}) => '${label}：${value}',
			'common.errorWithCause' => ({required Object message, required Object cause}) => '${message}：${cause}',
			'refresh.pullToRefresh' => '下拉重新整理',
			'refresh.releaseToRefresh' => '放開重新整理',
			'refresh.refreshing' => '正在重新整理',
			'refresh.refreshComplete' => '重新整理完成',
			'refresh.refreshFailed' => '重新整理失敗',
			'refresh.pullToLoadMore' => '上拉載入更多',
			'refresh.releaseToLoad' => '放開載入',
			'refresh.loading' => '載入中',
			'refresh.loadComplete' => '載入完成',
			'refresh.noMoreItems' => '沒有更多內容',
			'refresh.loadFailed' => '載入失敗',
			'refresh.lastUpdated' => '最後更新 %T',
			'toast.bookmarkFailed' => '收藏失敗',
			'toast.followFailed' => '關注失敗',
			'login.title' => '登入',
			'login.notSignedIn' => '尚未登入 Pixiv',
			'login.signedInAs' => ({required Object name}) => '已登入為 ${name}',
			'login.signInToPixiv' => '登入 Pixiv',
			'login.signInAgain' => '重新登入',
			'login.openingBrowser' => '正在開啟瀏覽器…',
			'login.apiNotInitialized' => 'Pixiv API 尚未初始化。',
			'login.desktopOnly' => '系統瀏覽器登入目前僅支援 Linux、macOS 與 Windows。',
			'login.openedInBrowser' => '已在系統瀏覽器開啟 Pixiv 登入。完成登入後請返回應用程式。',
			'login.callbackMissingCode' => ({required Object uri}) => 'Pixiv 回呼缺少 code：${uri}',
			'login.callbackReceived' => '已收到 Pixiv 回呼，正在取得權杖。',
			'login.browserOpenUnsupported' => '目前環境尚未實作系統瀏覽器開啟功能。',
			'login.browserOpenFailed' => ({required Object browser, required Object output}) => '${browser} 無法開啟登入連結：${output}',
			'login.proxyHint' => '如果你使用了網路代理，請在此設定代理地址再進行登入。',
			'settings.theme.title' => '主題',
			'settings.theme.system' => '跟隨系統',
			'settings.theme.light' => '淺色',
			'settings.theme.dark' => '深色',
			'settings.language.title' => '語言',
			'settings.language.systemDefault' => '跟隨系統',
			'settings.language.enUs' => 'English (United States)',
			'settings.language.zhCn' => '简体中文',
			'settings.language.zhTw' => '繁體中文',
			'settings.language.jaJp' => '日本語',
			'settings.images.title' => '圖片',
			'settings.images.previewQuality' => '預覽品質',
			'settings.images.viewerQuality' => '檢視品質',
			'settings.images.medium' => '中等',
			'settings.images.large' => '大圖',
			'settings.images.original' => '原圖',
			'settings.downloads.title' => '下載',
			'settings.downloads.savePath' => '儲存路徑',
			'settings.downloads.chooseFolder' => '選擇資料夾',
			'settings.downloads.dialogTitle' => '下載儲存路徑',
			'settings.downloads.defaultPath' => '預設',
			'settings.downloads.customPath' => '自訂',
			'settings.downloads.systemDownloadsFolder' => '系統下載資料夾',
			'settings.downloads.noFolderSelected' => '尚未選擇資料夾',
			'settings.downloads.directorySet' => ({required Object path}) => '下載目錄已設定：${path}',
			'settings.downloads.directoryUnavailable' => '下載目錄不可用',
			'settings.downloads.maxConcurrentDownloads' => '最大同時下載數量',
			'settings.downloads.maxConcurrentDownloadsSubtitle' => ({required Object count}) => '目前最多同時下載 ${count} 個任務，後續任務會排隊等待。',
			'settings.downloads.tasksTitle' => '下載任務',
			'settings.downloads.openTasks' => '下載任務',
			'settings.downloads.openTasksSubtitle' => '檢視進度、失敗項目和已儲存檔案',
			'settings.downloads.noTasks' => '尚無下載任務',
			'settings.downloads.noTasksMessage' => '下載的圖片會顯示在這裡。',
			'settings.downloads.total' => '總數',
			'settings.downloads.active' => '進行中',
			'settings.downloads.saved' => '已儲存',
			'settings.downloads.failed' => '失敗',
			'settings.downloads.downloading' => '正在下載',
			'settings.downloads.needsAttention' => '需要處理',
			'settings.downloads.completed' => '已完成',
			'settings.downloads.queued' => '佇列中',
			'settings.downloads.running' => '正在下載',
			'settings.downloads.paused' => '已暫停',
			'settings.downloads.downloaded' => '已下載',
			'settings.downloads.cancelled' => '已取消',
			'settings.downloads.savePending' => '等待儲存',
			'settings.downloads.saving' => '正在儲存',
			'settings.downloads.saveFailed' => '儲存失敗',
			'settings.downloads.retrySave' => '重試儲存',
			'settings.downloads.cancel' => '取消',
			'settings.downloads.deleteTask' => '刪除任務',
			'settings.downloads.sync' => '同步',
			'settings.downloads.syncFailed' => '下載狀態同步失敗',
			'settings.downloads.actionFailed' => '下載操作失敗',
			'settings.downloads.expand' => '展開',
			'settings.downloads.collapse' => '收合',
			'settings.proxy.title' => '網路代理',
			'settings.proxy.shortTitle' => '代理',
			'settings.proxy.subtitle' => '儲存後 Pixiv API 和圖片請求會使用所選代理。',
			'settings.proxy.open' => '設定代理',
			'settings.proxy.enabled' => '啟用代理',
			'settings.proxy.enabledStatus' => '代理已開啟',
			'settings.proxy.disabledStatus' => '直連',
			'settings.proxy.protocol' => '代理協定',
			'settings.proxy.protocolHttp' => 'HTTP',
			'settings.proxy.protocolSocks' => 'SOCKS',
			'settings.proxy.address' => 'IP 位址',
			'settings.proxy.addressHint' => '127.0.0.1',
			'settings.proxy.port' => '連接埠',
			'settings.proxy.portHint' => '7890',
			'settings.proxy.helper' => 'IP 和連接埠分開填寫，例如 127.0.0.1 和 7890。',
			'settings.proxy.save' => '儲存',
			'settings.proxy.saved' => '代理設定已儲存',
			'settings.proxy.required' => '啟用代理前需要填寫 IP 和連接埠。',
			'settings.proxy.invalid' => '請輸入有效的 IP 和連接埠。',
			'settings.proxy.hostRequired' => '請輸入 IP。',
			'settings.proxy.portRequired' => '請輸入連接埠。',
			'settings.proxy.invalidHost' => '請輸入有效的 IP 或主機名稱。',
			'settings.proxy.invalidPort' => '連接埠範圍為 1-65535。',
			'settings.proxy.loadSystem' => '取得系統代理',
			'settings.proxy.systemLoaded' => '已取得系統代理',
			'settings.proxy.systemNotFound' => '未偵測到系統代理',
			'settings.proxy.systemUnsupported' => '僅桌面端支援取得系統代理',
			'settings.proxy.systemLoadFailed' => '取得系統代理失敗',
			'settings.proxy.entrySubtitleOn' => ({required Object url}) => '已開啟：${url}',
			'settings.proxy.entrySubtitleOff' => '未開啟',
			'settings.account.title' => '帳號',
			'settings.account.signedOutSubtitle' => '登入後顯示 Pixiv 帳號',
			'settings.account.notSignedIn' => '尚未登入',
			'settings.account.signOut' => '登出',
			'me.openProfile' => '開啟個人頁',
			'me.following' => '我的關注',
			'me.followers' => '我的粉絲',
			'me.emptyFollowing' => '尚無關注使用者',
			'me.emptyFollowers' => '尚無粉絲',
			'me.about' => '關於',
			'me.aboutSubtitle' => '版本、更新和專案連結',
			'me.settings' => '設定',
			'me.settingsSubtitle' => '主題、語言、圖片和下載',
			'about.title' => '關於',
			'about.appName' => 'freepiv',
			'about.subtitle' => '用於瀏覽 Pixiv 內容的輕量客戶端。你可以在這裡查看目前版本、檢查更新並開啟專案下載頁面。',
			'about.project' => '專案',
			'about.projectPage' => '專案首頁',
			'about.releasePage' => '發布頁面',
			'about.versionInfo' => '版本資訊',
			'about.appVersion' => '應用程式版本',
			'about.latestVersion' => '最新版本',
			'about.currentVersion' => ({required Object version, required Object buildNumber}) => '目前版本 ${version}+${buildNumber}',
			'about.noCachedUpdate' => '暫無可用更新',
			'about.loading' => '載入中',
			'about.community' => '社群',
			'about.telegram' => 'Telegram',
			'about.discord' => 'Discord',
			'about.checkUpdate' => '檢查更新',
			'about.checkingUpdateShort' => '檢查中',
			'about.checkingUpdate' => '正在檢查更新…',
			'about.noUpdate' => '目前已是最新版本',
			'about.updateAvailable' => ({required Object version, required Object buildNumber}) => '發現新版本 ${version}+${buildNumber}',
			'about.checkUpdateFailed' => '檢查更新失敗',
			'about.downloadPage' => '下載頁面',
			'about.downloadAssetUnavailable' => '找不到適合目前平台的下載項目，已開啟發布頁面。',
			'about.openDownloadFailed' => '開啟下載頁面失敗',
			'about.openLinkFailed' => '開啟連結失敗',
			'home.emptyTitle' => '尚無推薦',
			'home.emptyMessage' => '下拉即可重新取得推薦。',
			'home.rankings' => '排行榜',
			'home.seeMore' => '查看更多',
			'home.recommended' => '推薦',
			'home.illustrations' => '插畫',
			'home.manga' => '漫畫',
			'home.novels' => '小說',
			'home.users' => '使用者',
			'ranking.emptyTitle' => '暫無排行榜作品',
			'ranking.emptyMessage' => '下拉即可重新取得排行榜。',
			'ranking.types.illustrations' => '插畫',
			'ranking.types.manga' => '漫畫',
			'ranking.types.novels' => '小說',
			'ranking.modes.day' => '每日',
			'ranking.modes.dayR18' => '每日 R-18',
			'ranking.modes.dayMale' => '男性每日',
			'ranking.modes.dayMaleR18' => '男性每日 R-18',
			'ranking.modes.dayFemale' => '女性每日',
			'ranking.modes.dayFemaleR18' => '女性每日 R-18',
			'ranking.modes.dayAi' => 'AI 生成',
			'ranking.modes.dayR18Ai' => 'AI 生成 R-18',
			'ranking.modes.week' => '每週',
			'ranking.modes.weekR18' => '每週 R-18',
			'ranking.modes.weekOriginal' => '原創每週',
			'ranking.modes.weekRookie' => '新人每週',
			'ranking.modes.month' => '每月',
			'search.placeholder' => '搜尋標籤、作品 ID 或使用者 ID',
			'search.submit' => '搜尋',
			'search.trendingTags' => '熱門標籤',
			'search.emptyTrendingTitle' => '尚無熱門標籤',
			'search.emptyTrendingMessage' => '下拉即可重新取得熱門標籤。',
			'search.noSuggestions' => '沒有候選詞',
			'search.filters.title' => '搜尋篩選',
			'search.filters.sort' => '排序',
			'search.filters.target' => '目標',
			'search.filters.date' => '日期',
			'search.filters.bookmarks' => '收藏數',
			'search.type.illustManga' => '插畫&漫畫',
			'search.type.novel' => '小說',
			'search.type.user' => '使用者',
			'search.sort.newest' => '最新',
			'search.sort.oldest' => '最舊',
			'search.sort.popular' => '熱門',
			'search.target.tags' => '標籤',
			'search.target.exactTags' => '精確標籤',
			'search.target.titleAndCaption' => '標題與說明',
			'search.date.any' => '任意日期',
			'search.date.today' => '今天',
			'search.date.days7' => '7 天',
			'search.date.month1' => '1 個月',
			'search.date.months6' => '6 個月',
			'search.date.year1' => '1 年',
			'search.date.custom' => '自訂',
			'search.bookmarks.any' => '任意收藏數',
			'search.bookmarks.atLeast' => ({required Object count}) => '${count}+ 收藏',
			'search.direct.illust' => ({required Object id}) => '插畫：${id}',
			'search.direct.user' => ({required Object id}) => '使用者：${id}',
			'search.direct.novel' => ({required Object id}) => '小說：${id}',
			'search.empty.illustrations' => '找不到插畫',
			'search.empty.novels' => '找不到小說',
			'search.empty.users' => '找不到使用者',
			'user.tabs.illustrations' => '插畫',
			'user.tabs.manga' => '漫畫',
			'user.tabs.novels' => '小說',
			'user.tabs.bookmarks' => '收藏',
			'user.tabs.following' => '關注',
			'user.tabs.profile' => '詳細資訊',
			'user.stats.illustrations' => '插畫',
			'user.stats.manga' => '漫畫',
			'user.stats.novels' => '小說',
			'user.stats.following' => '關注',
			'user.bookmarks.illustManga' => '插畫&漫畫',
			'user.bookmarks.novels' => '小說',
			'user.empty.illustrations' => '尚無插畫',
			'user.empty.manga' => '尚無漫畫',
			'user.empty.novels' => '尚無小說',
			'user.empty.bookmarkIllustrations' => '尚無公開插畫或漫畫收藏',
			'user.empty.bookmarkNovels' => '尚無公開小說收藏',
			'user.empty.following' => '尚無關注使用者',
			'user.empty.profile' => '尚無公開詳細資訊',
			'user.profile.birthday' => '生日',
			'user.profile.region' => '地區',
			'user.profile.job' => '職業',
			'user.profile.webpage' => '主頁',
			'user.profile.twitter' => 'Twitter',
			'user.profile.pawoo' => 'Pawoo',
			'user.profile.openLink' => '開啟連結',
			'user.meta.novelChars' => ({required Object count}) => '${count} 字',
			'user.meta.novelPages' => ({required Object count}) => '${count} 頁',
			'user.error.missingUser' => '缺少使用者 ID 或使用者詳細資訊。',
			'newest.audience.following' => '關注',
			'newest.audience.mypixiv' => '好P友',
			'newest.audience.everyone' => '所有人',
			'newest.workType.illustManga' => '插畫&漫畫',
			'newest.workType.illust' => '插畫',
			'newest.workType.manga' => '漫畫',
			'newest.workType.novel' => '小說',
			'newest.workType.compactArt' => '作品',
			'newest.workType.compactIllust' => '插畫',
			'newest.workType.compactManga' => '漫畫',
			'newest.workType.compactNovel' => '小說',
			'newest.followScope.title' => '關注範圍',
			'newest.followScope.all' => '全部關注',
			'newest.followScope.private' => '私人關注',
			'newest.followScope.public' => '公開關注',
			'newest.followScope.compactAll' => '全部',
			'newest.followScope.compactPrivate' => '私人',
			'newest.followScope.compactPublic' => '公開',
			'newest.emptyTitle' => '尚無最新作品',
			'newest.compactFilter' => ({required Object workType, required Object scope}) => '${workType} · ${scope}',
			'newest.novelChars' => ({required Object count}) => '${count} 字',
			'newest.novelPages' => ({required Object count}) => '${count} 頁',
			'illust.contextMenu.download' => '下載',
			'illust.contextMenu.downloadAll' => '下載全部',
			'illust.contextMenu.copyImage' => '複製圖像',
			'illust.imageLabels.original' => '原圖',
			'illust.imageLabels.large' => '大圖',
			'illust.toast.downloadStarted' => '開始下載圖片',
			'illust.toast.downloadAllQueued' => ({required Object count}) => '已加入下載佇列：${count} 張圖片',
			'illust.toast.downloadComplete' => ({required Object path}) => '下載完成：${path}',
			'illust.toast.downloadFailed' => '下載失敗',
			'illust.toast.copying' => ({required Object label}) => '正在複製${label}',
			'illust.toast.copied' => ({required Object label}) => '已複製${label}',
			'illust.toast.copiedValue' => ({required Object label, required Object value}) => '已複製${label}：${value}',
			'illust.toast.copyFailed' => ({required Object label}) => '複製${label}失敗',
			'illust.tooltip.previousImage' => '上一張圖片',
			'illust.tooltip.nextImage' => '下一張圖片',
			'illust.tooltip.backToDetail' => '回到圖片詳細資訊',
			'illust.tooltip.removeBookmark' => '移除收藏',
			'illust.tooltip.addBookmark' => '加入收藏',
			'illust.section.tags' => '標籤',
			'illust.section.caption' => '說明',
			'illust.section.details' => '詳細資訊',
			'illust.section.creator' => '作者',
			'illust.section.recentWorks' => '近期作品',
			'illust.section.comments' => '留言',
			'illust.section.commentsWithCount' => ({required Object count}) => '留言（${count}）',
			'illust.section.relatedWorks' => '相似作品',
			'illust.metadata.type' => '類型',
			'illust.metadata.created' => '建立時間',
			'illust.badge.aiArtwork' => 'AI 作品',
			'illust.badge.original' => '原創',
			'illust.stats.size' => '尺寸',
			'illust.stats.views' => '瀏覽',
			'illust.stats.bookmarks' => '收藏',
			'illust.stats.pages' => '頁數',
			'illust.tags.none' => '沒有標籤',
			'illust.tags.tag' => '標籤',
			'illust.comments.failed' => '留言載入失敗',
			'illust.comments.empty' => '尚無留言',
			'illust.comments.moreAvailable' => '還有更多留言',
			'illust.comments.hasReplies' => '有回覆',
			'illust.comments.open' => '開啟留言',
			'illust.comments.reply' => '回覆',
			'illust.comments.replyingTo' => ({required Object name}) => '正在回覆 ${name}',
			'illust.comments.loadReplies' => '載入回覆',
			'illust.comments.loadMoreReplies' => '載入更多回覆',
			'illust.comments.repliesFailed' => '回覆載入失敗',
			'illust.comments.sendFailed' => '留言傳送失敗',
			'illust.comments.delete' => '刪除',
			'illust.comments.deleteFailed' => '留言刪除失敗',
			'illust.comments.inputHint' => '寫下留言',
			'illust.comments.replyInputHint' => ({required Object name}) => '回覆 ${name}',
			'illust.comments.emoji' => '表情',
			'illust.comments.stamp' => '貼圖',
			'illust.works.failed' => '作品載入失敗',
			'illust.works.empty' => '暫無可顯示作品',
			'illust.related.failed' => '相似作品載入失敗',
			'illust.related.empty' => '暫無相似作品',
			'illust.related.viewMore' => '查看更多相似作品',
			'novel.detail.images' => '圖片',
			'novel.detail.series' => '系列',
			'novel.detail.content' => '正文',
			'novel.detail.startReading' => '開始閱讀',
			'novel.detail.totalChars' => ({required Object count}) => '共 ${count} 字',
			'novel.detail.paragraphCount' => ({required Object count}) => '${count} 段',
			'novel.detail.segmentCount' => ({required Object count}) => '${count} 頁',
			'novel.reader.title' => '閱讀',
			'novel.reader.body' => '正文',
			'novel.reader.chapters' => '章節',
			'novel.reader.settings' => '閱讀設定',
			'novel.reader.emptyBody' => '正文為空',
			'novel.reader.totalChars' => ({required Object count}) => '共 ${count} 字',
			'novel.reader.pagePosition' => ({required Object current, required Object total}) => '${current} / ${total} 頁',
			'novel.reader.pageTotal' => ({required Object total}) => '${total} 頁',
			'novel.reader.currentPage' => ({required Object page}) => '第 ${page} 頁',
			'novel.reader.readingProgress' => '閱讀進度',
			'novel.reader.previousPage' => '上一頁',
			'novel.reader.nextPage' => '下一頁',
			'novel.reader.display' => '顯示',
			'novel.reader.fontSize' => '字號',
			'novel.reader.lineHeight' => '行距',
			'novel.reader.noChapterMarkers' => '沒有章節標記',
			'novel.reader.close' => '關閉',
			'novel.reader.decrease' => '減小',
			'novel.reader.increase' => '增大',
			'novel.reader.shortcutsTitle' => '快捷鍵',
			'novel.reader.shortcutsHelp' => '左右鍵或 A/D 翻頁，上下鍵或 W/S 捲動',
			'follow.tooltipFollow' => '關注使用者',
			'follow.tooltipUnfollow' => '取消關注',
			'follow.followed' => '已關注',
			'follow.notFollowed' => '未關注',
			'richText.twitterUser' => ({required Object username}) => 'Twitter：${username}',
			'richText.illustId' => ({required Object id}) => '插畫 ID：${id}',
			'richText.userId' => ({required Object id}) => '使用者 ID：${id}',
			_ => null,
		};
	}
}
