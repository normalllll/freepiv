///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEnUs = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.enUs,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en-US>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$en_US app = Translations$app$en_US.internal(_root);
	late final Translations$navigation$en_US navigation = Translations$navigation$en_US.internal(_root);
	late final Translations$common$en_US common = Translations$common$en_US.internal(_root);
	late final Translations$refresh$en_US refresh = Translations$refresh$en_US.internal(_root);
	late final Translations$toast$en_US toast = Translations$toast$en_US.internal(_root);
	late final Translations$login$en_US login = Translations$login$en_US.internal(_root);
	late final Translations$settings$en_US settings = Translations$settings$en_US.internal(_root);
	late final Translations$me$en_US me = Translations$me$en_US.internal(_root);
	late final Translations$about$en_US about = Translations$about$en_US.internal(_root);
	late final Translations$home$en_US home = Translations$home$en_US.internal(_root);
	late final Translations$ranking$en_US ranking = Translations$ranking$en_US.internal(_root);
	late final Translations$search$en_US search = Translations$search$en_US.internal(_root);
	late final Translations$user$en_US user = Translations$user$en_US.internal(_root);
	late final Translations$newest$en_US newest = Translations$newest$en_US.internal(_root);
	late final Translations$illust$en_US illust = Translations$illust$en_US.internal(_root);
	late final Translations$novel$en_US novel = Translations$novel$en_US.internal(_root);
	late final Translations$follow$en_US follow = Translations$follow$en_US.internal(_root);
	late final Translations$richText$en_US richText = Translations$richText$en_US.internal(_root);
}

// Path: app
class Translations$app$en_US {
	Translations$app$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'freepiv';
}

// Path: navigation
class Translations$navigation$en_US {
	Translations$navigation$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get home => 'Home';
	String get search => 'Search';
	String get newest => 'Newest';
	String get ranking => 'Ranking';
	String get me => 'Me';
	String get settings => 'Settings';
}

// Path: common
class Translations$common$en_US {
	Translations$common$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get back => 'Back';
	String get cancel => 'Cancel';
	String get retry => 'Retry';
	String get send => 'Send';
	String get filter => 'Filter';
	String get type => 'Type';
	String get id => 'ID';
	String get error => 'Error';
	String get notFound => 'Not found';
	String copy({required Object label}) => 'Copy ${label}';
	String labelValue({required Object label, required Object value}) => '${label}: ${value}';
	String errorWithCause({required Object message, required Object cause}) => '${message}: ${cause}';
}

// Path: refresh
class Translations$refresh$en_US {
	Translations$refresh$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get pullToRefresh => 'Pull to refresh';
	String get releaseToRefresh => 'Release to refresh';
	String get refreshing => 'Refreshing';
	String get refreshComplete => 'Refresh complete';
	String get refreshFailed => 'Refresh failed';
	String get pullToLoadMore => 'Pull to load more';
	String get releaseToLoad => 'Release to load';
	String get loading => 'Loading';
	String get loadComplete => 'Load complete';
	String get noMoreItems => 'No more items';
	String get loadFailed => 'Load failed';
	String get lastUpdated => 'Last updated %T';
}

// Path: toast
class Translations$toast$en_US {
	Translations$toast$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get bookmarkFailed => 'Bookmark failed';
	String get followFailed => 'Follow failed';
}

// Path: login
class Translations$login$en_US {
	Translations$login$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Sign in';
	String get notSignedIn => 'Not signed in to Pixiv';
	String signedInAs({required Object name}) => 'Signed in as ${name}';
	String get signInToPixiv => 'Sign in to Pixiv';
	String get signInAgain => 'Sign in again';
	String get openingBrowser => 'Opening browser...';
	String get apiNotInitialized => 'Pixiv API is not initialized.';
	String get desktopOnly => 'System browser sign-in currently supports only Linux, macOS, and Windows.';
	String get openedInBrowser => 'Pixiv sign-in opened in the system browser. Return to the app after signing in.';
	String callbackMissingCode({required Object uri}) => 'Pixiv callback is missing code: ${uri}';
	String get callbackReceived => 'Pixiv callback received. Fetching token.';
	String get browserOpenUnsupported => 'System browser opening is not implemented here.';
	String browserOpenFailed({required Object browser, required Object output}) => '${browser} failed to open the sign-in link: ${output}';
	String get proxyHint => 'If you use a network proxy, set the proxy address here before signing in.';
}

// Path: settings
class Translations$settings$en_US {
	Translations$settings$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$settings$theme$en_US theme = Translations$settings$theme$en_US.internal(_root);
	late final Translations$settings$language$en_US language = Translations$settings$language$en_US.internal(_root);
	late final Translations$settings$images$en_US images = Translations$settings$images$en_US.internal(_root);
	late final Translations$settings$downloads$en_US downloads = Translations$settings$downloads$en_US.internal(_root);
	late final Translations$settings$proxy$en_US proxy = Translations$settings$proxy$en_US.internal(_root);
	late final Translations$settings$account$en_US account = Translations$settings$account$en_US.internal(_root);
}

// Path: me
class Translations$me$en_US {
	Translations$me$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get openProfile => 'Open profile';
	String get following => 'My following';
	String get followers => 'My followers';
	String get emptyFollowing => 'No following users';
	String get emptyFollowers => 'No followers';
	String get about => 'About';
	String get aboutSubtitle => 'Version, updates, and project links';
	String get settings => 'Settings';
	String get settingsSubtitle => 'Theme, language, images, and downloads';
}

// Path: about
class Translations$about$en_US {
	Translations$about$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'About';
	String get appName => 'freepiv';
	String get subtitle => 'A lightweight client for browsing Pixiv content. Check the current version, look for updates, and open the project download page here.';
	String get project => 'Project';
	String get projectPage => 'Project page';
	String get releasePage => 'Release page';
	String get versionInfo => 'Version info';
	String get appVersion => 'App version';
	String get latestVersion => 'Latest version';
	String currentVersion({required Object version, required Object buildNumber}) => 'Current version ${version}+${buildNumber}';
	String get noCachedUpdate => 'No cached update';
	String get loading => 'Loading';
	String get community => 'Community';
	String get telegram => 'Telegram';
	String get discord => 'Discord';
	String get checkUpdate => 'Check update';
	String get checkingUpdateShort => 'Checking';
	String get checkingUpdate => 'Checking for updates...';
	String get noUpdate => 'You are on the latest version';
	String updateAvailable({required Object version, required Object buildNumber}) => 'New version available: ${version}+${buildNumber}';
	String get checkUpdateFailed => 'Failed to check for updates';
	String get downloadPage => 'Download page';
	String get downloadAssetUnavailable => 'No download asset matched this platform. Opening the release page.';
	String get openDownloadFailed => 'Failed to open the download page';
	String get openLinkFailed => 'Failed to open link';
}

