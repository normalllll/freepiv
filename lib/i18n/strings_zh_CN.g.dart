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
class TranslationsZhCn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZhCn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhCn,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh-CN>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsZhCn _root = this; // ignore: unused_field

	@override 
	TranslationsZhCn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZhCn(meta: meta ?? this.$meta);

	// Translations
	@override late final Translations$app$zh_CN app = Translations$app$zh_CN.internal(_root);
	@override late final Translations$navigation$zh_CN navigation = Translations$navigation$zh_CN.internal(_root);
	@override late final Translations$common$zh_CN common = Translations$common$zh_CN.internal(_root);
	@override late final Translations$refresh$zh_CN refresh = Translations$refresh$zh_CN.internal(_root);
	@override late final Translations$toast$zh_CN toast = Translations$toast$zh_CN.internal(_root);
	@override late final Translations$login$zh_CN login = Translations$login$zh_CN.internal(_root);
	@override late final Translations$settings$zh_CN settings = Translations$settings$zh_CN.internal(_root);
	@override late final Translations$me$zh_CN me = Translations$me$zh_CN.internal(_root);
	@override late final Translations$home$zh_CN home = Translations$home$zh_CN.internal(_root);
	@override late final Translations$ranking$zh_CN ranking = Translations$ranking$zh_CN.internal(_root);
	@override late final Translations$search$zh_CN search = Translations$search$zh_CN.internal(_root);
	@override late final Translations$user$zh_CN user = Translations$user$zh_CN.internal(_root);
	@override late final Translations$newest$zh_CN newest = Translations$newest$zh_CN.internal(_root);
	@override late final Translations$illust$zh_CN illust = Translations$illust$zh_CN.internal(_root);
	@override late final Translations$novel$zh_CN novel = Translations$novel$zh_CN.internal(_root);
	@override late final Translations$follow$zh_CN follow = Translations$follow$zh_CN.internal(_root);
	@override late final Translations$richText$zh_CN richText = Translations$richText$zh_CN.internal(_root);
}

// Path: app
class Translations$app$zh_CN extends Translations$app$en_US {
	Translations$app$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => 'freepiv';
}

// Path: navigation
class Translations$navigation$zh_CN extends Translations$navigation$en_US {
	Translations$navigation$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get home => '首页';
	@override String get search => '搜索';
	@override String get newest => '最新';
	@override String get ranking => '排行榜';
	@override String get me => '我的';
	@override String get settings => '设置';
}

// Path: common
class Translations$common$zh_CN extends Translations$common$en_US {
	Translations$common$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get back => '返回';
	@override String get cancel => '取消';
	@override String get retry => '重试';
	@override String get send => '发送';
	@override String get filter => '筛选';
	@override String get type => '类型';
	@override String get id => 'ID';
	@override String get error => '错误';
	@override String get notFound => '未找到';
	@override String copy({required Object label}) => '复制${label}';
	@override String labelValue({required Object label, required Object value}) => '${label}：${value}';
	@override String errorWithCause({required Object message, required Object cause}) => '${message}：${cause}';
}

// Path: refresh
class Translations$refresh$zh_CN extends Translations$refresh$en_US {
	Translations$refresh$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get pullToRefresh => '下拉刷新';
	@override String get releaseToRefresh => '松开刷新';
	@override String get refreshing => '正在刷新';
	@override String get refreshComplete => '刷新完成';
	@override String get refreshFailed => '刷新失败';
	@override String get pullToLoadMore => '上拉加载更多';
	@override String get releaseToLoad => '松开加载';
	@override String get loading => '正在加载';
	@override String get loadComplete => '加载完成';
	@override String get noMoreItems => '没有更多内容';
	@override String get loadFailed => '加载失败';
	@override String get lastUpdated => '最后更新 %T';
}

// Path: toast
class Translations$toast$zh_CN extends Translations$toast$en_US {
	Translations$toast$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get bookmarkFailed => '收藏失败';
	@override String get followFailed => '关注失败';
}

// Path: login
class Translations$login$zh_CN extends Translations$login$en_US {
	Translations$login$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '登录';
	@override String get notSignedIn => '未登录 Pixiv';
	@override String signedInAs({required Object name}) => '已登录为 ${name}';
	@override String get signInToPixiv => '登录 Pixiv';
	@override String get signInAgain => '重新登录';
	@override String get openingBrowser => '正在打开浏览器…';
	@override String get apiNotInitialized => 'Pixiv API 尚未初始化。';
	@override String get desktopOnly => '系统浏览器登录目前仅支持 Linux、macOS 和 Windows。';
	@override String get openedInBrowser => '已在系统浏览器中打开 Pixiv 登录。完成登录后请返回应用。';
	@override String callbackMissingCode({required Object uri}) => 'Pixiv 回调缺少 code：${uri}';
	@override String get callbackReceived => '已收到 Pixiv 回调，正在获取令牌。';
	@override String get browserOpenUnsupported => '当前环境尚未实现系统浏览器打开功能。';
	@override String browserOpenFailed({required Object browser, required Object output}) => '${browser} 打开登录链接失败：${output}';
	@override String get proxyHint => '如果你使用了网路代理请在此设置代理地址再进行登录。';
}

// Path: settings
class Translations$settings$zh_CN extends Translations$settings$en_US {
	Translations$settings$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override late final Translations$settings$theme$zh_CN theme = Translations$settings$theme$zh_CN.internal(_root);
	@override late final Translations$settings$language$zh_CN language = Translations$settings$language$zh_CN.internal(_root);
	@override late final Translations$settings$images$zh_CN images = Translations$settings$images$zh_CN.internal(_root);
	@override late final Translations$settings$downloads$zh_CN downloads = Translations$settings$downloads$zh_CN.internal(_root);
	@override late final Translations$settings$proxy$zh_CN proxy = Translations$settings$proxy$zh_CN.internal(_root);
	@override late final Translations$settings$account$zh_CN account = Translations$settings$account$zh_CN.internal(_root);
}

// Path: me
class Translations$me$zh_CN extends Translations$me$en_US {
	Translations$me$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get openProfile => '打开个人主页';
	@override String get following => '我的关注';
	@override String get followers => '我的粉丝';
	@override String get emptyFollowing => '暂无关注用户';
	@override String get emptyFollowers => '暂无粉丝';
	@override String get settings => '设置';
	@override String get settingsSubtitle => '主题、语言、图片和下载';
}