// Path: home
class Translations$home$en_US {
	Translations$home$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get emptyTitle => 'No recommendations yet';
	String get emptyMessage => 'Pull down to fetch recommendations again.';
	String get rankings => 'Rankings';
	String get seeMore => 'See more';
	String get recommended => 'Recommended';
	String get illustrations => 'Illust';
	String get manga => 'Manga';
	String get novels => 'Novels';
	String get users => 'Users';
}

// Path: ranking
class Translations$ranking$en_US {
	Translations$ranking$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get emptyTitle => 'No ranking works';
	String get emptyMessage => 'Pull down to fetch the ranking again.';
	late final Translations$ranking$types$en_US types = Translations$ranking$types$en_US.internal(_root);
	late final Translations$ranking$modes$en_US modes = Translations$ranking$modes$en_US.internal(_root);
}

// Path: search
class Translations$search$en_US {
	Translations$search$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get placeholder => 'Search tags, illust ID, or user ID';
	String get submit => 'Search';
	String get trendingTags => 'Trending Tags';
	String get emptyTrendingTitle => 'No trending tags';
	String get emptyTrendingMessage => 'Pull down to load trending tags again.';
	String get noSuggestions => 'No suggestions';
	late final Translations$search$filters$en_US filters = Translations$search$filters$en_US.internal(_root);
	late final Translations$search$type$en_US type = Translations$search$type$en_US.internal(_root);
	late final Translations$search$sort$en_US sort = Translations$search$sort$en_US.internal(_root);
	late final Translations$search$target$en_US target = Translations$search$target$en_US.internal(_root);
	late final Translations$search$date$en_US date = Translations$search$date$en_US.internal(_root);
	late final Translations$search$bookmarks$en_US bookmarks = Translations$search$bookmarks$en_US.internal(_root);
	late final Translations$search$direct$en_US direct = Translations$search$direct$en_US.internal(_root);
	late final Translations$search$empty$en_US empty = Translations$search$empty$en_US.internal(_root);
}

// Path: user
class Translations$user$en_US {
	Translations$user$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$user$tabs$en_US tabs = Translations$user$tabs$en_US.internal(_root);
	late final Translations$user$stats$en_US stats = Translations$user$stats$en_US.internal(_root);
	late final Translations$user$bookmarks$en_US bookmarks = Translations$user$bookmarks$en_US.internal(_root);
	late final Translations$user$empty$en_US empty = Translations$user$empty$en_US.internal(_root);
	late final Translations$user$profile$en_US profile = Translations$user$profile$en_US.internal(_root);
	late final Translations$user$meta$en_US meta = Translations$user$meta$en_US.internal(_root);
	late final Translations$user$error$en_US error = Translations$user$error$en_US.internal(_root);
}

// Path: newest
class Translations$newest$en_US {
	Translations$newest$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$newest$audience$en_US audience = Translations$newest$audience$en_US.internal(_root);
	late final Translations$newest$workType$en_US workType = Translations$newest$workType$en_US.internal(_root);
	late final Translations$newest$followScope$en_US followScope = Translations$newest$followScope$en_US.internal(_root);
	String get emptyTitle => 'No newest works';
	String compactFilter({required Object workType, required Object scope}) => '${workType} · ${scope}';
	String novelChars({required Object count}) => '${count} chars';
	String novelPages({required Object count}) => '${count} pages';
}

// Path: illust
class Translations$illust$en_US {
	Translations$illust$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$illust$contextMenu$en_US contextMenu = Translations$illust$contextMenu$en_US.internal(_root);
	late final Translations$illust$imageLabels$en_US imageLabels = Translations$illust$imageLabels$en_US.internal(_root);
	late final Translations$illust$toast$en_US toast = Translations$illust$toast$en_US.internal(_root);
	late final Translations$illust$tooltip$en_US tooltip = Translations$illust$tooltip$en_US.internal(_root);
	late final Translations$illust$section$en_US section = Translations$illust$section$en_US.internal(_root);
	late final Translations$illust$metadata$en_US metadata = Translations$illust$metadata$en_US.internal(_root);
	late final Translations$illust$badge$en_US badge = Translations$illust$badge$en_US.internal(_root);
	late final Translations$illust$stats$en_US stats = Translations$illust$stats$en_US.internal(_root);
	late final Translations$illust$tags$en_US tags = Translations$illust$tags$en_US.internal(_root);
	late final Translations$illust$comments$en_US comments = Translations$illust$comments$en_US.internal(_root);
	late final Translations$illust$works$en_US works = Translations$illust$works$en_US.internal(_root);
	late final Translations$illust$related$en_US related = Translations$illust$related$en_US.internal(_root);
}

// Path: novel
class Translations$novel$en_US {
	Translations$novel$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$novel$detail$en_US detail = Translations$novel$detail$en_US.internal(_root);
	late final Translations$novel$reader$en_US reader = Translations$novel$reader$en_US.internal(_root);
}

// Path: follow
class Translations$follow$en_US {
	Translations$follow$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get tooltipFollow => 'Follow user';
	String get tooltipUnfollow => 'Unfollow';
	String get followed => 'Following';
	String get notFollowed => 'Not following';
}

// Path: richText
class Translations$richText$en_US {
	Translations$richText$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String twitterUser({required Object username}) => 'Twitter: ${username}';
	String illustId({required Object id}) => 'Illust ID: ${id}';
	String userId({required Object id}) => 'User ID: ${id}';
}

// Path: settings.theme
class Translations$settings$theme$en_US {
	Translations$settings$theme$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Theme';
	String get system => 'System';
	String get light => 'Light';
	String get dark => 'Dark';
}