// Path: home
class Translations$home$zh_CN extends Translations$home$en_US {
	Translations$home$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get emptyTitle => '暂无推荐';
	@override String get emptyMessage => '下拉即可重新获取推荐。';
	@override String get rankings => '排行榜';
	@override String get seeMore => '查看更多';
	@override String get recommended => '推荐';
	@override String get illustrations => '插画';
	@override String get manga => '漫画';
	@override String get novels => '小说';
	@override String get users => '用户';
}

// Path: ranking
class Translations$ranking$zh_CN extends Translations$ranking$en_US {
	Translations$ranking$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get emptyTitle => '暂无排行榜作品';
	@override String get emptyMessage => '下拉即可重新获取排行榜。';
	@override late final Translations$ranking$types$zh_CN types = Translations$ranking$types$zh_CN.internal(_root);
	@override late final Translations$ranking$modes$zh_CN modes = Translations$ranking$modes$zh_CN.internal(_root);
}

// Path: search
class Translations$search$zh_CN extends Translations$search$en_US {
	Translations$search$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get placeholder => '搜索标签、作品 ID 或用户 ID';
	@override String get submit => '搜索';
	@override String get trendingTags => '热门标签';
	@override String get emptyTrendingTitle => '暂无热门标签';
	@override String get emptyTrendingMessage => '下拉即可重新获取热门标签。';
	@override String get noSuggestions => '没有候选词';
	@override late final Translations$search$filters$zh_CN filters = Translations$search$filters$zh_CN.internal(_root);
	@override late final Translations$search$type$zh_CN type = Translations$search$type$zh_CN.internal(_root);
	@override late final Translations$search$sort$zh_CN sort = Translations$search$sort$zh_CN.internal(_root);
	@override late final Translations$search$target$zh_CN target = Translations$search$target$zh_CN.internal(_root);
	@override late final Translations$search$date$zh_CN date = Translations$search$date$zh_CN.internal(_root);
	@override late final Translations$search$bookmarks$zh_CN bookmarks = Translations$search$bookmarks$zh_CN.internal(_root);
	@override late final Translations$search$direct$zh_CN direct = Translations$search$direct$zh_CN.internal(_root);
	@override late final Translations$search$empty$zh_CN empty = Translations$search$empty$zh_CN.internal(_root);
}

// Path: user
class Translations$user$zh_CN extends Translations$user$en_US {
	Translations$user$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override late final Translations$user$tabs$zh_CN tabs = Translations$user$tabs$zh_CN.internal(_root);
	@override late final Translations$user$stats$zh_CN stats = Translations$user$stats$zh_CN.internal(_root);
	@override late final Translations$user$bookmarks$zh_CN bookmarks = Translations$user$bookmarks$zh_CN.internal(_root);
	@override late final Translations$user$empty$zh_CN empty = Translations$user$empty$zh_CN.internal(_root);
	@override late final Translations$user$profile$zh_CN profile = Translations$user$profile$zh_CN.internal(_root);
	@override late final Translations$user$meta$zh_CN meta = Translations$user$meta$zh_CN.internal(_root);
	@override late final Translations$user$error$zh_CN error = Translations$user$error$zh_CN.internal(_root);
}

// Path: newest
class Translations$newest$zh_CN extends Translations$newest$en_US {
	Translations$newest$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override late final Translations$newest$audience$zh_CN audience = Translations$newest$audience$zh_CN.internal(_root);
	@override late final Translations$newest$workType$zh_CN workType = Translations$newest$workType$zh_CN.internal(_root);
	@override late final Translations$newest$followScope$zh_CN followScope = Translations$newest$followScope$zh_CN.internal(_root);
	@override String get emptyTitle => '暂无最新作品';
	@override String compactFilter({required Object workType, required Object scope}) => '${workType} · ${scope}';
	@override String novelChars({required Object count}) => '${count} 字';
	@override String novelPages({required Object count}) => '${count} 页';
}

// Path: illust
class Translations$illust$zh_CN extends Translations$illust$en_US {
	Translations$illust$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override late final Translations$illust$contextMenu$zh_CN contextMenu = Translations$illust$contextMenu$zh_CN.internal(_root);
	@override late final Translations$illust$imageLabels$zh_CN imageLabels = Translations$illust$imageLabels$zh_CN.internal(_root);
	@override late final Translations$illust$toast$zh_CN toast = Translations$illust$toast$zh_CN.internal(_root);
	@override late final Translations$illust$tooltip$zh_CN tooltip = Translations$illust$tooltip$zh_CN.internal(_root);
	@override late final Translations$illust$section$zh_CN section = Translations$illust$section$zh_CN.internal(_root);
	@override late final Translations$illust$metadata$zh_CN metadata = Translations$illust$metadata$zh_CN.internal(_root);
	@override late final Translations$illust$badge$zh_CN badge = Translations$illust$badge$zh_CN.internal(_root);
	@override late final Translations$illust$stats$zh_CN stats = Translations$illust$stats$zh_CN.internal(_root);
	@override late final Translations$illust$tags$zh_CN tags = Translations$illust$tags$zh_CN.internal(_root);
	@override late final Translations$illust$comments$zh_CN comments = Translations$illust$comments$zh_CN.internal(_root);
	@override late final Translations$illust$works$zh_CN works = Translations$illust$works$zh_CN.internal(_root);
	@override late final Translations$illust$related$zh_CN related = Translations$illust$related$zh_CN.internal(_root);
}

// Path: novel
class Translations$novel$zh_CN extends Translations$novel$en_US {
	Translations$novel$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override late final Translations$novel$detail$zh_CN detail = Translations$novel$detail$zh_CN.internal(_root);
	@override late final Translations$novel$reader$zh_CN reader = Translations$novel$reader$zh_CN.internal(_root);
}

// Path: follow
class Translations$follow$zh_CN extends Translations$follow$en_US {
	Translations$follow$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get tooltipFollow => '关注用户';
	@override String get tooltipUnfollow => '取消关注';
	@override String get followed => '已关注';
	@override String get notFollowed => '未关注';
}

// Path: richText
class Translations$richText$zh_CN extends Translations$richText$en_US {
	Translations$richText$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String twitterUser({required Object username}) => 'Twitter：${username}';
	@override String illustId({required Object id}) => '插画 ID：${id}';
	@override String userId({required Object id}) => '用户 ID：${id}';
}

// Path: settings.theme
class Translations$settings$theme$zh_CN extends Translations$settings$theme$en_US {
	Translations$settings$theme$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '主题';
	@override String get system => '跟随系统';
	@override String get light => '浅色';
	@override String get dark => '深色';
}

// Path: settings.language
class Translations$settings$language$zh_CN extends Translations$settings$language$en_US {
	Translations$settings$language$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '语言';
	@override String get systemDefault => '跟随系统';
	@override String get enUs => 'English (United States)';
	@override String get zhCn => '简体中文';
	@override String get zhTw => '繁體中文';
	@override String get jaJp => '日本語';
}

// Path: settings.images
class Translations$settings$images$zh_CN extends Translations$settings$images$en_US {
	Translations$settings$images$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '图片';
	@override String get previewQuality => '预览质量';
	@override String get viewerQuality => '查看质量';
	@override String get medium => '中等';
	@override String get large => '大图';
	@override String get original => '原图';
}

// Path: settings.downloads
class Translations$settings$downloads$zh_CN extends Translations$settings$downloads$en_US {
	Translations$settings$downloads$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '下载';
	@override String get savePath => '保存路径';
	@override String get chooseFolder => '选择文件夹';
	@override String get dialogTitle => '下载保存路径';
	@override String get defaultPath => '默认';
	@override String get customPath => '自定义';
	@override String get systemDownloadsFolder => '系统下载文件夹';
	@override String get noFolderSelected => '未选择文件夹';
	@override String directorySet({required Object path}) => '下载目录已设置：${path}';
	@override String get directoryUnavailable => '下载目录不可用';
	@override String get maxConcurrentDownloads => '最大同时下载数量';
	@override String maxConcurrentDownloadsSubtitle({required Object count}) => '当前最多同时下载 ${count} 个任务，后续任务会排队等待。';
	@override String get tasksTitle => '下载任务';
	@override String get openTasks => '下载任务';
	@override String get openTasksSubtitle => '查看进度、失败项和已保存文件';
	@override String get noTasks => '暂无下载任务';
	@override String get noTasksMessage => '下载的图片会显示在这里。';
	@override String get total => '总数';
	@override String get active => '进行中';
	@override String get saved => '已保存';
	@override String get failed => '失败';
	@override String get downloading => '正在下载';
	@override String get needsAttention => '需要处理';
	@override String get completed => '已完成';
	@override String get queued => '排队中';
	@override String get running => '正在下载';
	@override String get paused => '已暂停';
	@override String get downloaded => '已下载';
	@override String get cancelled => '已取消';
	@override String get savePending => '等待保存';
	@override String get saving => '正在保存';
	@override String get saveFailed => '保存失败';
	@override String get retrySave => '重试保存';
	@override String get cancel => '取消';
	@override String get deleteTask => '删除任务';
	@override String get sync => '同步';
	@override String get syncFailed => '下载状态同步失败';
	@override String get actionFailed => '下载操作失败';
	@override String get expand => '展开';
	@override String get collapse => '收起';
}

// Path: settings.proxy
class Translations$settings$proxy$zh_CN extends Translations$settings$proxy$en_US {
	Translations$settings$proxy$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '网络代理';
	@override String get shortTitle => '代理';
	@override String get subtitle => '保存后 Pixiv API 和图片请求会使用所选代理。';
	@override String get open => '设置代理';
	@override String get enabled => '启用代理';
	@override String get enabledStatus => '代理已开启';
	@override String get disabledStatus => '直连';
	@override String get protocol => '代理协议';
	@override String get protocolHttp => 'HTTP';
	@override String get protocolSocks => 'SOCKS';
	@override String get address => 'IP 地址';
	@override String get addressHint => '127.0.0.1';
	@override String get port => '端口号';
	@override String get portHint => '7890';
	@override String get helper => 'IP 和端口分开填写，例如 127.0.0.1 和 7890。';
	@override String get save => '保存';
	@override String get saved => '代理设置已保存';
	@override String get required => '启用代理前需要填写 IP 和端口。';
	@override String get invalid => '请输入有效的 IP 和端口。';
	@override String get hostRequired => '请输入 IP。';
	@override String get portRequired => '请输入端口。';
	@override String get invalidHost => '请输入有效的 IP 或主机名。';
	@override String get invalidPort => '端口范围为 1-65535。';
	@override String get loadSystem => '获取系统代理';
	@override String get systemLoaded => '已获取系统代理';
	@override String get systemNotFound => '未检测到系统代理';
	@override String get systemUnsupported => '仅桌面端支持获取系统代理';
	@override String get systemLoadFailed => '获取系统代理失败';
	@override String entrySubtitleOn({required Object url}) => '已开启：${url}';
	@override String get entrySubtitleOff => '未开启';
}

// Path: settings.account
class Translations$settings$account$zh_CN extends Translations$settings$account$en_US {
	Translations$settings$account$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '账号';
	@override String get signedOutSubtitle => '登录后显示 Pixiv 账号';
	@override String get notSignedIn => '未登录';
	@override String get signOut => '退出登录';
}

// Path: ranking.types
class Translations$ranking$types$zh_CN extends Translations$ranking$types$en_US {
	Translations$ranking$types$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get illustrations => '插画';
	@override String get manga => '漫画';
	@override String get novels => '小说';
}

// Path: ranking.modes
class Translations$ranking$modes$zh_CN extends Translations$ranking$modes$en_US {
	Translations$ranking$modes$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get day => '每日';
	@override String get dayR18 => '每日 R-18';
	@override String get dayMale => '男性每日';
	@override String get dayMaleR18 => '男性每日 R-18';
	@override String get dayFemale => '女性每日';
	@override String get dayFemaleR18 => '女性每日 R-18';
	@override String get dayAi => 'AI 生成';
	@override String get dayR18Ai => 'AI 生成 R-18';
	@override String get week => '每周';
	@override String get weekR18 => '每周 R-18';
	@override String get weekOriginal => '原创每周';
	@override String get weekRookie => '新人每周';
	@override String get month => '每月';
}