// Path: settings.language
class Translations$settings$language$en_US {
	Translations$settings$language$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Language';
	String get systemDefault => 'System default';
	String get enUs => 'English (United States)';
	String get zhCn => 'Simplified Chinese';
	String get zhTw => 'Traditional Chinese';
	String get jaJp => 'Japanese';
}

// Path: settings.images
class Translations$settings$images$en_US {
	Translations$settings$images$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Images';
	String get previewQuality => 'Preview quality';
	String get viewerQuality => 'Viewer quality';
	String get medium => 'Medium';
	String get large => 'Large';
	String get original => 'Original';
}

// Path: settings.downloads
class Translations$settings$downloads$en_US {
	Translations$settings$downloads$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Downloads';
	String get savePath => 'Save path';
	String get chooseFolder => 'Choose folder';
	String get dialogTitle => 'Download save path';
	String get defaultPath => 'Default';
	String get customPath => 'Custom';
	String get systemDownloadsFolder => 'System Downloads folder';
	String get noFolderSelected => 'No folder selected';
	String directorySet({required Object path}) => 'Download folder set: ${path}';
	String get directoryUnavailable => 'Download folder is unavailable';
	String get maxConcurrentDownloads => 'Maximum simultaneous downloads';
	String maxConcurrentDownloadsSubtitle({required Object count}) => 'Up to ${count} tasks download at once. Later tasks wait in the queue.';
	String get tasksTitle => 'Download tasks';
	String get openTasks => 'Download tasks';
	String get openTasksSubtitle => 'View progress, failures, and saved files';
	String get noTasks => 'No download tasks';
	String get noTasksMessage => 'Downloaded images will appear here.';
	String get total => 'Total';
	String get active => 'Active';
	String get saved => 'Saved';
	String get failed => 'Failed';
	String get downloading => 'Downloading';
	String get needsAttention => 'Needs attention';
	String get completed => 'Completed';
	String get queued => 'Queued';
	String get running => 'Downloading';
	String get paused => 'Paused';
	String get downloaded => 'Downloaded';
	String get cancelled => 'Cancelled';
	String get savePending => 'Waiting to save';
	String get saving => 'Saving';
	String get saveFailed => 'Save failed';
	String get retrySave => 'Retry save';
	String get cancel => 'Cancel';
	String get deleteTask => 'Delete task';
	String get sync => 'Sync';
	String get syncFailed => 'Download sync failed';
	String get actionFailed => 'Download action failed';
	String get expand => 'Expand';
	String get collapse => 'Collapse';
}

// Path: settings.proxy
class Translations$settings$proxy$en_US {
	Translations$settings$proxy$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Network proxy';
	String get shortTitle => 'Proxy';
	String get subtitle => 'Pixiv API and image requests will use the selected proxy after saving.';
	String get open => 'Set proxy';
	String get enabled => 'Use proxy';
	String get enabledStatus => 'Proxy is on';
	String get disabledStatus => 'Direct connection';
	String get protocol => 'Proxy protocol';
	String get protocolHttp => 'HTTP';
	String get protocolSocks => 'SOCKS';
	String get address => 'IP address';
	String get addressHint => '127.0.0.1';
	String get port => 'Port';
	String get portHint => '7890';
	String get helper => 'Enter IP and port separately, for example 127.0.0.1 and 7890.';
	String get save => 'Save';
	String get saved => 'Proxy settings saved';
	String get required => 'Enter an IP and port before turning this on.';
	String get invalid => 'Enter a valid IP and port.';
	String get hostRequired => 'Enter an IP.';
	String get portRequired => 'Enter a port.';
	String get invalidHost => 'Enter a valid IP or host name.';
	String get invalidPort => 'Port must be 1-65535.';
	String get loadSystem => 'Get system proxy';
	String get systemLoaded => 'System proxy loaded';
	String get systemNotFound => 'No system proxy detected';
	String get systemUnsupported => 'System proxy detection is available on desktop only';
	String get systemLoadFailed => 'Failed to get system proxy';
	String entrySubtitleOn({required Object url}) => 'On: ${url}';
	String get entrySubtitleOff => 'Off';
}

// Path: settings.account
class Translations$settings$account$en_US {
	Translations$settings$account$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Account';
	String get signedOutSubtitle => 'Sign in to show your Pixiv account';
	String get notSignedIn => 'Not signed in';
	String get signOut => 'Sign out';
}

// Path: ranking.types
class Translations$ranking$types$en_US {
	Translations$ranking$types$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get illustrations => 'Illust';
	String get manga => 'Manga';
	String get novels => 'Novels';
}

// Path: ranking.modes
class Translations$ranking$modes$en_US {
	Translations$ranking$modes$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get day => 'Daily';
	String get dayR18 => 'Daily R-18';
	String get dayMale => 'Daily Male';
	String get dayMaleR18 => 'Daily Male R-18';
	String get dayFemale => 'Daily Female';
	String get dayFemaleR18 => 'Daily Female R-18';
	String get dayAi => 'AI-generated';
	String get dayR18Ai => 'AI-generated R-18';
	String get week => 'Weekly';
	String get weekR18 => 'Weekly R-18';
	String get weekOriginal => 'Weekly Original';
	String get weekRookie => 'Weekly Rookie';
	String get month => 'Monthly';
}

// Path: search.filters
class Translations$search$filters$en_US {
	Translations$search$filters$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Search filters';
	String get sort => 'Sort';
	String get target => 'Target';
	String get date => 'Date';
	String get bookmarks => 'Bookmarks';
}

// Path: search.type
class Translations$search$type$en_US {
	Translations$search$type$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get illustManga => 'Illust & Manga';
	String get novel => 'Novel';
	String get user => 'User';
}

// Path: search.sort
class Translations$search$sort$en_US {
	Translations$search$sort$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get newest => 'Newest';
	String get oldest => 'Oldest';
	String get popular => 'Popular';
}

// Path: search.target
class Translations$search$target$en_US {
	Translations$search$target$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get tags => 'Tags';
	String get exactTags => 'Exact tags';
	String get titleAndCaption => 'Title & caption';
}