// Path: search.filters
class Translations$search$filters$zh_CN extends Translations$search$filters$en_US {
	Translations$search$filters$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '搜索筛选';
	@override String get sort => '排序';
	@override String get target => '目标';
	@override String get date => '日期';
	@override String get bookmarks => '收藏数';
}

// Path: search.type
class Translations$search$type$zh_CN extends Translations$search$type$en_US {
	Translations$search$type$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get illustManga => '插画&漫画';
	@override String get novel => '小说';
	@override String get user => '用户';
}

// Path: search.sort
class Translations$search$sort$zh_CN extends Translations$search$sort$en_US {
	Translations$search$sort$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get newest => '最新';
	@override String get oldest => '最旧';
	@override String get popular => '热门';
}

// Path: search.target
class Translations$search$target$zh_CN extends Translations$search$target$en_US {
	Translations$search$target$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get tags => '标签';
	@override String get exactTags => '精确标签';
	@override String get titleAndCaption => '标题与说明';
}

// Path: search.date
class Translations$search$date$zh_CN extends Translations$search$date$en_US {
	Translations$search$date$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get any => '任意日期';
	@override String get today => '今天';
	@override String get days7 => '7 天';
	@override String get month1 => '1 个月';
	@override String get months6 => '6 个月';
	@override String get year1 => '1 年';
	@override String get custom => '自定义';
}

// Path: search.bookmarks
class Translations$search$bookmarks$zh_CN extends Translations$search$bookmarks$en_US {
	Translations$search$bookmarks$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get any => '任意收藏数';
	@override String atLeast({required Object count}) => '${count}+ 收藏';
}

// Path: search.direct
class Translations$search$direct$zh_CN extends Translations$search$direct$en_US {
	Translations$search$direct$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String illust({required Object id}) => '插画：${id}';
	@override String user({required Object id}) => '用户：${id}';
	@override String novel({required Object id}) => '小说：${id}';
}

// Path: search.empty
class Translations$search$empty$zh_CN extends Translations$search$empty$en_US {
	Translations$search$empty$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get illustrations => '没有找到插画';
	@override String get novels => '没有找到小说';
	@override String get users => '没有找到用户';
}

// Path: user.tabs
class Translations$user$tabs$zh_CN extends Translations$user$tabs$en_US {
	Translations$user$tabs$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get illustrations => '插画';
	@override String get manga => '漫画';
	@override String get novels => '小说';
	@override String get bookmarks => '收藏';
	@override String get following => '关注';
	@override String get profile => '详细信息';
}

// Path: user.stats
class Translations$user$stats$zh_CN extends Translations$user$stats$en_US {
	Translations$user$stats$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get illustrations => '插画';
	@override String get manga => '漫画';
	@override String get novels => '小说';
	@override String get following => '关注';
}

// Path: user.bookmarks
class Translations$user$bookmarks$zh_CN extends Translations$user$bookmarks$en_US {
	Translations$user$bookmarks$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get illustManga => '插画&漫画';
	@override String get novels => '小说';
}

// Path: user.empty
class Translations$user$empty$zh_CN extends Translations$user$empty$en_US {
	Translations$user$empty$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get illustrations => '暂无插画';
	@override String get manga => '暂无漫画';
	@override String get novels => '暂无小说';
	@override String get bookmarkIllustrations => '暂无公开插画或漫画收藏';
	@override String get bookmarkNovels => '暂无公开小说收藏';
	@override String get following => '暂无关注用户';
	@override String get profile => '暂无公开详细信息';
}

// Path: user.profile
class Translations$user$profile$zh_CN extends Translations$user$profile$en_US {
	Translations$user$profile$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get birthday => '生日';
	@override String get region => '地区';
	@override String get job => '职业';
	@override String get webpage => '主页';
	@override String get twitter => 'Twitter';
	@override String get pawoo => 'Pawoo';
	@override String get openLink => '打开链接';
}

// Path: user.meta
class Translations$user$meta$zh_CN extends Translations$user$meta$en_US {
	Translations$user$meta$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String novelChars({required Object count}) => '${count} 字';
	@override String novelPages({required Object count}) => '${count} 页';
}

// Path: user.error
class Translations$user$error$zh_CN extends Translations$user$error$en_US {
	Translations$user$error$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get missingUser => '缺少用户 ID 或用户详情。';
}

// Path: newest.audience
class Translations$newest$audience$zh_CN extends Translations$newest$audience$en_US {
	Translations$newest$audience$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get following => '关注';
	@override String get mypixiv => '好P友';
	@override String get everyone => '所有人';
}

// Path: newest.workType
class Translations$newest$workType$zh_CN extends Translations$newest$workType$en_US {
	Translations$newest$workType$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get illustManga => '插画&漫画';
	@override String get illust => '插画';
	@override String get manga => '漫画';
	@override String get novel => '小说';
	@override String get compactArt => '作品';
	@override String get compactIllust => '插画';
	@override String get compactManga => '漫画';
	@override String get compactNovel => '小说';
}

// Path: newest.followScope
class Translations$newest$followScope$zh_CN extends Translations$newest$followScope$en_US {
	Translations$newest$followScope$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '关注范围';
	@override String get all => '全部关注';
	@override String get private => '私密关注';
	@override String get public => '公开关注';
	@override String get compactAll => '全部';
	@override String get compactPrivate => '私密';
	@override String get compactPublic => '公开';
}

// Path: illust.contextMenu
class Translations$illust$contextMenu$zh_CN extends Translations$illust$contextMenu$en_US {
	Translations$illust$contextMenu$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get download => '下载';
	@override String get downloadAll => '下载全部';
	@override String get copyImage => '复制图片';
}

// Path: illust.imageLabels
class Translations$illust$imageLabels$zh_CN extends Translations$illust$imageLabels$en_US {
	Translations$illust$imageLabels$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get original => '原图';
	@override String get large => '大图';
}

// Path: illust.toast
class Translations$illust$toast$zh_CN extends Translations$illust$toast$en_US {
	Translations$illust$toast$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get downloadStarted => '开始下载图片';
	@override String downloadAllQueued({required Object count}) => '已加入下载队列：${count} 张图片';
	@override String downloadComplete({required Object path}) => '下载完成：${path}';
	@override String get downloadFailed => '下载失败';
	@override String copying({required Object label}) => '正在复制${label}';
	@override String copied({required Object label}) => '已复制${label}';
	@override String copiedValue({required Object label, required Object value}) => '已复制${label}：${value}';
	@override String copyFailed({required Object label}) => '复制${label}失败';
}

// Path: illust.tooltip
class Translations$illust$tooltip$zh_CN extends Translations$illust$tooltip$en_US {
	Translations$illust$tooltip$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get previousImage => '上一张图片';
	@override String get nextImage => '下一张图片';
	@override String get backToDetail => '回到图片详情';
	@override String get removeBookmark => '移除收藏';
	@override String get addBookmark => '添加收藏';
}

// Path: illust.section
class Translations$illust$section$zh_CN extends Translations$illust$section$en_US {
	Translations$illust$section$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get tags => '标签';
	@override String get caption => '说明';
	@override String get details => '详情';
	@override String get creator => '作者';
	@override String get recentWorks => '近期作品';
	@override String get comments => '评论';
	@override String commentsWithCount({required Object count}) => '评论（${count}）';
	@override String get relatedWorks => '相似作品';
}

// Path: illust.metadata
class Translations$illust$metadata$zh_CN extends Translations$illust$metadata$en_US {
	Translations$illust$metadata$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get type => '类型';
	@override String get created => '创建时间';
}

// Path: illust.badge
class Translations$illust$badge$zh_CN extends Translations$illust$badge$en_US {
	Translations$illust$badge$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get aiArtwork => 'AI 作品';
	@override String get original => '原创';
}

// Path: illust.stats
class Translations$illust$stats$zh_CN extends Translations$illust$stats$en_US {
	Translations$illust$stats$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get size => '尺寸';
	@override String get views => '浏览';
	@override String get bookmarks => '收藏';
	@override String get pages => '页数';
}

// Path: illust.tags
class Translations$illust$tags$zh_CN extends Translations$illust$tags$en_US {
	Translations$illust$tags$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get none => '没有标签';
	@override String get tag => '标签';
}

// Path: illust.comments
class Translations$illust$comments$zh_CN extends Translations$illust$comments$en_US {
	Translations$illust$comments$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get failed => '评论加载失败';
	@override String get empty => '暂无评论';
	@override String get moreAvailable => '还有更多评论';
	@override String get hasReplies => '有回复';
	@override String get open => '打开评论';
	@override String get reply => '回复';
	@override String replyingTo({required Object name}) => '正在回复 ${name}';
	@override String get loadReplies => '加载回复';
	@override String get loadMoreReplies => '加载更多回复';
	@override String get repliesFailed => '回复加载失败';
	@override String get sendFailed => '评论发送失败';
	@override String get delete => '删除';
	@override String get deleteFailed => '评论删除失败';
	@override String get inputHint => '写下评论';
	@override String replyInputHint({required Object name}) => '回复 ${name}';
	@override String get emoji => '表情';
	@override String get stamp => '贴图';
}

// Path: illust.works
class Translations$illust$works$zh_CN extends Translations$illust$works$en_US {
	Translations$illust$works$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get failed => '作品加载失败';
	@override String get empty => '暂无可显示作品';
}

// Path: illust.related
class Translations$illust$related$zh_CN extends Translations$illust$related$en_US {
	Translations$illust$related$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get failed => '相似作品加载失败';
	@override String get empty => '暂无相似作品';
	@override String get viewMore => '查看更多相似作品';
}

// Path: novel.detail
class Translations$novel$detail$zh_CN extends Translations$novel$detail$en_US {
	Translations$novel$detail$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get images => '图片';
	@override String get series => '系列';
	@override String get content => '正文';
	@override String get startReading => '开始阅读';
	@override String totalChars({required Object count}) => '共 ${count} 字';
	@override String paragraphCount({required Object count}) => '${count} 段';
	@override String segmentCount({required Object count}) => '${count} 页';
}

// Path: novel.reader
class Translations$novel$reader$zh_CN extends Translations$novel$reader$en_US {
	Translations$novel$reader$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '阅读';
	@override String get body => '正文';
	@override String get chapters => '章节';
	@override String get settings => '阅读设置';
	@override String get emptyBody => '正文为空';
	@override String totalChars({required Object count}) => '共 ${count} 字';
	@override String pagePosition({required Object current, required Object total}) => '${current} / ${total} 页';
	@override String pageTotal({required Object total}) => '${total} 页';
	@override String currentPage({required Object page}) => '第 ${page} 页';
	@override String get readingProgress => '阅读进度';
	@override String get previousPage => '上一页';
	@override String get nextPage => '下一页';
	@override String get display => '显示';
	@override String get fontSize => '字号';
	@override String get lineHeight => '行距';
	@override String get noChapterMarkers => '没有章节标记';
	@override String get close => '关闭';
	@override String get decrease => '减小';
	@override String get increase => '增大';
	@override String get shortcutsTitle => '快捷键';
	@override String get shortcutsHelp => '左右键或 A/D 翻页，上下键或 W/S 滚动';
}