// Path: search.date
class Translations$search$date$en_US {
	Translations$search$date$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get any => 'Any date';
	String get today => 'Today';
	String get days7 => '7 days';
	String get month1 => '1 month';
	String get months6 => '6 months';
	String get year1 => '1 year';
	String get custom => 'Custom';
}

// Path: search.bookmarks
class Translations$search$bookmarks$en_US {
	Translations$search$bookmarks$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get any => 'Any bookmarks';
	String atLeast({required Object count}) => '${count}+ bookmarks';
}

// Path: search.direct
class Translations$search$direct$en_US {
	Translations$search$direct$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String illust({required Object id}) => 'Illust: ${id}';
	String user({required Object id}) => 'User: ${id}';
	String novel({required Object id}) => 'Novel: ${id}';
}

// Path: search.empty
class Translations$search$empty$en_US {
	Translations$search$empty$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get illustrations => 'No illustrations found';
	String get novels => 'No novels found';
	String get users => 'No users found';
}

// Path: user.tabs
class Translations$user$tabs$en_US {
	Translations$user$tabs$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get illustrations => 'Illustrations';
	String get manga => 'Manga';
	String get novels => 'Novels';
	String get bookmarks => 'Bookmarks';
	String get following => 'Following';
	String get profile => 'Details';
}

// Path: user.stats
class Translations$user$stats$en_US {
	Translations$user$stats$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get illustrations => 'Illusts';
	String get manga => 'Manga';
	String get novels => 'Novels';
	String get following => 'Following';
}

// Path: user.bookmarks
class Translations$user$bookmarks$en_US {
	Translations$user$bookmarks$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get illustManga => 'Illust & Manga';
	String get novels => 'Novels';
}

// Path: user.empty
class Translations$user$empty$en_US {
	Translations$user$empty$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get illustrations => 'No Illusts';
	String get manga => 'No manga';
	String get novels => 'No novels';
	String get bookmarkIllustrations => 'No public illustration or manga bookmarks';
	String get bookmarkNovels => 'No public novel bookmarks';
	String get following => 'No following users';
	String get profile => 'No public profile details';
}

// Path: user.profile
class Translations$user$profile$en_US {
	Translations$user$profile$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get birthday => 'Birthday';
	String get region => 'Region';
	String get job => 'Job';
	String get webpage => 'Website';
	String get twitter => 'Twitter';
	String get pawoo => 'Pawoo';
	String get openLink => 'Open link';
}

// Path: user.meta
class Translations$user$meta$en_US {
	Translations$user$meta$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String novelChars({required Object count}) => '${count} chars';
	String novelPages({required Object count}) => '${count} pages';
}

// Path: user.error
class Translations$user$error$en_US {
	Translations$user$error$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get missingUser => 'User id or user detail is missing.';
}

// Path: newest.audience
class Translations$newest$audience$en_US {
	Translations$newest$audience$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get following => 'Following';
	String get mypixiv => 'MyPixiv';
	String get everyone => 'Everyone';
}

// Path: newest.workType
class Translations$newest$workType$en_US {
	Translations$newest$workType$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get illustManga => 'Illust & Manga';
	String get illust => 'Illust';
	String get manga => 'Manga';
	String get novel => 'Novels';
	String get compactArt => 'Art';
	String get compactIllust => 'Illust';
	String get compactManga => 'Manga';
	String get compactNovel => 'Novel';
}

// Path: newest.followScope
class Translations$newest$followScope$en_US {
	Translations$newest$followScope$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Follow Scope';
	String get all => 'All follows';
	String get private => 'Private follows';
	String get public => 'Public follows';
	String get compactAll => 'All';
	String get compactPrivate => 'Private';
	String get compactPublic => 'Public';
}

// Path: illust.contextMenu
class Translations$illust$contextMenu$en_US {
	Translations$illust$contextMenu$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get download => 'Download';
	String get downloadAll => 'Download all';
	String get copyImage => 'Copy image';
}

// Path: illust.imageLabels
class Translations$illust$imageLabels$en_US {
	Translations$illust$imageLabels$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get original => 'original image';
	String get large => 'large image';
}

// Path: illust.toast
class Translations$illust$toast$en_US {
	Translations$illust$toast$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get downloadStarted => 'Downloading image';
	String downloadAllQueued({required Object count}) => '${count} images added to the download queue';
	String downloadComplete({required Object path}) => 'Download complete: ${path}';
	String get downloadFailed => 'Download failed';
	String copying({required Object label}) => 'Copying ${label}';
	String copied({required Object label}) => 'Copied ${label}';
	String copiedValue({required Object label, required Object value}) => 'Copied ${label}: ${value}';
	String copyFailed({required Object label}) => 'Failed to copy ${label}';
}

// Path: illust.tooltip
class Translations$illust$tooltip$en_US {
	Translations$illust$tooltip$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get previousImage => 'Previous image';
	String get nextImage => 'Next image';
	String get backToDetail => 'Back to image detail';
	String get removeBookmark => 'Remove bookmark';
	String get addBookmark => 'Add bookmark';
}

// Path: illust.section
class Translations$illust$section$en_US {
	Translations$illust$section$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get tags => 'Tags';
	String get caption => 'Caption';
	String get details => 'Details';
	String get creator => 'Creator';
	String get recentWorks => 'Recent works';
	String get comments => 'Comments';
	String commentsWithCount({required Object count}) => 'Comments (${count})';
	String get relatedWorks => 'Related works';
}

// Path: illust.metadata
class Translations$illust$metadata$en_US {
	Translations$illust$metadata$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get type => 'Type';
	String get created => 'Created';
}

// Path: illust.badge
class Translations$illust$badge$en_US {
	Translations$illust$badge$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get aiArtwork => 'AI Artwork';
	String get original => 'Original';
}

// Path: illust.stats
class Translations$illust$stats$en_US {
	Translations$illust$stats$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get size => 'Size';
	String get views => 'Views';
	String get bookmarks => 'Bookmarks';
	String get pages => 'Pages';
}

// Path: illust.tags
class Translations$illust$tags$en_US {
	Translations$illust$tags$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get none => 'No tags';
	String get tag => 'tag';
}

// Path: illust.comments
class Translations$illust$comments$en_US {
	Translations$illust$comments$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get failed => 'Failed to load comments';
	String get empty => 'No comments yet';
	String get moreAvailable => 'More comments available';
	String get hasReplies => 'Has replies';
	String get open => 'Open comments';
	String get reply => 'Reply';
	String replyingTo({required Object name}) => 'Replying to ${name}';
	String get loadReplies => 'Load replies';
	String get loadMoreReplies => 'Load more replies';
	String get repliesFailed => 'Failed to load replies';
	String get sendFailed => 'Failed to send comment';
	String get delete => 'Delete';
	String get deleteFailed => 'Failed to delete comment';
	String get inputHint => 'Write a comment';
	String replyInputHint({required Object name}) => 'Reply to ${name}';
	String get emoji => 'Emoji';
	String get stamp => 'Stamp';
}

// Path: illust.works
class Translations$illust$works$en_US {
	Translations$illust$works$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get failed => 'Failed to load works';
	String get empty => 'No works to show';
}

// Path: illust.related
class Translations$illust$related$en_US {
	Translations$illust$related$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get failed => 'Failed to load related works';
	String get empty => 'No related works';
	String get viewMore => 'View more related works';
}

// Path: novel.detail
class Translations$novel$detail$en_US {
	Translations$novel$detail$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get images => 'Images';
	String get series => 'Series';
	String get content => 'Content';
	String get startReading => 'Start reading';
	String totalChars({required Object count}) => '${count} chars';
	String paragraphCount({required Object count}) => '${count} paragraphs';
	String segmentCount({required Object count}) => '${count} pages';
}

// Path: novel.reader
class Translations$novel$reader$en_US {
	Translations$novel$reader$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Reading';
	String get body => 'Body';
	String get chapters => 'Chapters';
	String get settings => 'Reading settings';
	String get emptyBody => 'No body text';
	String totalChars({required Object count}) => '${count} chars';
	String pagePosition({required Object current, required Object total}) => '${current} / ${total} pages';
	String pageTotal({required Object total}) => '${total} pages';
	String currentPage({required Object page}) => 'Page ${page}';
	String get readingProgress => 'Reading progress';
	String get previousPage => 'Previous page';
	String get nextPage => 'Next page';
	String get display => 'Display';
	String get fontSize => 'Font size';
	String get lineHeight => 'Line height';
	String get noChapterMarkers => 'No chapter markers';
	String get close => 'Close';
	String get decrease => 'Decrease';
	String get increase => 'Increase';
	String get shortcutsTitle => 'Shortcuts';
	String get shortcutsHelp => 'Left/Right or A/D turn pages; Up/Down or W/S scroll';
}