/// The flat map containing all translations for locale <zh-CN>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZhCn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'freepiv',
			'navigation.home' => '首页',
			'navigation.search' => '搜索',
			'navigation.newest' => '最新',
			'navigation.ranking' => '排行榜',
			'navigation.me' => '我的',
			'navigation.settings' => '设置',
			'common.back' => '返回',
			'common.cancel' => '取消',
			'common.retry' => '重试',
			'common.send' => '发送',
			'common.filter' => '筛选',
			'common.type' => '类型',
			'common.id' => 'ID',
			'common.error' => '错误',
			'common.notFound' => '未找到',
			'common.copy' => ({required Object label}) => '复制${label}',
			'common.labelValue' => ({required Object label, required Object value}) => '${label}：${value}',
			'common.errorWithCause' => ({required Object message, required Object cause}) => '${message}：${cause}',
			'refresh.pullToRefresh' => '下拉刷新',
			'refresh.releaseToRefresh' => '松开刷新',
			'refresh.refreshing' => '正在刷新',
			'refresh.refreshComplete' => '刷新完成',
			'refresh.refreshFailed' => '刷新失败',
			'refresh.pullToLoadMore' => '上拉加载更多',
			'refresh.releaseToLoad' => '松开加载',
			'refresh.loading' => '正在加载',
			'refresh.loadComplete' => '加载完成',
			'refresh.noMoreItems' => '没有更多内容',
			'refresh.loadFailed' => '加载失败',
			'refresh.lastUpdated' => '最后更新 %T',
			'toast.bookmarkFailed' => '收藏失败',
			'toast.followFailed' => '关注失败',
			'login.title' => '登录',
			'login.notSignedIn' => '未登录 Pixiv',
			'login.signedInAs' => ({required Object name}) => '已登录为 ${name}',
			'login.signInToPixiv' => '登录 Pixiv',
			'login.signInAgain' => '重新登录',
			'login.openingBrowser' => '正在打开浏览器…',
			'login.apiNotInitialized' => 'Pixiv API 尚未初始化。',
			'login.desktopOnly' => '系统浏览器登录目前仅支持 Linux、macOS 和 Windows。',
			'login.openedInBrowser' => '已在系统浏览器中打开 Pixiv 登录。完成登录后请返回应用。',
			'login.callbackMissingCode' => ({required Object uri}) => 'Pixiv 回调缺少 code：${uri}',
			'login.callbackReceived' => '已收到 Pixiv 回调，正在获取令牌。',
			'login.browserOpenUnsupported' => '当前环境尚未实现系统浏览器打开功能。',
			'login.browserOpenFailed' => ({required Object browser, required Object output}) => '${browser} 打开登录链接失败：${output}',
			'login.proxyHint' => '如果你使用了网路代理请在此设置代理地址再进行登录。',
			'settings.theme.title' => '主题',
			'settings.theme.system' => '跟随系统',
			'settings.theme.light' => '浅色',
			'settings.theme.dark' => '深色',
			'settings.language.title' => '语言',
			'settings.language.systemDefault' => '跟随系统',
			'settings.language.enUs' => 'English (United States)',
			'settings.language.zhCn' => '简体中文',
			'settings.language.zhTw' => '繁體中文',
			'settings.language.jaJp' => '日本語',
			'settings.images.title' => '图片',
			'settings.images.previewQuality' => '预览质量',
			'settings.images.viewerQuality' => '查看质量',
			'settings.images.medium' => '中等',
			'settings.images.large' => '大图',
			'settings.images.original' => '原图',
			'settings.downloads.title' => '下载',
			'settings.downloads.savePath' => '保存路径',
			'settings.downloads.chooseFolder' => '选择文件夹',
			'settings.downloads.dialogTitle' => '下载保存路径',
			'settings.downloads.defaultPath' => '默认',
			'settings.downloads.customPath' => '自定义',
			'settings.downloads.systemDownloadsFolder' => '系统下载文件夹',
			'settings.downloads.noFolderSelected' => '未选择文件夹',
			'settings.downloads.directorySet' => ({required Object path}) => '下载目录已设置：${path}',
			'settings.downloads.directoryUnavailable' => '下载目录不可用',
			'settings.downloads.maxConcurrentDownloads' => '最大同时下载数量',
			'settings.downloads.maxConcurrentDownloadsSubtitle' => ({required Object count}) => '当前最多同时下载 ${count} 个任务，后续任务会排队等待。',
			'settings.downloads.tasksTitle' => '下载任务',
			'settings.downloads.openTasks' => '下载任务',
			'settings.downloads.openTasksSubtitle' => '查看进度、失败项和已保存文件',
			'settings.downloads.noTasks' => '暂无下载任务',
			'settings.downloads.noTasksMessage' => '下载的图片会显示在这里。',
			'settings.downloads.total' => '总数',
			'settings.downloads.active' => '进行中',
			'settings.downloads.saved' => '已保存',
			'settings.downloads.failed' => '失败',
			'settings.downloads.downloading' => '正在下载',
			'settings.downloads.needsAttention' => '需要处理',
			'settings.downloads.completed' => '已完成',
			'settings.downloads.queued' => '排队中',
			'settings.downloads.running' => '正在下载',
			'settings.downloads.paused' => '已暂停',
			'settings.downloads.downloaded' => '已下载',
			'settings.downloads.cancelled' => '已取消',
			'settings.downloads.savePending' => '等待保存',
			'settings.downloads.saving' => '正在保存',
			'settings.downloads.saveFailed' => '保存失败',
			'settings.downloads.retrySave' => '重试保存',
			'settings.downloads.cancel' => '取消',
			'settings.downloads.deleteTask' => '删除任务',
			'settings.downloads.sync' => '同步',
			'settings.downloads.syncFailed' => '下载状态同步失败',
			'settings.downloads.actionFailed' => '下载操作失败',
			'settings.downloads.expand' => '展开',
			'settings.downloads.collapse' => '收起',
			'settings.proxy.title' => '网络代理',
			'settings.proxy.shortTitle' => '代理',
			'settings.proxy.subtitle' => '保存后 Pixiv API 和图片请求会使用所选代理。',
			'settings.proxy.open' => '设置代理',
			'settings.proxy.enabled' => '启用代理',
			'settings.proxy.enabledStatus' => '代理已开启',
			'settings.proxy.disabledStatus' => '直连',
			'settings.proxy.protocol' => '代理协议',
			'settings.proxy.protocolHttp' => 'HTTP',
			'settings.proxy.protocolSocks' => 'SOCKS',
			'settings.proxy.address' => 'IP 地址',
			'settings.proxy.addressHint' => '127.0.0.1',
			'settings.proxy.port' => '端口号',
			'settings.proxy.portHint' => '7890',
			'settings.proxy.helper' => 'IP 和端口分开填写，例如 127.0.0.1 和 7890。',
			'settings.proxy.save' => '保存',
			'settings.proxy.saved' => '代理设置已保存',
			'settings.proxy.required' => '启用代理前需要填写 IP 和端口。',
			'settings.proxy.invalid' => '请输入有效的 IP 和端口。',
			'settings.proxy.hostRequired' => '请输入 IP。',
			'settings.proxy.portRequired' => '请输入端口。',
			'settings.proxy.invalidHost' => '请输入有效的 IP 或主机名。',
			'settings.proxy.invalidPort' => '端口范围为 1-65535。',
			'settings.proxy.loadSystem' => '获取系统代理',
			'settings.proxy.systemLoaded' => '已获取系统代理',
			'settings.proxy.systemNotFound' => '未检测到系统代理',
			'settings.proxy.systemUnsupported' => '仅桌面端支持获取系统代理',
			'settings.proxy.systemLoadFailed' => '获取系统代理失败',
			'settings.proxy.entrySubtitleOn' => ({required Object url}) => '已开启：${url}',
			'settings.proxy.entrySubtitleOff' => '未开启',
			'settings.account.title' => '账号',
			'settings.account.signedOutSubtitle' => '登录后显示 Pixiv 账号',
			'settings.account.notSignedIn' => '未登录',
			'settings.account.signOut' => '退出登录',
			'me.openProfile' => '打开个人主页',
			'me.following' => '我的关注',
			'me.followers' => '我的粉丝',
			'me.emptyFollowing' => '暂无关注用户',
			'me.emptyFollowers' => '暂无粉丝',
			'me.settings' => '设置',
			'me.settingsSubtitle' => '主题、语言、图片和下载',
			'home.emptyTitle' => '暂无推荐',
			'home.emptyMessage' => '下拉即可重新获取推荐。',
			'home.rankings' => '排行榜',
			'home.seeMore' => '查看更多',
			'home.recommended' => '推荐',
			'home.illustrations' => '插画',
			'home.manga' => '漫画',
			'home.novels' => '小说',
			'home.users' => '用户',
			'ranking.emptyTitle' => '暂无排行榜作品',
			'ranking.emptyMessage' => '下拉即可重新获取排行榜。',
			'ranking.types.illustrations' => '插画',
			'ranking.types.manga' => '漫画',
			'ranking.types.novels' => '小说',
			'ranking.modes.day' => '每日',
			'ranking.modes.dayR18' => '每日 R-18',
			'ranking.modes.dayMale' => '男性每日',
			'ranking.modes.dayMaleR18' => '男性每日 R-18',
			'ranking.modes.dayFemale' => '女性每日',
			'ranking.modes.dayFemaleR18' => '女性每日 R-18',
			'ranking.modes.dayAi' => 'AI 生成',
			'ranking.modes.dayR18Ai' => 'AI 生成 R-18',
			'ranking.modes.week' => '每周',
			'ranking.modes.weekR18' => '每周 R-18',
			'ranking.modes.weekOriginal' => '原创每周',
			'ranking.modes.weekRookie' => '新人每周',
			'ranking.modes.month' => '每月',
			'search.placeholder' => '搜索标签、作品 ID 或用户 ID',
			'search.submit' => '搜索',
			'search.trendingTags' => '热门标签',
			'search.emptyTrendingTitle' => '暂无热门标签',
			'search.emptyTrendingMessage' => '下拉即可重新获取热门标签。',
			'search.noSuggestions' => '没有候选词',
			'search.filters.title' => '搜索筛选',
			'search.filters.sort' => '排序',
			'search.filters.target' => '目标',
			'search.filters.date' => '日期',
			'search.filters.bookmarks' => '收藏数',
			'search.type.illustManga' => '插画&漫画',
			'search.type.novel' => '小说',
			'search.type.user' => '用户',
			'search.sort.newest' => '最新',
			'search.sort.oldest' => '最旧',
			'search.sort.popular' => '热门',
			'search.target.tags' => '标签',
			'search.target.exactTags' => '精确标签',
			'search.target.titleAndCaption' => '标题与说明',
			'search.date.any' => '任意日期',
			'search.date.today' => '今天',
			'search.date.days7' => '7 天',
			'search.date.month1' => '1 个月',
			'search.date.months6' => '6 个月',
			'search.date.year1' => '1 年',
			'search.date.custom' => '自定义',
			'search.bookmarks.any' => '任意收藏数',
			'search.bookmarks.atLeast' => ({required Object count}) => '${count}+ 收藏',
			'search.direct.illust' => ({required Object id}) => '插画：${id}',
			'search.direct.user' => ({required Object id}) => '用户：${id}',
			'search.direct.novel' => ({required Object id}) => '小说：${id}',
			'search.empty.illustrations' => '没有找到插画',
			'search.empty.novels' => '没有找到小说',
			'search.empty.users' => '没有找到用户',
			'user.tabs.illustrations' => '插画',
			'user.tabs.manga' => '漫画',
			'user.tabs.novels' => '小说',
			'user.tabs.bookmarks' => '收藏',
			'user.tabs.following' => '关注',
			'user.tabs.profile' => '详细信息',
			'user.stats.illustrations' => '插画',
			'user.stats.manga' => '漫画',
			'user.stats.novels' => '小说',
			'user.stats.following' => '关注',
			'user.bookmarks.illustManga' => '插画&漫画',
			'user.bookmarks.novels' => '小说',
			'user.empty.illustrations' => '暂无插画',
			'user.empty.manga' => '暂无漫画',
			'user.empty.novels' => '暂无小说',
			'user.empty.bookmarkIllustrations' => '暂无公开插画或漫画收藏',
			'user.empty.bookmarkNovels' => '暂无公开小说收藏',
			'user.empty.following' => '暂无关注用户',
			'user.empty.profile' => '暂无公开详细信息',
			'user.profile.birthday' => '生日',
			'user.profile.region' => '地区',
			'user.profile.job' => '职业',
			'user.profile.webpage' => '主页',
			'user.profile.twitter' => 'Twitter',
			'user.profile.pawoo' => 'Pawoo',
			'user.profile.openLink' => '打开链接',
			'user.meta.novelChars' => ({required Object count}) => '${count} 字',
			'user.meta.novelPages' => ({required Object count}) => '${count} 页',
			'user.error.missingUser' => '缺少用户 ID 或用户详情。',
			'newest.audience.following' => '关注',
			'newest.audience.mypixiv' => '好P友',
			'newest.audience.everyone' => '所有人',
			'newest.workType.illustManga' => '插画&漫画',
			'newest.workType.illust' => '插画',
			'newest.workType.manga' => '漫画',
			'newest.workType.novel' => '小说',
			'newest.workType.compactArt' => '作品',
			'newest.workType.compactIllust' => '插画',
			'newest.workType.compactManga' => '漫画',
			'newest.workType.compactNovel' => '小说',
			'newest.followScope.title' => '关注范围',
			'newest.followScope.all' => '全部关注',
			'newest.followScope.private' => '私密关注',
			'newest.followScope.public' => '公开关注',
			'newest.followScope.compactAll' => '全部',
			'newest.followScope.compactPrivate' => '私密',
			'newest.followScope.compactPublic' => '公开',
			'newest.emptyTitle' => '暂无最新作品',
			'newest.compactFilter' => ({required Object workType, required Object scope}) => '${workType} · ${scope}',
			'newest.novelChars' => ({required Object count}) => '${count} 字',
			'newest.novelPages' => ({required Object count}) => '${count} 页',
			'illust.contextMenu.download' => '下载',
			'illust.contextMenu.downloadAll' => '下载全部',
			'illust.contextMenu.copyImage' => '复制图片',
			'illust.imageLabels.original' => '原图',
			'illust.imageLabels.large' => '大图',
			'illust.toast.downloadStarted' => '开始下载图片',
			'illust.toast.downloadAllQueued' => ({required Object count}) => '已加入下载队列：${count} 张图片',
			'illust.toast.downloadComplete' => ({required Object path}) => '下载完成：${path}',
			'illust.toast.downloadFailed' => '下载失败',
			'illust.toast.copying' => ({required Object label}) => '正在复制${label}',
			'illust.toast.copied' => ({required Object label}) => '已复制${label}',
			'illust.toast.copiedValue' => ({required Object label, required Object value}) => '已复制${label}：${value}',
			'illust.toast.copyFailed' => ({required Object label}) => '复制${label}失败',
			'illust.tooltip.previousImage' => '上一张图片',
			'illust.tooltip.nextImage' => '下一张图片',
			'illust.tooltip.backToDetail' => '回到图片详情',
			'illust.tooltip.removeBookmark' => '移除收藏',
			'illust.tooltip.addBookmark' => '添加收藏',
			'illust.section.tags' => '标签',
			'illust.section.caption' => '说明',
			'illust.section.details' => '详情',
			'illust.section.creator' => '作者',
			'illust.section.recentWorks' => '近期作品',
			'illust.section.comments' => '评论',
			'illust.section.commentsWithCount' => ({required Object count}) => '评论（${count}）',
			'illust.section.relatedWorks' => '相似作品',
			'illust.metadata.type' => '类型',
			'illust.metadata.created' => '创建时间',
			'illust.badge.aiArtwork' => 'AI 作品',
			'illust.badge.original' => '原创',
			'illust.stats.size' => '尺寸',
			'illust.stats.views' => '浏览',
			'illust.stats.bookmarks' => '收藏',
			'illust.stats.pages' => '页数',
			'illust.tags.none' => '没有标签',
			'illust.tags.tag' => '标签',
			'illust.comments.failed' => '评论加载失败',
			'illust.comments.empty' => '暂无评论',
			'illust.comments.moreAvailable' => '还有更多评论',
			'illust.comments.hasReplies' => '有回复',
			'illust.comments.open' => '打开评论',
			'illust.comments.reply' => '回复',
			'illust.comments.replyingTo' => ({required Object name}) => '正在回复 ${name}',
			'illust.comments.loadReplies' => '加载回复',
			'illust.comments.loadMoreReplies' => '加载更多回复',
			'illust.comments.repliesFailed' => '回复加载失败',
			'illust.comments.sendFailed' => '评论发送失败',
			'illust.comments.delete' => '删除',
			'illust.comments.deleteFailed' => '评论删除失败',
			'illust.comments.inputHint' => '写下评论',
			'illust.comments.replyInputHint' => ({required Object name}) => '回复 ${name}',
			'illust.comments.emoji' => '表情',
			'illust.comments.stamp' => '贴图',
			'illust.works.failed' => '作品加载失败',
			'illust.works.empty' => '暂无可显示作品',
			'illust.related.failed' => '相似作品加载失败',
			'illust.related.empty' => '暂无相似作品',
			'illust.related.viewMore' => '查看更多相似作品',
			'novel.detail.images' => '图片',
			'novel.detail.series' => '系列',
			'novel.detail.content' => '正文',
			'novel.detail.startReading' => '开始阅读',
			'novel.detail.totalChars' => ({required Object count}) => '共 ${count} 字',
			'novel.detail.paragraphCount' => ({required Object count}) => '${count} 段',
			'novel.detail.segmentCount' => ({required Object count}) => '${count} 页',
			'novel.reader.title' => '阅读',
			'novel.reader.body' => '正文',
			'novel.reader.chapters' => '章节',
			'novel.reader.settings' => '阅读设置',
			'novel.reader.emptyBody' => '正文为空',
			'novel.reader.totalChars' => ({required Object count}) => '共 ${count} 字',
			'novel.reader.pagePosition' => ({required Object current, required Object total}) => '${current} / ${total} 页',
			'novel.reader.pageTotal' => ({required Object total}) => '${total} 页',
			'novel.reader.currentPage' => ({required Object page}) => '第 ${page} 页',
			'novel.reader.readingProgress' => '阅读进度',
			'novel.reader.previousPage' => '上一页',
			'novel.reader.nextPage' => '下一页',
			'novel.reader.display' => '显示',
			'novel.reader.fontSize' => '字号',
			'novel.reader.lineHeight' => '行距',
			'novel.reader.noChapterMarkers' => '没有章节标记',
			'novel.reader.close' => '关闭',
			'novel.reader.decrease' => '减小',
			'novel.reader.increase' => '增大',
			'novel.reader.shortcutsTitle' => '快捷键',
			'novel.reader.shortcutsHelp' => '左右键或 A/D 翻页，上下键或 W/S 滚动',
			'follow.tooltipFollow' => '关注用户',
			'follow.tooltipUnfollow' => '取消关注',
			'follow.followed' => '已关注',
			'follow.notFollowed' => '未关注',
			'richText.twitterUser' => ({required Object username}) => 'Twitter：${username}',
			'richText.illustId' => ({required Object id}) => '插画 ID：${id}',
			'richText.userId' => ({required Object id}) => '用户 ID：${id}',
			_ => null,
		};
	}
}