/// The flat map containing all translations for locale <en-US>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'freepiv',
			'navigation.home' => 'Home',
			'navigation.search' => 'Search',
			'navigation.newest' => 'Newest',
			'navigation.ranking' => 'Ranking',
			'navigation.me' => 'Me',
			'navigation.settings' => 'Settings',
			'common.back' => 'Back',
			'common.cancel' => 'Cancel',
			'common.retry' => 'Retry',
			'common.send' => 'Send',
			'common.filter' => 'Filter',
			'common.type' => 'Type',
			'common.id' => 'ID',
			'common.error' => 'Error',
			'common.notFound' => 'Not found',
			'common.copy' => ({required Object label}) => 'Copy ${label}',
			'common.labelValue' => ({required Object label, required Object value}) => '${label}: ${value}',
			'common.errorWithCause' => ({required Object message, required Object cause}) => '${message}: ${cause}',
			'refresh.pullToRefresh' => 'Pull to refresh',
			'refresh.releaseToRefresh' => 'Release to refresh',
			'refresh.refreshing' => 'Refreshing',
			'refresh.refreshComplete' => 'Refresh complete',
			'refresh.refreshFailed' => 'Refresh failed',
			'refresh.pullToLoadMore' => 'Pull to load more',
			'refresh.releaseToLoad' => 'Release to load',
			'refresh.loading' => 'Loading',
			'refresh.loadComplete' => 'Load complete',
			'refresh.noMoreItems' => 'No more items',
			'refresh.loadFailed' => 'Load failed',
			'refresh.lastUpdated' => 'Last updated %T',
			'toast.bookmarkFailed' => 'Bookmark failed',
			'toast.followFailed' => 'Follow failed',
			'login.title' => 'Sign in',
			'login.notSignedIn' => 'Not signed in to Pixiv',
			'login.signedInAs' => ({required Object name}) => 'Signed in as ${name}',
			'login.signInToPixiv' => 'Sign in to Pixiv',
			'login.signInAgain' => 'Sign in again',
			'login.openingBrowser' => 'Opening browser...',
			'login.apiNotInitialized' => 'Pixiv API is not initialized.',
			'login.desktopOnly' => 'System browser sign-in currently supports only Linux, macOS, and Windows.',
			'login.openedInBrowser' => 'Pixiv sign-in opened in the system browser. Return to the app after signing in.',
			'login.callbackMissingCode' => ({required Object uri}) => 'Pixiv callback is missing code: ${uri}',
			'login.callbackReceived' => 'Pixiv callback received. Fetching token.',
			'login.browserOpenUnsupported' => 'System browser opening is not implemented here.',
			'login.browserOpenFailed' => ({required Object browser, required Object output}) => '${browser} failed to open the sign-in link: ${output}',
			'login.proxyHint' => 'If you use a network proxy, set the proxy address here before signing in.',
			'settings.theme.title' => 'Theme',
			'settings.theme.system' => 'System',
			'settings.theme.light' => 'Light',
			'settings.theme.dark' => 'Dark',
			'settings.language.title' => 'Language',
			'settings.language.systemDefault' => 'System default',
			'settings.language.enUs' => 'English (United States)',
			'settings.language.zhCn' => 'Simplified Chinese',
			'settings.language.zhTw' => 'Traditional Chinese',
			'settings.language.jaJp' => 'Japanese',
			'settings.images.title' => 'Images',
			'settings.images.previewQuality' => 'Preview quality',
			'settings.images.viewerQuality' => 'Viewer quality',
			'settings.images.medium' => 'Medium',
			'settings.images.large' => 'Large',
			'settings.images.original' => 'Original',
			'settings.downloads.title' => 'Downloads',
			'settings.downloads.savePath' => 'Save path',
			'settings.downloads.chooseFolder' => 'Choose folder',
			'settings.downloads.dialogTitle' => 'Download save path',
			'settings.downloads.defaultPath' => 'Default',
			'settings.downloads.customPath' => 'Custom',
			'settings.downloads.systemDownloadsFolder' => 'System Downloads folder',
			'settings.downloads.noFolderSelected' => 'No folder selected',
			'settings.downloads.directorySet' => ({required Object path}) => 'Download folder set: ${path}',
			'settings.downloads.directoryUnavailable' => 'Download folder is unavailable',
			'settings.downloads.maxConcurrentDownloads' => 'Maximum simultaneous downloads',
			'settings.downloads.maxConcurrentDownloadsSubtitle' => ({required Object count}) => 'Up to ${count} tasks download at once. Later tasks wait in the queue.',
			'settings.downloads.tasksTitle' => 'Download tasks',
			'settings.downloads.openTasks' => 'Download tasks',
			'settings.downloads.openTasksSubtitle' => 'View progress, failures, and saved files',
			'settings.downloads.noTasks' => 'No download tasks',
			'settings.downloads.noTasksMessage' => 'Downloaded images will appear here.',
			'settings.downloads.total' => 'Total',
			'settings.downloads.active' => 'Active',
			'settings.downloads.saved' => 'Saved',
			'settings.downloads.failed' => 'Failed',
			'settings.downloads.downloading' => 'Downloading',
			'settings.downloads.needsAttention' => 'Needs attention',
			'settings.downloads.completed' => 'Completed',
			'settings.downloads.queued' => 'Queued',
			'settings.downloads.running' => 'Downloading',
			'settings.downloads.paused' => 'Paused',
			'settings.downloads.downloaded' => 'Downloaded',
			'settings.downloads.cancelled' => 'Cancelled',
			'settings.downloads.savePending' => 'Waiting to save',
			'settings.downloads.saving' => 'Saving',
			'settings.downloads.saveFailed' => 'Save failed',
			'settings.downloads.retrySave' => 'Retry save',
			'settings.downloads.cancel' => 'Cancel',
			'settings.downloads.deleteTask' => 'Delete task',
			'settings.downloads.sync' => 'Sync',
			'settings.downloads.syncFailed' => 'Download sync failed',
			'settings.downloads.actionFailed' => 'Download action failed',
			'settings.downloads.expand' => 'Expand',
			'settings.downloads.collapse' => 'Collapse',
			'settings.proxy.title' => 'Network proxy',
			'settings.proxy.shortTitle' => 'Proxy',
			'settings.proxy.subtitle' => 'Pixiv API and image requests will use the selected proxy after saving.',
			'settings.proxy.open' => 'Set proxy',
			'settings.proxy.enabled' => 'Use proxy',
			'settings.proxy.enabledStatus' => 'Proxy is on',
			'settings.proxy.disabledStatus' => 'Direct connection',
			'settings.proxy.protocol' => 'Proxy protocol',
			'settings.proxy.protocolHttp' => 'HTTP',
			'settings.proxy.protocolSocks' => 'SOCKS',
			'settings.proxy.address' => 'IP address',
			'settings.proxy.addressHint' => '127.0.0.1',
			'settings.proxy.port' => 'Port',
			'settings.proxy.portHint' => '7890',
			'settings.proxy.helper' => 'Enter IP and port separately, for example 127.0.0.1 and 7890.',
			'settings.proxy.save' => 'Save',
			'settings.proxy.saved' => 'Proxy settings saved',
			'settings.proxy.required' => 'Enter an IP and port before turning this on.',
			'settings.proxy.invalid' => 'Enter a valid IP and port.',
			'settings.proxy.hostRequired' => 'Enter an IP.',
			'settings.proxy.portRequired' => 'Enter a port.',
			'settings.proxy.invalidHost' => 'Enter a valid IP or host name.',
			'settings.proxy.invalidPort' => 'Port must be 1-65535.',
			'settings.proxy.loadSystem' => 'Get system proxy',
			'settings.proxy.systemLoaded' => 'System proxy loaded',
			'settings.proxy.systemNotFound' => 'No system proxy detected',
			'settings.proxy.systemUnsupported' => 'System proxy detection is available on desktop only',
			'settings.proxy.systemLoadFailed' => 'Failed to get system proxy',
			'settings.proxy.entrySubtitleOn' => ({required Object url}) => 'On: ${url}',
			'settings.proxy.entrySubtitleOff' => 'Off',
			'settings.account.title' => 'Account',
			'settings.account.signedOutSubtitle' => 'Sign in to show your Pixiv account',
			'settings.account.notSignedIn' => 'Not signed in',
			'settings.account.signOut' => 'Sign out',
			'me.openProfile' => 'Open profile',
			'me.following' => 'My following',
			'me.followers' => 'My followers',
			'me.emptyFollowing' => 'No following users',
			'me.emptyFollowers' => 'No followers',
			'me.about' => 'About',
			'me.aboutSubtitle' => 'Version, updates, and project links',
			'me.settings' => 'Settings',
			'me.settingsSubtitle' => 'Theme, language, images, and downloads',
			'about.title' => 'About',
			'about.appName' => 'freepiv',
			'about.subtitle' => 'A lightweight client for browsing Pixiv content. Check the current version, look for updates, and open the project download page here.',
			'about.project' => 'Project',
			'about.projectPage' => 'Project page',
			'about.releasePage' => 'Release page',
			'about.versionInfo' => 'Version info',
			'about.appVersion' => 'App version',
			'about.latestVersion' => 'Latest version',
			'about.currentVersion' => ({required Object version, required Object buildNumber}) => 'Current version ${version}+${buildNumber}',
			'about.noCachedUpdate' => 'No cached update',
			'about.loading' => 'Loading',
			'about.community' => 'Community',
			'about.telegram' => 'Telegram',
			'about.discord' => 'Discord',
			'about.checkUpdate' => 'Check update',
			'about.checkingUpdateShort' => 'Checking',
			'about.checkingUpdate' => 'Checking for updates...',
			'about.noUpdate' => 'You are on the latest version',
			'about.updateAvailable' => ({required Object version, required Object buildNumber}) => 'New version available: ${version}+${buildNumber}',
			'about.checkUpdateFailed' => 'Failed to check for updates',
			'about.downloadPage' => 'Download page',
			'about.downloadAssetUnavailable' => 'No download asset matched this platform. Opening the release page.',
			'about.openDownloadFailed' => 'Failed to open the download page',
			'about.openLinkFailed' => 'Failed to open link',
			'home.emptyTitle' => 'No recommendations yet',
			'home.emptyMessage' => 'Pull down to fetch recommendations again.',
			'home.rankings' => 'Rankings',
			'home.seeMore' => 'See more',
			'home.recommended' => 'Recommended',
			'home.illustrations' => 'Illust',
			'home.manga' => 'Manga',
			'home.novels' => 'Novels',
			'home.users' => 'Users',
			'ranking.emptyTitle' => 'No ranking works',
			'ranking.emptyMessage' => 'Pull down to fetch the ranking again.',
			'ranking.types.illustrations' => 'Illust',
			'ranking.types.manga' => 'Manga',
			'ranking.types.novels' => 'Novels',
			'ranking.modes.day' => 'Daily',
			'ranking.modes.dayR18' => 'Daily R-18',
			'ranking.modes.dayMale' => 'Daily Male',
			'ranking.modes.dayMaleR18' => 'Daily Male R-18',
			'ranking.modes.dayFemale' => 'Daily Female',
			'ranking.modes.dayFemaleR18' => 'Daily Female R-18',
			'ranking.modes.dayAi' => 'AI-generated',
			'ranking.modes.dayR18Ai' => 'AI-generated R-18',
			'ranking.modes.week' => 'Weekly',
			'ranking.modes.weekR18' => 'Weekly R-18',
			'ranking.modes.weekOriginal' => 'Weekly Original',
			'ranking.modes.weekRookie' => 'Weekly Rookie',
			'ranking.modes.month' => 'Monthly',
			'search.placeholder' => 'Search tags, illust ID, or user ID',
			'search.submit' => 'Search',
			'search.trendingTags' => 'Trending Tags',
			'search.emptyTrendingTitle' => 'No trending tags',
			'search.emptyTrendingMessage' => 'Pull down to load trending tags again.',
			'search.noSuggestions' => 'No suggestions',
			'search.filters.title' => 'Search filters',
			'search.filters.sort' => 'Sort',
			'search.filters.target' => 'Target',
			'search.filters.date' => 'Date',
			'search.filters.bookmarks' => 'Bookmarks',
			'search.type.illustManga' => 'Illust & Manga',
			'search.type.novel' => 'Novel',
			'search.type.user' => 'User',
			'search.sort.newest' => 'Newest',
			'search.sort.oldest' => 'Oldest',
			'search.sort.popular' => 'Popular',
			'search.target.tags' => 'Tags',
			'search.target.exactTags' => 'Exact tags',
			'search.target.titleAndCaption' => 'Title & caption',
			'search.date.any' => 'Any date',
			'search.date.today' => 'Today',
			'search.date.days7' => '7 days',
			'search.date.month1' => '1 month',
			'search.date.months6' => '6 months',
			'search.date.year1' => '1 year',
			'search.date.custom' => 'Custom',
			'search.bookmarks.any' => 'Any bookmarks',
			'search.bookmarks.atLeast' => ({required Object count}) => '${count}+ bookmarks',
			'search.direct.illust' => ({required Object id}) => 'Illust: ${id}',
			'search.direct.user' => ({required Object id}) => 'User: ${id}',
			'search.direct.novel' => ({required Object id}) => 'Novel: ${id}',
			'search.empty.illustrations' => 'No illustrations found',
			'search.empty.novels' => 'No novels found',
			'search.empty.users' => 'No users found',
			'user.tabs.illustrations' => 'Illustrations',
			'user.tabs.manga' => 'Manga',
			'user.tabs.novels' => 'Novels',
			'user.tabs.bookmarks' => 'Bookmarks',
			'user.tabs.following' => 'Following',
			'user.tabs.profile' => 'Details',
			'user.stats.illustrations' => 'Illusts',
			'user.stats.manga' => 'Manga',
			'user.stats.novels' => 'Novels',
			'user.stats.following' => 'Following',
			'user.bookmarks.illustManga' => 'Illust & Manga',
			'user.bookmarks.novels' => 'Novels',
			'user.empty.illustrations' => 'No Illusts',
			'user.empty.manga' => 'No manga',
			'user.empty.novels' => 'No novels',
			'user.empty.bookmarkIllustrations' => 'No public illustration or manga bookmarks',
			'user.empty.bookmarkNovels' => 'No public novel bookmarks',
			'user.empty.following' => 'No following users',
			'user.empty.profile' => 'No public profile details',
			'user.profile.birthday' => 'Birthday',
			'user.profile.region' => 'Region',
			'user.profile.job' => 'Job',
			'user.profile.webpage' => 'Website',
			'user.profile.twitter' => 'Twitter',
			'user.profile.pawoo' => 'Pawoo',
			'user.profile.openLink' => 'Open link',
			'user.meta.novelChars' => ({required Object count}) => '${count} chars',
			'user.meta.novelPages' => ({required Object count}) => '${count} pages',
			'user.error.missingUser' => 'User id or user detail is missing.',
			'newest.audience.following' => 'Following',
			'newest.audience.mypixiv' => 'MyPixiv',
			'newest.audience.everyone' => 'Everyone',
			'newest.workType.illustManga' => 'Illust & Manga',
			'newest.workType.illust' => 'Illust',
			'newest.workType.manga' => 'Manga',
			'newest.workType.novel' => 'Novels',
			'newest.workType.compactArt' => 'Art',
			'newest.workType.compactIllust' => 'Illust',
			'newest.workType.compactManga' => 'Manga',
			'newest.workType.compactNovel' => 'Novel',
			'newest.followScope.title' => 'Follow Scope',
			'newest.followScope.all' => 'All follows',
			'newest.followScope.private' => 'Private follows',
			'newest.followScope.public' => 'Public follows',
			'newest.followScope.compactAll' => 'All',
			'newest.followScope.compactPrivate' => 'Private',
			'newest.followScope.compactPublic' => 'Public',
			'newest.emptyTitle' => 'No newest works',
			'newest.compactFilter' => ({required Object workType, required Object scope}) => '${workType} · ${scope}',
			'newest.novelChars' => ({required Object count}) => '${count} chars',
			'newest.novelPages' => ({required Object count}) => '${count} pages',
			'illust.contextMenu.download' => 'Download',
			'illust.contextMenu.downloadAll' => 'Download all',
			'illust.contextMenu.copyImage' => 'Copy image',
			'illust.imageLabels.original' => 'original image',
			'illust.imageLabels.large' => 'large image',
			'illust.toast.downloadStarted' => 'Downloading image',
			'illust.toast.downloadAllQueued' => ({required Object count}) => '${count} images added to the download queue',
			'illust.toast.downloadComplete' => ({required Object path}) => 'Download complete: ${path}',
			'illust.toast.downloadFailed' => 'Download failed',
			'illust.toast.copying' => ({required Object label}) => 'Copying ${label}',
			'illust.toast.copied' => ({required Object label}) => 'Copied ${label}',
			'illust.toast.copiedValue' => ({required Object label, required Object value}) => 'Copied ${label}: ${value}',
			'illust.toast.copyFailed' => ({required Object label}) => 'Failed to copy ${label}',
			'illust.tooltip.previousImage' => 'Previous image',
			'illust.tooltip.nextImage' => 'Next image',
			'illust.tooltip.backToDetail' => 'Back to image detail',
			'illust.tooltip.removeBookmark' => 'Remove bookmark',
			'illust.tooltip.addBookmark' => 'Add bookmark',
			'illust.section.tags' => 'Tags',
			'illust.section.caption' => 'Caption',
			'illust.section.details' => 'Details',
			'illust.section.creator' => 'Creator',
			'illust.section.recentWorks' => 'Recent works',
			'illust.section.comments' => 'Comments',
			'illust.section.commentsWithCount' => ({required Object count}) => 'Comments (${count})',
			'illust.section.relatedWorks' => 'Related works',
			'illust.metadata.type' => 'Type',
			'illust.metadata.created' => 'Created',
			'illust.badge.aiArtwork' => 'AI Artwork',
			'illust.badge.original' => 'Original',
			'illust.stats.size' => 'Size',
			'illust.stats.views' => 'Views',
			'illust.stats.bookmarks' => 'Bookmarks',
			'illust.stats.pages' => 'Pages',
			'illust.tags.none' => 'No tags',
			'illust.tags.tag' => 'tag',
			'illust.comments.failed' => 'Failed to load comments',
			'illust.comments.empty' => 'No comments yet',
			'illust.comments.moreAvailable' => 'More comments available',
			'illust.comments.hasReplies' => 'Has replies',
			'illust.comments.open' => 'Open comments',
			'illust.comments.reply' => 'Reply',
			'illust.comments.replyingTo' => ({required Object name}) => 'Replying to ${name}',
			'illust.comments.loadReplies' => 'Load replies',
			'illust.comments.loadMoreReplies' => 'Load more replies',
			'illust.comments.repliesFailed' => 'Failed to load replies',
			'illust.comments.sendFailed' => 'Failed to send comment',
			'illust.comments.delete' => 'Delete',
			'illust.comments.deleteFailed' => 'Failed to delete comment',
			'illust.comments.inputHint' => 'Write a comment',
			'illust.comments.replyInputHint' => ({required Object name}) => 'Reply to ${name}',
			'illust.comments.emoji' => 'Emoji',
			'illust.comments.stamp' => 'Stamp',
			'illust.works.failed' => 'Failed to load works',
			'illust.works.empty' => 'No works to show',
			'illust.related.failed' => 'Failed to load related works',
			'illust.related.empty' => 'No related works',
			'illust.related.viewMore' => 'View more related works',
			'novel.detail.images' => 'Images',
			'novel.detail.series' => 'Series',
			'novel.detail.content' => 'Content',
			'novel.detail.startReading' => 'Start reading',
			'novel.detail.totalChars' => ({required Object count}) => '${count} chars',
			'novel.detail.paragraphCount' => ({required Object count}) => '${count} paragraphs',
			'novel.detail.segmentCount' => ({required Object count}) => '${count} pages',
			'novel.reader.title' => 'Reading',
			'novel.reader.body' => 'Body',
			'novel.reader.chapters' => 'Chapters',
			'novel.reader.settings' => 'Reading settings',
			'novel.reader.emptyBody' => 'No body text',
			'novel.reader.totalChars' => ({required Object count}) => '${count} chars',
			'novel.reader.pagePosition' => ({required Object current, required Object total}) => '${current} / ${total} pages',
			'novel.reader.pageTotal' => ({required Object total}) => '${total} pages',
			'novel.reader.currentPage' => ({required Object page}) => 'Page ${page}',
			'novel.reader.readingProgress' => 'Reading progress',
			'novel.reader.previousPage' => 'Previous page',
			'novel.reader.nextPage' => 'Next page',
			'novel.reader.display' => 'Display',
			'novel.reader.fontSize' => 'Font size',
			'novel.reader.lineHeight' => 'Line height',
			'novel.reader.noChapterMarkers' => 'No chapter markers',
			'novel.reader.close' => 'Close',
			'novel.reader.decrease' => 'Decrease',
			'novel.reader.increase' => 'Increase',
			'novel.reader.shortcutsTitle' => 'Shortcuts',
			'novel.reader.shortcutsHelp' => 'Left/Right or A/D turn pages; Up/Down or W/S scroll',
			'follow.tooltipFollow' => 'Follow user',
			'follow.tooltipUnfollow' => 'Unfollow',
			'follow.followed' => 'Following',
			'follow.notFollowed' => 'Not following',
			'richText.twitterUser' => ({required Object username}) => 'Twitter: ${username}',
			'richText.illustId' => ({required Object id}) => 'Illust ID: ${id}',
			'richText.userId' => ({required Object id}) => 'User ID: ${id}',
			_ => null,
		};
	}
}
