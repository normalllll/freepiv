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
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.enUs,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en-US>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$downloadEntry$en_US downloadEntry = Translations$downloadEntry$en_US.internal(_root);
	late final Translations$novelText$en_US novelText = Translations$novelText$en_US.internal(_root);
	late final Translations$signOut$en_US signOut = Translations$signOut$en_US.internal(_root);
	late final Translations$appSearch$en_US appSearch = Translations$appSearch$en_US.internal(_root);
	late final Translations$frost$en_US frost = Translations$frost$en_US.internal(_root);
	late final Translations$nativeWindow$en_US nativeWindow = Translations$nativeWindow$en_US.internal(_root);
	late final Translations$discover$en_US discover = Translations$discover$en_US.internal(_root);
	late final Translations$app$en_US app = Translations$app$en_US.internal(_root);
	late final Translations$navigation$en_US navigation = Translations$navigation$en_US.internal(_root);
	late final Translations$errors$en_US errors = Translations$errors$en_US.internal(_root);
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
	late final Translations$fanbox$en_US fanbox = Translations$fanbox$en_US.internal(_root);
	late final Translations$pixivision$en_US pixivision = Translations$pixivision$en_US.internal(_root);
	late final Translations$artworkCard$en_US artworkCard = Translations$artworkCard$en_US.internal(_root);
	late final Translations$illustDetail$en_US illustDetail = Translations$illustDetail$en_US.internal(_root);
	late final Translations$viewer$en_US viewer = Translations$viewer$en_US.internal(_root);
	late final Translations$userPage$en_US userPage = Translations$userPage$en_US.internal(_root);
	late final Translations$novelDetail$en_US novelDetail = Translations$novelDetail$en_US.internal(_root);
	late final Translations$commentsPage$en_US commentsPage = Translations$commentsPage$en_US.internal(_root);
	late final Translations$searchPage$en_US searchPage = Translations$searchPage$en_US.internal(_root);
	late final Translations$downloadsPage$en_US downloadsPage = Translations$downloadsPage$en_US.internal(_root);
	late final Translations$loginPage$en_US loginPage = Translations$loginPage$en_US.internal(_root);
	late final Translations$fanboxPage$en_US fanboxPage = Translations$fanboxPage$en_US.internal(_root);
	late final Translations$discoverPage$en_US discoverPage = Translations$discoverPage$en_US.internal(_root);
	late final Translations$privacy$en_US privacy = Translations$privacy$en_US.internal(_root);
	late final Translations$bookmarkOptions$en_US bookmarkOptions = Translations$bookmarkOptions$en_US.internal(_root);
	late final Translations$series$en_US series = Translations$series$en_US.internal(_root);
	late final Translations$watchlist$en_US watchlist = Translations$watchlist$en_US.internal(_root);
	late final Translations$profileEdit$en_US profileEdit = Translations$profileEdit$en_US.internal(_root);
	late final Translations$workspaceEdit$en_US workspaceEdit = Translations$workspaceEdit$en_US.internal(_root);
}

// Path: downloadEntry
class Translations$downloadEntry$en_US {
	Translations$downloadEntry$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get retryFailed => 'Retry failed';
	String get clearCompleted => 'Clear completed';
	String get viewAll => 'View all';
}

// Path: novelText
class Translations$novelText$en_US {
	Translations$novelText$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get loadFailed => 'The text couldn\'t load';
}

// Path: signOut
class Translations$signOut$en_US {
	Translations$signOut$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Sign out of Pixiv?';
	String get message => 'You need to sign in again to browse. Downloads and settings stay on this device.';
	String get confirm => 'Sign out';
}

// Path: appSearch
class Translations$appSearch$en_US {
	Translations$appSearch$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get placeholder => 'Search illustrations, novels, users';
	String get allHistory => 'All history';
	String get allTrendingTags => 'All trending tags';
	String searchIllust({required Object query}) => 'Search illustrations & manga for “${query}”';
	String searchNovel({required Object query}) => 'Search novels for “${query}”';
	String searchUser({required Object query}) => 'Search users for “${query}”';
	String get openGroup => 'Open';
	String get tagGroup => 'Tags';
	String get noSuggestions => 'No suggestions';
	String get suggestionsFailed => 'Couldn\'t load suggestions';
}

// Path: frost
class Translations$frost$en_US {
	Translations$frost$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get retry => 'Retry';
	String get error => 'Error';
	String get errorDetails => 'Error details';
	String get copyDetails => 'Copy details';
	String get copied => 'Copied';
	String get loading => 'Loading';
	String get actionSucceeded => 'Action succeeded';
	String get actionFailed => 'Action failed';
	String get loadFailed => 'Couldn\'t load';
	String get noItems => 'No items';
	String get noMoreItems => 'No more items';
	String get pullToRefresh => 'Pull to refresh';
	String get releaseToRefresh => 'Release to refresh';
	String get refreshing => 'Refreshing';
	String get refreshComplete => 'Refresh complete';
	String get refreshFailed => 'Refresh failed';
	String get previous => 'Previous';
	String get next => 'Next';
	String get back => 'Back';
	String get more => 'More';
	String get expandNavigation => 'Expand sidebar';
	String get collapseNavigation => 'Collapse sidebar';
	String get clearText => 'Clear text';
	String get search => 'Search';
	String noResults({required Object query}) => 'No results for “${query}”';
	String get clearSearch => 'Clear search';
	String get dismiss => 'Dismiss';
	String get expandText => 'Show more';
	String get collapseText => 'Show less';
	String get showAll => 'Show all';
	String get copy => 'Copy';
	String get clearAll => 'Clear all';
	String get showPassword => 'Show password';
	String get hidePassword => 'Hide password';
	String get chooseDate => 'Choose date';
	String get chooseTime => 'Choose time';
	String get increment => 'Increase';
	String get decrement => 'Decrease';
	String get reorderHandle => 'Reorder';
	String get sortAscending => 'Ascending';
	String get sortDescending => 'Descending';
	String get play => 'Play';
	String get pause => 'Pause';
	String get loop => 'Loop';
	String get mute => 'Mute';
	String get unmute => 'Unmute';
	String get fullscreen => 'Full screen';
	String get exitFullscreen => 'Exit full screen';
	String get minimize => 'Minimize';
	String get maximize => 'Maximize';
	String get restore => 'Restore';
	String get close => 'Close';
	String get cancel => 'Cancel';
	String get apply => 'Apply';
	String get clear => 'Clear';
	String get choose => 'Choose';
	String get showInFolder => 'Show in folder';
	String selectedCount({required Object count}) => '${count} selected';
	String pageOf({required Object page, required Object total}) => 'Page ${page} of ${total}';
	String get selectAll => 'Select all';
	String get done => 'Done';
	String itemPosition({required Object position, required Object total}) => '${position} of ${total}';
	String tableDimensions({required Object rows, required Object columns}) => '${rows} rows, ${columns} columns';
	String get taskQueued => 'Queued';
	String get taskRunning => 'Downloading';
	String get taskPaused => 'Paused';
	String get taskCompleted => 'Completed';
	String get taskFailed => 'Failed';
	String get taskCancelled => 'Cancelled';
	String get remove => 'Remove';
	String get seek => 'Playback position';
	String showReplies({required Object count}) => 'Show ${count} replies';
	String moreMedia({required Object count}) => '${count} more images';
	String navigationCount({required Object count}) => '${count} items';
	String navigationProgress({required Object progress}) => '${progress}% complete';
	String get listSeparator => ', ';
	String retryAfter({required Object seconds}) => 'Retry in ${seconds} s';
}

// Path: nativeWindow
class Translations$nativeWindow$en_US {
	Translations$nativeWindow$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get minimize => 'Minimize';
	String get maximize => 'Maximize';
	String get restore => 'Restore';
	String get close => 'Close';
	String get illust => 'Illust';
	String get manga => 'Manga';
	String get novel => 'Novel';
	String workFallback({required Object type, required Object id}) => '${type}: ${id}';
	String workTitle({required Object type, required Object id, required Object title}) => '${type}: ${id} · ${title}';
	String relatedTitle({required Object title}) => 'Related works · ${title}';
	String get user => 'User';
	String userFallback({required Object id}) => 'User: ${id}';
	String viewerTitle({required Object title, required Object page, required Object total}) => '${title} · ${page}/${total}';
}

// Path: discover
class Translations$discover$en_US {
	Translations$discover$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get searchHint => 'Search Pixiv';
	String get history => 'Recent searches';
	String get viewAll => 'View all';
	String get clearHistory => 'Clear history';
	String get deleteHistoryItem => 'Remove recent search';
	String get emptyHistory => 'Your searches will appear here';
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
	String get backToFirst => 'Back to first page';
	String get activity => 'Activity';
	String get home => 'Home';
	String get search => 'Search';
	String get newest => 'Newest';
	String get ranking => 'Ranking';
	String get me => 'Me';
	String get settings => 'Settings';
	String get more => 'More';
	String get expand => 'Expand navigation';
	String get collapse => 'Collapse navigation';
	String get downloads => 'Downloads';
	String get about => 'About';
}

// Path: errors
class Translations$errors$en_US {
	Translations$errors$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get generic => 'Unable to load content. Please try again.';
	String get connection => 'Check your connection and try again.';
	String get session => 'Your session has expired. Please sign in again.';
	String get forbidden => 'You do not have access to this content.';
	String get missing => 'This content is no longer available.';
}

// Path: common
class Translations$common$en_US {
	Translations$common$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get viewLog => 'View log';
	String get apply => 'Apply';
	String get reset => 'Reset';
	String get discover => 'Discover';
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
	String get errorDetails => 'Error details';
	String get copyDetails => 'Copy details';
	String get detailsCopied => 'Error details copied';
	String get refresh => 'Refresh';
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
	String get openingBrowser => 'Opening browser';
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
	String get profile => 'My profile';
	String get openProfile => 'Open profile';
	String get following => 'My following';
	String get followers => 'My followers';
	String get mypixiv => 'My pixiv';
	String get emptyFollowing => 'No following users';
	String get emptyFollowers => 'No followers';
	String get emptyMypixiv => 'No My pixiv friends';
	String get about => 'About';
	String get settings => 'Settings';
	String get watchlist => 'Follow-ups';
	String get editProfile => 'Edit profile';
	String get workspace => 'Workspace';
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
	String get checkingUpdate => 'Checking for updates';
	String get noUpdate => 'You are on the latest version';
	String updateAvailable({required Object version, required Object buildNumber}) => 'New version available: ${version}+${buildNumber}';
	String get checkUpdateFailed => 'Failed to check for updates';
	String get downloadPage => 'Download page';
	String get downloadAssetUnavailable => 'No download asset matched this platform. Opening the release page.';
	String get openDownloadFailed => 'Failed to open the download page';
	String get openLinkFailed => 'Failed to open link';
	String latestValue({required Object version, required Object buildNumber}) => 'Latest: ${version}+${buildNumber}';
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
	String get r18Section => 'R-18';
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
	late final Translations$search$contentType$en_US contentType = Translations$search$contentType$en_US.internal(_root);
	late final Translations$search$ratio$en_US ratio = Translations$search$ratio$en_US.internal(_root);
	late final Translations$search$size$en_US size = Translations$search$size$en_US.internal(_root);
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
	String get noPublicWorks => 'No public works';
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
	late final Translations$newest$empty$en_US empty = Translations$newest$empty$en_US.internal(_root);
}

// Path: illust
class Translations$illust$en_US {
	Translations$illust$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get pageJump => 'Go to page';
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
	String get follow => 'Follow';
	String get restrictTitle => 'Follow as';
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

// Path: fanbox
class Translations$fanbox$en_US {
	Translations$fanbox$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get accountConnected => 'Connected';
	String get updateSession => 'Update Cookie';
	String get title => 'FANBOX';
	String get home => 'Following feed';
	String get feedGroup => 'Feed';
	String get supporting => 'Supporting feed';
	String get following => 'Following';
	String get recommended => 'Discover';
	String get pixiv => 'From Pixiv';
	String get plans => 'Supported plans';
	String get searchCreators => 'Creators';
	String get searchTags => 'Tags';
	String get notices => 'Notifications';
	String get messages => 'Messages';
	String get bookmarks => 'Saved posts';
	String get login => 'Sign in to FANBOX';
	String get cookieHint => 'Paste FANBOXSESSID or FANBOXSESSID=value';
	String get importSession => 'Import session file';
	String get openWebsite => 'Open FANBOX website';
	String get loginHelp => 'Log in in your browser, then copy FANBOXSESSID from Developer Tools → Application → Cookies. Your Pixiv login is separate.';
	String get logout => 'Sign out';
	String get empty => 'No items yet';
	String get loadMore => 'Load more';
	String get searchHint => 'Creator name, ID or tag';
	String get creatorId => 'Open creator by ID';
	String get posts => 'Posts';
	String get creatorPlans => 'Creator plans';
	String restricted({required Object fee}) => 'Support at least ¥${fee}/month to read';
	String get free => 'Public';
	String get readable => 'Available to you';
	String get viewPlans => 'View support plans';
	String monthlyFee({required Object fee}) => '¥${fee}/month';
	String get supportOnWebsite => 'View plan on FANBOX';
	String get follow => 'Follow';
	String get unfollow => 'Unfollow';
	String get like => 'Like';
	String get liked => 'Liked';
	String get comments => 'Comments';
	String get reply => 'Reply';
	String get commentHint => 'Write a comment';
	String get deleteComment => 'Delete comment';
	String get deleteConfirm => 'Delete this comment?';
	String get send => 'Send';
	String get save => 'Save post';
	String get saved => 'Saved';
	String get download => 'Download';
	String get downloadAll => 'Download all media';
	String get downloadCreator => 'Download creator posts';
	String get fanCard => 'Fan card';
	String get previous => 'Previous post';
	String get next => 'Next post';
	String get unknown => 'This content format is not supported yet. Open the original post to view it.';
	String get openOriginal => 'Open original';
	String get openLink => 'Open link';
	String get sessionExpired => 'Your FANBOX session is invalid or expired. Please sign in again.';
	String get requestFailed => 'Unable to load FANBOX. Check your connection or retry.';
	String get accessDenied => 'FANBOX denied this request. Check your access or open the website.';
	String get rateLimited => 'Too many requests. Please try again later.';
	String get loginFailed => 'Could not validate the session. Check the Cookie and proxy settings.';
	String get working => 'Working';
	String get cancel => 'Cancel';
	String get retry => 'Retry';
	String get done => 'Done';
	String get newNotice => 'Unread';
	String get unknownNotice => 'FANBOX activity';
	String get chooseFolder => 'Choose download folder';
	String get unsupportedUrl => 'This link cannot be opened.';
	String get restrictedInfo => 'This post remains visible, but its content requires a qualifying support plan.';
	String get noPlans => 'No available plans';
	String get downloadPreparing => 'Collecting accessible posts';
	String downloadQueued({required Object count}) => '${count} files added to the download queue';
	String get downloadNothingNew => 'Everything here is already in the download queue';
	String get browserLogin => 'Log in with browser';
	String get manualLogin => 'Enter Cookie manually';
	String get browserHelp => 'Complete sign-in on the official website. This window closes after your session is verified.';
	String get browserCheck => 'I am signed in';
	String get browserCheckFailed => 'Verification failed. Choose “I am signed in” to retry.';
	String get browserUnavailable => 'Could not open or read the login page. Retry or enter a Cookie manually.';
	String get browserProxyUnsupported => 'This browser cannot use the configured proxy. Use a supported HTTP/SOCKS5 proxy, a system proxy, or enter a Cookie manually.';
	String get browserCleanupFailed => 'Signed out, but browser data could not be cleared. Cleanup will be retried before the next browser login.';
	String get browserTimedOut => 'Login timed out. Close this window and start again.';
	String get browserBusy => 'Another login window is still closing. Please try again shortly.';
	String get runtimeTitle => 'Install login component';
	String get runtimeMissing => 'WebView2 Runtime is missing or unavailable. Install it, then check again.';
	String get runtimeInstall => 'Get WebView2 from Microsoft';
	String get runtimeHelp => 'Choose Evergreen Runtime on the Microsoft website. If the online installer fails, use the standalone installer. Other app features remain available.';
	String get runtimeRecheck => 'Check again';
}

// Path: pixivision
class Translations$pixivision$en_US {
	Translations$pixivision$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'pixivision';
	String get searchHint => 'Search articles';
	String get latest => 'Latest';
	String get ranking => 'Monthly ranking';
	String get recommended => 'Recommended';
	String get tags => 'Tags';
	String get allCategories => 'All categories';
	String get empty => 'No articles found';
	String get requestFailed => 'Could not load content. Please retry.';
	String get loadMore => 'Load more';
	String get openOriginal => 'Open original';
	String get openFailed => 'Could not open the link';
	String get translations => 'Languages';
	String get previous => 'Previous';
	String get next => 'Next';
	String get unsupported => 'This content can be viewed on the original page.';
	String userId({required Object id}) => 'User ID: ${id}';
	String userName({required Object name}) => 'User: ${name}';
}

// Path: artworkCard
class Translations$artworkCard$en_US {
	Translations$artworkCard$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get ai => 'AI';
	String get ugoira => 'Animation';
	String semantics({required Object title, required Object author}) => '${title} by ${author}';
	String menuHeader({required Object title, required Object author}) => '${title} · ${author}';
	String get openAuthor => 'Open author';
}

// Path: illustDetail
class Translations$illustDetail$en_US {
	Translations$illustDetail$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get downloadGif => 'Download GIF';
	String get copyGif => 'Copy GIF';
	String get pause => 'Pause';
	late final Translations$illustDetail$ugoira$en_US ugoira = Translations$illustDetail$ugoira$en_US.internal(_root);
	String bookmarkCount({required Object count}) => 'Bookmark ${count}';
	String get copyId => 'Copy ID';
	String views({required Object count}) => '${count} views';
	String pages({required Object count}) => '${count} pages';
	String get copyTag => 'Copy tag';
	String allComments({required Object count}) => 'View all ${count} comments';
	String get moreRelated => 'View more';
	String get missing => 'This work does not exist or is not visible to you';
}

// Path: viewer
class Translations$viewer$en_US {
	Translations$viewer$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String position({required Object title, required Object page, required Object total}) => '${title} · ${page} / ${total}';
	String get loading => 'Loading the original image';
}

// Path: userPage
class Translations$userPage$en_US {
	Translations$userPage$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get copyLink => 'Copy profile link';
	String get linkCopied => 'Link copied';
	String get openInBrowser => 'Open in browser';
	String get copyBio => 'Copy bio';
	String get bioCopied => 'Bio copied';
	String get copyFailed => 'Could not copy';
	String get openFailed => 'Could not open the link';
}

// Path: novelDetail
class Translations$novelDetail$en_US {
	Translations$novelDetail$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get missing => 'This novel does not exist or is not visible to you';
	String get bookmark => 'Bookmark';
	String get bookmarked => 'Bookmarked';
	String bookmarks({required Object count}) => '${count} bookmarks';
	String get related => 'Related novels';
	String get noRelated => 'No related novels';
	String get authorNovels => 'More by the author';
}

// Path: commentsPage
class Translations$commentsPage$en_US {
	Translations$commentsPage$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get empty => 'No comments yet. Write the first one';
}

// Path: searchPage
class Translations$searchPage$en_US {
	Translations$searchPage$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get minWidth => 'Minimum width';
	String get minHeight => 'Minimum height';
	String get clearFilters => 'Clear filters';
	String get noUserFilters => 'User search has no filters';
}

// Path: downloadsPage
class Translations$downloadsPage$en_US {
	Translations$downloadsPage$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get all => 'All';
	String get inProgress => 'In progress';
	String get nothingInProgress => 'No downloads in progress';
	String get nothingDone => 'Nothing downloaded yet';
	String failedGroup({required Object count}) => '${count} failed';
}

// Path: loginPage
class Translations$loginPage$en_US {
	Translations$loginPage$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get intro => 'Sign in with your Pixiv account in the browser, then come back here';
	String get signIn => 'Sign in in the browser';
	String get waiting => 'Finish signing in in the browser';
	String get reopen => 'Open the browser again';
}

// Path: fanboxPage
class Translations$fanboxPage$en_US {
	Translations$fanboxPage$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get groupFeed => 'Feed';
	String get groupDiscover => 'Discover';
	String get groupMine => 'Mine';
	String get searchPlaceholder => 'Search FANBOX';
	String openCreator({required Object id}) => 'Open creator @${id}';
	String searchCreators({required Object query}) => 'Search creators for “${query}”';
	String searchTags({required Object query}) => 'Search tags for “${query}”';
	String get accountSettings => 'FANBOX account settings';
	String get localOnly => 'Saved posts stay on this device only';
	String get creatorPage => 'Open creator';
	String get noComments => 'No comments yet';
	String get collecting => 'Collecting posts';
}

// Path: discoverPage
class Translations$discoverPage$en_US {
	Translations$discoverPage$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get noArticles => 'No articles right now';
}

// Path: privacy
class Translations$privacy$en_US {
	Translations$privacy$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get label => 'Visibility';
	String get public => 'Public';
	String get private => 'Private';
}

// Path: bookmarkOptions
class Translations$bookmarkOptions$en_US {
	Translations$bookmarkOptions$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Bookmark options';
	String get tags => 'Tags';
	String get addTag => 'Add a tag and press Enter';
	String get noTags => 'No tags to choose from yet';
	String get remove => 'Remove bookmark';
	String get save => 'Save';
	String get failed => 'Could not save the bookmark';
	String get loadFailed => 'Could not load the bookmark';
}

// Path: series
class Translations$series$en_US {
	Translations$series$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Series';
	String link({required Object title}) => 'Series · ${title}';
	String episodes({required Object count}) => '${count} episodes';
	String get concluded => 'Completed';
	String get ongoing => 'Ongoing';
	String get watch => 'Follow up';
	String get watching => 'Following up';
	String get watchFailed => 'Could not change the follow-up';
	String get startFromFirst => 'Start from episode 1';
	String get empty => 'This series has no works yet';
}

// Path: watchlist
class Translations$watchlist$en_US {
	Translations$watchlist$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Follow-ups';
	String get manga => 'Manga';
	String get novels => 'Novels';
	String get emptyManga => 'No manga series followed up yet';
	String get emptyNovels => 'No novel series followed up yet';
	String get unavailable => 'This series cannot be shown';
	String updated({required Object date}) => 'Updated ${date}';
}

// Path: profileEdit
class Translations$profileEdit$en_US {
	Translations$profileEdit$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Edit profile';
	String get name => 'Nickname';
	String get nameRequired => 'Enter a nickname';
	String get gender => 'Gender';
	String get genderUnknown => 'Not specified';
	String get genderMale => 'Male';
	String get genderFemale => 'Female';
	String get birthday => 'Birthday';
	String get notSet => 'Not set';
	String get region => 'Region';
	String get country => 'Country';
	String get job => 'Occupation';
	String get website => 'Website';
	String get twitter => 'Twitter';
	String get bio => 'Bio';
	String get save => 'Save';
	String get saved => 'Saved';
	String get failed => 'Could not save';
	String get discardTitle => 'Discard your changes?';
	String get discardMessage => 'Your changes have not been saved.';
	String get discard => 'Discard';
	String get keepEditing => 'Keep editing';
}

// Path: workspaceEdit
class Translations$workspaceEdit$en_US {
	Translations$workspaceEdit$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Workspace';
	String get pc => 'Computer';
	String get monitor => 'Monitor';
	String get tool => 'Software';
	String get scanner => 'Scanner';
	String get tablet => 'Tablet';
	String get mouse => 'Mouse';
	String get printer => 'Printer';
	String get desktop => 'On the desk';
	String get music => 'Music';
	String get desk => 'Desk';
	String get chair => 'Chair';
	String get comment => 'Other';
}

// Path: settings.theme
class Translations$settings$theme$en_US {
	Translations$settings$theme$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Appearance';
	String get displayMode => 'Display mode';
	String get tone => 'Tone';
	String get neutral => 'Neutral';
	String get cool => 'Cool';
	String get warm => 'Warm';
	String get systemNeutralHint => 'System mode uses a neutral tone';
	String get lightAccent => 'Light accent';
	String get darkAccent => 'Dark accent';
	String get systemEditingLight => 'Currently editing the light accent used by the system';
	String get systemEditingDark => 'Currently editing the dark accent used by the system';
	String get presetPink => 'Default pink';
	String get presetBlue => 'Blue';
	String get presetTeal => 'Teal';
	String get presetViolet => 'Violet';
	String get presetAmber => 'Amber';
	String get presetOrange => 'Orange';
	String get custom => 'Custom';
	String get defaultAccent => 'Default pink';
	String get restoreDefault => 'Restore default pink';
	String get editLightAccent => 'Custom light accent';
	String get editDarkAccent => 'Custom dark accent';
	String get hue => 'Hue';
	String get saturation => 'Saturation';
	String get value => 'Brightness';
	String get hex => 'HEX color';
	String get invalidHex => 'Enter a six-digit HEX color';
	String get preview => 'Preview';
	String get previewButton => 'Button';
	String get rejectedLight => 'This color is too close to light backgrounds. Choose another color.';
	String get rejectedDark => 'This color is too close to dark backgrounds. Choose another color.';
	String get weakContrast => 'This color may be difficult to distinguish on some backgrounds.';
	String get applyAnyway => 'Apply anyway';
	String get useDefault => 'Use default pink';
	String get saving => 'Saving';
	String get saveFailed => 'Could not save appearance. Try again.';
	String get unsaved => 'Appearance changes are not saved yet.';
	String get system => 'System';
	String get light => 'Light';
	String get dark => 'Dark';
	String get background => 'Background';
	String get ambientBlur => 'Blur';
	String get mica => 'Mica';
	String get backgroundOff => 'Off';
	String get backgroundIntensity => 'Intensity';
	String get systemTransparencyReduced => 'System transparency is reduced';
}

// Path: settings.language
class Translations$settings$language$en_US {
	Translations$settings$language$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Language';
	String get systemDefault => 'System default';
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
	String get retryFailed => 'Retry all failed tasks';
	String get clearCompleted => 'Clear completed tasks';
	String get syncFailed => 'Download sync failed';
	String get actionFailed => 'Download action failed';
	String get collapse => 'Collapse';
	String get viewAll => 'View all downloads';
	String badgeFailures({required Object count}) => 'Failed downloads: ${count}';
	String badgeActive({required Object count}) => 'Active downloads: ${count}';
	String filesProgress({required Object done, required Object total}) => '${done} / ${total} files';
	String filesFailed({required Object count}) => '${count} failed';
	String collectingPosts({required Object count}) => 'Collecting posts · ${count} read';
	String moreItems({required Object count}) => '${count} more';
	String showAll({required Object count}) => 'Show all ${count}';
	String get open => 'Open';
	String get showInFolder => 'Show in folder';
	String get openWork => 'Open work';
	String filesCount({required Object count}) => '${count} files';
	String get deleteItem => 'Delete records';
	String get expandItem => 'Show files';
	String get collapseItem => 'Hide files';
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
	String get saveFailed => 'Could not save proxy settings';
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
	String get showAi => 'Show AI-generated works';
	String get showAiHelp => 'This setting is saved to your pixiv account';
	String get showAiFailed => 'Could not change the setting';
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
	String get weekR18G => 'Weekly R-18G';
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
	String get bookmarks => 'Bookmark tag';
	String get contentType => 'Work type';
	String get ratio => 'Shape';
	String get size => 'Minimum size';
	String get tool => 'Tool';
	String get toolHint => 'e.g. Photoshop';
	String get previewNote => 'Popular preview shows one batch of up to 30 of the most bookmarked works. Type, shape, size and tool filters do not apply.';
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
	String get popularPreview => 'Popular preview';
}

// Path: search.target
class Translations$search$target$en_US {
	Translations$search$target$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get tags => 'Tags';
	String get exactTags => 'Exact tags';
	String get titleAndCaption => 'Title & caption';
	String get text => 'Body text';
	String get keyword => 'Keywords';
}

// Path: search.contentType
class Translations$search$contentType$en_US {
	Translations$search$contentType$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get any => 'Any';
	String get illust => 'Illustrations';
	String get manga => 'Manga';
	String get ugoira => 'Ugoira';
	String get illustAndUgoira => 'Illust & ugoira';
	String get all => 'Illust, manga & ugoira';
}

// Path: search.ratio
class Translations$search$ratio$en_US {
	Translations$search$ratio$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get any => 'Any';
	String get landscape => 'Landscape';
	String get portrait => 'Portrait';
	String get square => 'Square';
}

// Path: search.size
class Translations$search$size$en_US {
	Translations$search$size$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get any => 'Any';
	String minWidth({required Object px}) => 'Width ≥ ${px} px';
	String minHeight({required Object px}) => 'Height ≥ ${px} px';
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
	String get limitHint => 'A search covers at most one year; a longer range is cut to its last year.';
	String get pickerHelp => 'Select a range (up to 1 year)';
}

// Path: search.bookmarks
class Translations$search$bookmarks$en_US {
	Translations$search$bookmarks$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get any => 'Any';
	String tagged({required Object count}) => '${count} users tag';
}

// Path: search.direct
class Translations$search$direct$en_US {
	Translations$search$direct$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String illust({required Object id}) => 'Open illustration #${id}';
	String user({required Object id}) => 'Open user #${id}';
	String novel({required Object id}) => 'Open novel #${id}';
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
	String get comment => 'No comment';
	String get profile => 'No public profile details';
}

// Path: user.profile
class Translations$user$profile$en_US {
	Translations$user$profile$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get comment => 'Comment';
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

// Path: newest.empty
class Translations$newest$empty$en_US {
	Translations$newest$empty$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get following => 'Nothing new from the people you follow';
	String get privateFollows => 'Nothing new from your private follows';
	String get mypixiv => 'Nothing new from your My pixiv friends';
	String get everyone => 'No new works yet';
}

// Path: illust.contextMenu
class Translations$illust$contextMenu$en_US {
	Translations$illust$contextMenu$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get download => 'Download';
	String get downloadAll => 'Download all';
	String get copyImage => 'Copy image';
	String get copyLink => 'Copy work link';
	String get openOriginal => 'Open on Pixiv';
}

// Path: illust.imageLabels
class Translations$illust$imageLabels$en_US {
	Translations$illust$imageLabels$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get original => 'original image';
	String get large => 'large image';
	String get image => 'image';
}

// Path: illust.toast
class Translations$illust$toast$en_US {
	Translations$illust$toast$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String downloadAllQueued({required Object count}) => '${count} images added to the download queue';
	String downloadComplete({required Object name}) => 'Saved ${name}';
	String get downloadFailed => 'Download failed';
	String copying({required Object label}) => 'Copying ${label}';
	String copied({required Object label}) => 'Copied ${label}';
	String copiedValue({required Object label, required Object value}) => 'Copied ${label}: ${value}';
	String copyFailed({required Object label}) => 'Failed to copy ${label}';
	String get openFailed => 'Could not open this work on Pixiv';
	String get linkCopied => 'Link copied';
	String get linkCopyFailed => 'Could not copy the link';
	String get alreadyDownloading => 'This page is already in the download queue';
}

// Path: illust.tooltip
class Translations$illust$tooltip$en_US {
	Translations$illust$tooltip$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get play => 'Play animation';
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
	String showMore({required Object count}) => 'Show ${count} more';
	String get showLess => 'Show less';
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
	String get write => 'Write a comment';
	String get discardDraftTitle => 'Leave this comment?';
	String get discardDraftMessage => 'Your unsent comment will be lost.';
	String get continueEditing => 'Continue editing';
	String get discardDraft => 'Discard draft';
	String get reply => 'Reply';
	String replyingTo({required Object name}) => 'Replying to ${name}';
	String get loadReplies => 'Load replies';
	String get loadMoreReplies => 'Load more replies';
	String get repliesFailed => 'Failed to load replies';
	String get sendFailed => 'Failed to send comment';
	String get delete => 'Delete';
	String get deleteConfirm => 'Delete this comment?';
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
	String get continueReading => 'Continue reading';
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
	String get embeddedImageUnavailable => 'This image is unavailable';
	String get openEmbeddedWork => 'Open linked artwork';
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
	String get shortcutsHelp => 'Left/Right or A/D: previous/next chapter. Up/Down or W/S: scroll. Esc: clear the selection, then close.';
	String get volumeKeys => 'Use volume keys';
	String get volumeKeysHelp => 'Volume down reads forward; volume up reads back.';
	String get autoScroll => 'Auto scroll';
	String get startAutoScroll => 'Start auto scroll';
	String get pauseAutoScroll => 'Pause auto scroll';
	String get autoScrollSpeed => 'Scroll speed';
	String scrollSpeedValue({required Object speed}) => '${speed} px/s';
	String chapterPosition({required Object current, required Object total}) => 'Chapter ${current} of ${total}';
	String chapterNumber({required Object number}) => 'Chapter ${number}';
	String get previousChapter => 'Previous chapter';
	String get nextChapter => 'Next chapter';
	String progressValue({required Object percent}) => '${percent}%';
	String get markerSet => 'Bookmark this place';
	String get markerMenu => 'Reading bookmark';
	String markerJump({required Object page}) => 'Go to bookmark (section ${page})';
	String get markerUpdate => 'Move here';
	String get markerRemove => 'Remove bookmark';
	String get markerFailed => 'Could not change the bookmark';
}

// Path: illustDetail.ugoira
class Translations$illustDetail$ugoira$en_US {
	Translations$illustDetail$ugoira$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get metadata => 'Loading the animation';
	String get frames => 'Downloading frames';
	String get extracting => 'Extracting frames';
	String get preparing => 'Preparing playback';
	String get composing => 'Composing the GIF';
	String get saving => 'Saving the GIF';
}

/// The flat map containing all translations for locale <en-US>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'downloadEntry.retryFailed' => 'Retry failed',
			'downloadEntry.clearCompleted' => 'Clear completed',
			'downloadEntry.viewAll' => 'View all',
			'novelText.loadFailed' => 'The text couldn\'t load',
			'signOut.title' => 'Sign out of Pixiv?',
			'signOut.message' => 'You need to sign in again to browse. Downloads and settings stay on this device.',
			'signOut.confirm' => 'Sign out',
			'appSearch.placeholder' => 'Search illustrations, novels, users',
			'appSearch.allHistory' => 'All history',
			'appSearch.allTrendingTags' => 'All trending tags',
			'appSearch.searchIllust' => ({required Object query}) => 'Search illustrations & manga for “${query}”',
			'appSearch.searchNovel' => ({required Object query}) => 'Search novels for “${query}”',
			'appSearch.searchUser' => ({required Object query}) => 'Search users for “${query}”',
			'appSearch.openGroup' => 'Open',
			'appSearch.tagGroup' => 'Tags',
			'appSearch.noSuggestions' => 'No suggestions',
			'appSearch.suggestionsFailed' => 'Couldn\'t load suggestions',
			'frost.retry' => 'Retry',
			'frost.error' => 'Error',
			'frost.errorDetails' => 'Error details',
			'frost.copyDetails' => 'Copy details',
			'frost.copied' => 'Copied',
			'frost.loading' => 'Loading',
			'frost.actionSucceeded' => 'Action succeeded',
			'frost.actionFailed' => 'Action failed',
			'frost.loadFailed' => 'Couldn\'t load',
			'frost.noItems' => 'No items',
			'frost.noMoreItems' => 'No more items',
			'frost.pullToRefresh' => 'Pull to refresh',
			'frost.releaseToRefresh' => 'Release to refresh',
			'frost.refreshing' => 'Refreshing',
			'frost.refreshComplete' => 'Refresh complete',
			'frost.refreshFailed' => 'Refresh failed',
			'frost.previous' => 'Previous',
			'frost.next' => 'Next',
			'frost.back' => 'Back',
			'frost.more' => 'More',
			'frost.expandNavigation' => 'Expand sidebar',
			'frost.collapseNavigation' => 'Collapse sidebar',
			'frost.clearText' => 'Clear text',
			'frost.search' => 'Search',
			'frost.noResults' => ({required Object query}) => 'No results for “${query}”',
			'frost.clearSearch' => 'Clear search',
			'frost.dismiss' => 'Dismiss',
			'frost.expandText' => 'Show more',
			'frost.collapseText' => 'Show less',
			'frost.showAll' => 'Show all',
			'frost.copy' => 'Copy',
			'frost.clearAll' => 'Clear all',
			'frost.showPassword' => 'Show password',
			'frost.hidePassword' => 'Hide password',
			'frost.chooseDate' => 'Choose date',
			'frost.chooseTime' => 'Choose time',
			'frost.increment' => 'Increase',
			'frost.decrement' => 'Decrease',
			'frost.reorderHandle' => 'Reorder',
			'frost.sortAscending' => 'Ascending',
			'frost.sortDescending' => 'Descending',
			'frost.play' => 'Play',
			'frost.pause' => 'Pause',
			'frost.loop' => 'Loop',
			'frost.mute' => 'Mute',
			'frost.unmute' => 'Unmute',
			'frost.fullscreen' => 'Full screen',
			'frost.exitFullscreen' => 'Exit full screen',
			'frost.minimize' => 'Minimize',
			'frost.maximize' => 'Maximize',
			'frost.restore' => 'Restore',
			'frost.close' => 'Close',
			'frost.cancel' => 'Cancel',
			'frost.apply' => 'Apply',
			'frost.clear' => 'Clear',
			'frost.choose' => 'Choose',
			'frost.showInFolder' => 'Show in folder',
			'frost.selectedCount' => ({required Object count}) => '${count} selected',
			'frost.pageOf' => ({required Object page, required Object total}) => 'Page ${page} of ${total}',
			'frost.selectAll' => 'Select all',
			'frost.done' => 'Done',
			'frost.itemPosition' => ({required Object position, required Object total}) => '${position} of ${total}',
			'frost.tableDimensions' => ({required Object rows, required Object columns}) => '${rows} rows, ${columns} columns',
			'frost.taskQueued' => 'Queued',
			'frost.taskRunning' => 'Downloading',
			'frost.taskPaused' => 'Paused',
			'frost.taskCompleted' => 'Completed',
			'frost.taskFailed' => 'Failed',
			'frost.taskCancelled' => 'Cancelled',
			'frost.remove' => 'Remove',
			'frost.seek' => 'Playback position',
			'frost.showReplies' => ({required Object count}) => 'Show ${count} replies',
			'frost.moreMedia' => ({required Object count}) => '${count} more images',
			'frost.navigationCount' => ({required Object count}) => '${count} items',
			'frost.navigationProgress' => ({required Object progress}) => '${progress}% complete',
			'frost.listSeparator' => ', ',
			'frost.retryAfter' => ({required Object seconds}) => 'Retry in ${seconds} s',
			'nativeWindow.minimize' => 'Minimize',
			'nativeWindow.maximize' => 'Maximize',
			'nativeWindow.restore' => 'Restore',
			'nativeWindow.close' => 'Close',
			'nativeWindow.illust' => 'Illust',
			'nativeWindow.manga' => 'Manga',
			'nativeWindow.novel' => 'Novel',
			'nativeWindow.workFallback' => ({required Object type, required Object id}) => '${type}: ${id}',
			'nativeWindow.workTitle' => ({required Object type, required Object id, required Object title}) => '${type}: ${id} · ${title}',
			'nativeWindow.relatedTitle' => ({required Object title}) => 'Related works · ${title}',
			'nativeWindow.user' => 'User',
			'nativeWindow.userFallback' => ({required Object id}) => 'User: ${id}',
			'nativeWindow.viewerTitle' => ({required Object title, required Object page, required Object total}) => '${title} · ${page}/${total}',
			'discover.searchHint' => 'Search Pixiv',
			'discover.history' => 'Recent searches',
			'discover.viewAll' => 'View all',
			'discover.clearHistory' => 'Clear history',
			'discover.deleteHistoryItem' => 'Remove recent search',
			'discover.emptyHistory' => 'Your searches will appear here',
			'app.title' => 'freepiv',
			'navigation.backToFirst' => 'Back to first page',
			'navigation.activity' => 'Activity',
			'navigation.home' => 'Home',
			'navigation.search' => 'Search',
			'navigation.newest' => 'Newest',
			'navigation.ranking' => 'Ranking',
			'navigation.me' => 'Me',
			'navigation.settings' => 'Settings',
			'navigation.more' => 'More',
			'navigation.expand' => 'Expand navigation',
			'navigation.collapse' => 'Collapse navigation',
			'navigation.downloads' => 'Downloads',
			'navigation.about' => 'About',
			'errors.generic' => 'Unable to load content. Please try again.',
			'errors.connection' => 'Check your connection and try again.',
			'errors.session' => 'Your session has expired. Please sign in again.',
			'errors.forbidden' => 'You do not have access to this content.',
			'errors.missing' => 'This content is no longer available.',
			'common.viewLog' => 'View log',
			'common.apply' => 'Apply',
			'common.reset' => 'Reset',
			'common.discover' => 'Discover',
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
			'common.errorDetails' => 'Error details',
			'common.copyDetails' => 'Copy details',
			'common.detailsCopied' => 'Error details copied',
			'common.refresh' => 'Refresh',
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
			'login.openingBrowser' => 'Opening browser',
			'login.apiNotInitialized' => 'Pixiv API is not initialized.',
			'login.desktopOnly' => 'System browser sign-in currently supports only Linux, macOS, and Windows.',
			'login.openedInBrowser' => 'Pixiv sign-in opened in the system browser. Return to the app after signing in.',
			'login.callbackMissingCode' => ({required Object uri}) => 'Pixiv callback is missing code: ${uri}',
			'login.callbackReceived' => 'Pixiv callback received. Fetching token.',
			'login.browserOpenUnsupported' => 'System browser opening is not implemented here.',
			'login.browserOpenFailed' => ({required Object browser, required Object output}) => '${browser} failed to open the sign-in link: ${output}',
			'login.proxyHint' => 'If you use a network proxy, set the proxy address here before signing in.',
			'settings.theme.title' => 'Appearance',
			'settings.theme.displayMode' => 'Display mode',
			'settings.theme.tone' => 'Tone',
			'settings.theme.neutral' => 'Neutral',
			'settings.theme.cool' => 'Cool',
			'settings.theme.warm' => 'Warm',
			'settings.theme.systemNeutralHint' => 'System mode uses a neutral tone',
			'settings.theme.lightAccent' => 'Light accent',
			'settings.theme.darkAccent' => 'Dark accent',
			'settings.theme.systemEditingLight' => 'Currently editing the light accent used by the system',
			'settings.theme.systemEditingDark' => 'Currently editing the dark accent used by the system',
			'settings.theme.presetPink' => 'Default pink',
			'settings.theme.presetBlue' => 'Blue',
			'settings.theme.presetTeal' => 'Teal',
			'settings.theme.presetViolet' => 'Violet',
			'settings.theme.presetAmber' => 'Amber',
			'settings.theme.presetOrange' => 'Orange',
			'settings.theme.custom' => 'Custom',
			'settings.theme.defaultAccent' => 'Default pink',
			'settings.theme.restoreDefault' => 'Restore default pink',
			'settings.theme.editLightAccent' => 'Custom light accent',
			'settings.theme.editDarkAccent' => 'Custom dark accent',
			'settings.theme.hue' => 'Hue',
			'settings.theme.saturation' => 'Saturation',
			'settings.theme.value' => 'Brightness',
			'settings.theme.hex' => 'HEX color',
			'settings.theme.invalidHex' => 'Enter a six-digit HEX color',
			'settings.theme.preview' => 'Preview',
			'settings.theme.previewButton' => 'Button',
			'settings.theme.rejectedLight' => 'This color is too close to light backgrounds. Choose another color.',
			'settings.theme.rejectedDark' => 'This color is too close to dark backgrounds. Choose another color.',
			'settings.theme.weakContrast' => 'This color may be difficult to distinguish on some backgrounds.',
			'settings.theme.applyAnyway' => 'Apply anyway',
			'settings.theme.useDefault' => 'Use default pink',
			'settings.theme.saving' => 'Saving',
			'settings.theme.saveFailed' => 'Could not save appearance. Try again.',
			'settings.theme.unsaved' => 'Appearance changes are not saved yet.',
			'settings.theme.system' => 'System',
			'settings.theme.light' => 'Light',
			'settings.theme.dark' => 'Dark',
			'settings.theme.background' => 'Background',
			'settings.theme.ambientBlur' => 'Blur',
			'settings.theme.mica' => 'Mica',
			'settings.theme.backgroundOff' => 'Off',
			'settings.theme.backgroundIntensity' => 'Intensity',
			'settings.theme.systemTransparencyReduced' => 'System transparency is reduced',
			'settings.language.title' => 'Language',
			'settings.language.systemDefault' => 'System default',
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
			'settings.downloads.retryFailed' => 'Retry all failed tasks',
			'settings.downloads.clearCompleted' => 'Clear completed tasks',
			'settings.downloads.syncFailed' => 'Download sync failed',
			'settings.downloads.actionFailed' => 'Download action failed',
			'settings.downloads.collapse' => 'Collapse',
			'settings.downloads.viewAll' => 'View all downloads',
			'settings.downloads.badgeFailures' => ({required Object count}) => 'Failed downloads: ${count}',
			'settings.downloads.badgeActive' => ({required Object count}) => 'Active downloads: ${count}',
			'settings.downloads.filesProgress' => ({required Object done, required Object total}) => '${done} / ${total} files',
			'settings.downloads.filesFailed' => ({required Object count}) => '${count} failed',
			'settings.downloads.collectingPosts' => ({required Object count}) => 'Collecting posts · ${count} read',
			'settings.downloads.moreItems' => ({required Object count}) => '${count} more',
			'settings.downloads.showAll' => ({required Object count}) => 'Show all ${count}',
			'settings.downloads.open' => 'Open',
			'settings.downloads.showInFolder' => 'Show in folder',
			'settings.downloads.openWork' => 'Open work',
			'settings.downloads.filesCount' => ({required Object count}) => '${count} files',
			'settings.downloads.deleteItem' => 'Delete records',
			'settings.downloads.expandItem' => 'Show files',
			'settings.downloads.collapseItem' => 'Hide files',
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
			'settings.proxy.saveFailed' => 'Could not save proxy settings',
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
			'settings.account.showAi' => 'Show AI-generated works',
			'settings.account.showAiHelp' => 'This setting is saved to your pixiv account',
			'settings.account.showAiFailed' => 'Could not change the setting',
			'me.profile' => 'My profile',
			'me.openProfile' => 'Open profile',
			'me.following' => 'My following',
			'me.followers' => 'My followers',
			'me.mypixiv' => 'My pixiv',
			'me.emptyFollowing' => 'No following users',
			'me.emptyFollowers' => 'No followers',
			'me.emptyMypixiv' => 'No My pixiv friends',
			'me.about' => 'About',
			'me.settings' => 'Settings',
			'me.watchlist' => 'Follow-ups',
			'me.editProfile' => 'Edit profile',
			'me.workspace' => 'Workspace',
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
			'about.checkingUpdate' => 'Checking for updates',
			'about.noUpdate' => 'You are on the latest version',
			'about.updateAvailable' => ({required Object version, required Object buildNumber}) => 'New version available: ${version}+${buildNumber}',
			'about.checkUpdateFailed' => 'Failed to check for updates',
			'about.downloadPage' => 'Download page',
			'about.downloadAssetUnavailable' => 'No download asset matched this platform. Opening the release page.',
			'about.openDownloadFailed' => 'Failed to open the download page',
			'about.openLinkFailed' => 'Failed to open link',
			'about.latestValue' => ({required Object version, required Object buildNumber}) => 'Latest: ${version}+${buildNumber}',
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
			'ranking.modes.weekR18G' => 'Weekly R-18G',
			'ranking.modes.weekOriginal' => 'Weekly Original',
			'ranking.modes.weekRookie' => 'Weekly Rookie',
			'ranking.modes.month' => 'Monthly',
			'ranking.r18Section' => 'R-18',
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
			'search.filters.bookmarks' => 'Bookmark tag',
			'search.filters.contentType' => 'Work type',
			'search.filters.ratio' => 'Shape',
			'search.filters.size' => 'Minimum size',
			'search.filters.tool' => 'Tool',
			'search.filters.toolHint' => 'e.g. Photoshop',
			'search.filters.previewNote' => 'Popular preview shows one batch of up to 30 of the most bookmarked works. Type, shape, size and tool filters do not apply.',
			'search.type.illustManga' => 'Illust & Manga',
			'search.type.novel' => 'Novel',
			'search.type.user' => 'User',
			'search.sort.newest' => 'Newest',
			'search.sort.oldest' => 'Oldest',
			'search.sort.popularPreview' => 'Popular preview',
			'search.target.tags' => 'Tags',
			'search.target.exactTags' => 'Exact tags',
			'search.target.titleAndCaption' => 'Title & caption',
			'search.target.text' => 'Body text',
			'search.target.keyword' => 'Keywords',
			'search.contentType.any' => 'Any',
			'search.contentType.illust' => 'Illustrations',
			'search.contentType.manga' => 'Manga',
			'search.contentType.ugoira' => 'Ugoira',
			'search.contentType.illustAndUgoira' => 'Illust & ugoira',
			'search.contentType.all' => 'Illust, manga & ugoira',
			'search.ratio.any' => 'Any',
			'search.ratio.landscape' => 'Landscape',
			'search.ratio.portrait' => 'Portrait',
			'search.ratio.square' => 'Square',
			'search.size.any' => 'Any',
			'search.size.minWidth' => ({required Object px}) => 'Width ≥ ${px} px',
			'search.size.minHeight' => ({required Object px}) => 'Height ≥ ${px} px',
			'search.date.any' => 'Any date',
			'search.date.today' => 'Today',
			'search.date.days7' => '7 days',
			'search.date.month1' => '1 month',
			'search.date.months6' => '6 months',
			'search.date.year1' => '1 year',
			'search.date.custom' => 'Custom',
			'search.date.limitHint' => 'A search covers at most one year; a longer range is cut to its last year.',
			'search.date.pickerHelp' => 'Select a range (up to 1 year)',
			'search.bookmarks.any' => 'Any',
			'search.bookmarks.tagged' => ({required Object count}) => '${count} users tag',
			'search.direct.illust' => ({required Object id}) => 'Open illustration #${id}',
			'search.direct.user' => ({required Object id}) => 'Open user #${id}',
			'search.direct.novel' => ({required Object id}) => 'Open novel #${id}',
			'search.empty.illustrations' => 'No illustrations found',
			'search.empty.novels' => 'No novels found',
			'search.empty.users' => 'No users found',
			'user.noPublicWorks' => 'No public works',
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
			'user.empty.comment' => 'No comment',
			'user.empty.profile' => 'No public profile details',
			'user.profile.comment' => 'Comment',
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
			'newest.empty.following' => 'Nothing new from the people you follow',
			'newest.empty.privateFollows' => 'Nothing new from your private follows',
			'newest.empty.mypixiv' => 'Nothing new from your My pixiv friends',
			'newest.empty.everyone' => 'No new works yet',
			_ => null,
		} ?? switch (path) {
			'illust.pageJump' => 'Go to page',
			'illust.contextMenu.download' => 'Download',
			'illust.contextMenu.downloadAll' => 'Download all',
			'illust.contextMenu.copyImage' => 'Copy image',
			'illust.contextMenu.copyLink' => 'Copy work link',
			'illust.contextMenu.openOriginal' => 'Open on Pixiv',
			'illust.imageLabels.original' => 'original image',
			'illust.imageLabels.large' => 'large image',
			'illust.imageLabels.image' => 'image',
			'illust.toast.downloadAllQueued' => ({required Object count}) => '${count} images added to the download queue',
			'illust.toast.downloadComplete' => ({required Object name}) => 'Saved ${name}',
			'illust.toast.downloadFailed' => 'Download failed',
			'illust.toast.copying' => ({required Object label}) => 'Copying ${label}',
			'illust.toast.copied' => ({required Object label}) => 'Copied ${label}',
			'illust.toast.copiedValue' => ({required Object label, required Object value}) => 'Copied ${label}: ${value}',
			'illust.toast.copyFailed' => ({required Object label}) => 'Failed to copy ${label}',
			'illust.toast.openFailed' => 'Could not open this work on Pixiv',
			'illust.toast.linkCopied' => 'Link copied',
			'illust.toast.linkCopyFailed' => 'Could not copy the link',
			'illust.toast.alreadyDownloading' => 'This page is already in the download queue',
			'illust.tooltip.play' => 'Play animation',
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
			'illust.tags.showMore' => ({required Object count}) => 'Show ${count} more',
			'illust.tags.showLess' => 'Show less',
			'illust.comments.failed' => 'Failed to load comments',
			'illust.comments.empty' => 'No comments yet',
			'illust.comments.moreAvailable' => 'More comments available',
			'illust.comments.hasReplies' => 'Has replies',
			'illust.comments.open' => 'Open comments',
			'illust.comments.write' => 'Write a comment',
			'illust.comments.discardDraftTitle' => 'Leave this comment?',
			'illust.comments.discardDraftMessage' => 'Your unsent comment will be lost.',
			'illust.comments.continueEditing' => 'Continue editing',
			'illust.comments.discardDraft' => 'Discard draft',
			'illust.comments.reply' => 'Reply',
			'illust.comments.replyingTo' => ({required Object name}) => 'Replying to ${name}',
			'illust.comments.loadReplies' => 'Load replies',
			'illust.comments.loadMoreReplies' => 'Load more replies',
			'illust.comments.repliesFailed' => 'Failed to load replies',
			'illust.comments.sendFailed' => 'Failed to send comment',
			'illust.comments.delete' => 'Delete',
			'illust.comments.deleteConfirm' => 'Delete this comment?',
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
			'novel.detail.continueReading' => 'Continue reading',
			'novel.detail.totalChars' => ({required Object count}) => '${count} chars',
			'novel.detail.paragraphCount' => ({required Object count}) => '${count} paragraphs',
			'novel.detail.segmentCount' => ({required Object count}) => '${count} pages',
			'novel.reader.title' => 'Reading',
			'novel.reader.body' => 'Body',
			'novel.reader.chapters' => 'Chapters',
			'novel.reader.settings' => 'Reading settings',
			'novel.reader.emptyBody' => 'No body text',
			'novel.reader.embeddedImageUnavailable' => 'This image is unavailable',
			'novel.reader.openEmbeddedWork' => 'Open linked artwork',
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
			'novel.reader.shortcutsHelp' => 'Left/Right or A/D: previous/next chapter. Up/Down or W/S: scroll. Esc: clear the selection, then close.',
			'novel.reader.volumeKeys' => 'Use volume keys',
			'novel.reader.volumeKeysHelp' => 'Volume down reads forward; volume up reads back.',
			'novel.reader.autoScroll' => 'Auto scroll',
			'novel.reader.startAutoScroll' => 'Start auto scroll',
			'novel.reader.pauseAutoScroll' => 'Pause auto scroll',
			'novel.reader.autoScrollSpeed' => 'Scroll speed',
			'novel.reader.scrollSpeedValue' => ({required Object speed}) => '${speed} px/s',
			'novel.reader.chapterPosition' => ({required Object current, required Object total}) => 'Chapter ${current} of ${total}',
			'novel.reader.chapterNumber' => ({required Object number}) => 'Chapter ${number}',
			'novel.reader.previousChapter' => 'Previous chapter',
			'novel.reader.nextChapter' => 'Next chapter',
			'novel.reader.progressValue' => ({required Object percent}) => '${percent}%',
			'novel.reader.markerSet' => 'Bookmark this place',
			'novel.reader.markerMenu' => 'Reading bookmark',
			'novel.reader.markerJump' => ({required Object page}) => 'Go to bookmark (section ${page})',
			'novel.reader.markerUpdate' => 'Move here',
			'novel.reader.markerRemove' => 'Remove bookmark',
			'novel.reader.markerFailed' => 'Could not change the bookmark',
			'follow.tooltipFollow' => 'Follow user',
			'follow.tooltipUnfollow' => 'Unfollow',
			'follow.followed' => 'Following',
			'follow.follow' => 'Follow',
			'follow.restrictTitle' => 'Follow as',
			'richText.twitterUser' => ({required Object username}) => 'Twitter: ${username}',
			'richText.illustId' => ({required Object id}) => 'Illust ID: ${id}',
			'richText.userId' => ({required Object id}) => 'User ID: ${id}',
			'fanbox.accountConnected' => 'Connected',
			'fanbox.updateSession' => 'Update Cookie',
			'fanbox.title' => 'FANBOX',
			'fanbox.home' => 'Following feed',
			'fanbox.feedGroup' => 'Feed',
			'fanbox.supporting' => 'Supporting feed',
			'fanbox.following' => 'Following',
			'fanbox.recommended' => 'Discover',
			'fanbox.pixiv' => 'From Pixiv',
			'fanbox.plans' => 'Supported plans',
			'fanbox.searchCreators' => 'Creators',
			'fanbox.searchTags' => 'Tags',
			'fanbox.notices' => 'Notifications',
			'fanbox.messages' => 'Messages',
			'fanbox.bookmarks' => 'Saved posts',
			'fanbox.login' => 'Sign in to FANBOX',
			'fanbox.cookieHint' => 'Paste FANBOXSESSID or FANBOXSESSID=value',
			'fanbox.importSession' => 'Import session file',
			'fanbox.openWebsite' => 'Open FANBOX website',
			'fanbox.loginHelp' => 'Log in in your browser, then copy FANBOXSESSID from Developer Tools → Application → Cookies. Your Pixiv login is separate.',
			'fanbox.logout' => 'Sign out',
			'fanbox.empty' => 'No items yet',
			'fanbox.loadMore' => 'Load more',
			'fanbox.searchHint' => 'Creator name, ID or tag',
			'fanbox.creatorId' => 'Open creator by ID',
			'fanbox.posts' => 'Posts',
			'fanbox.creatorPlans' => 'Creator plans',
			'fanbox.restricted' => ({required Object fee}) => 'Support at least ¥${fee}/month to read',
			'fanbox.free' => 'Public',
			'fanbox.readable' => 'Available to you',
			'fanbox.viewPlans' => 'View support plans',
			'fanbox.monthlyFee' => ({required Object fee}) => '¥${fee}/month',
			'fanbox.supportOnWebsite' => 'View plan on FANBOX',
			'fanbox.follow' => 'Follow',
			'fanbox.unfollow' => 'Unfollow',
			'fanbox.like' => 'Like',
			'fanbox.liked' => 'Liked',
			'fanbox.comments' => 'Comments',
			'fanbox.reply' => 'Reply',
			'fanbox.commentHint' => 'Write a comment',
			'fanbox.deleteComment' => 'Delete comment',
			'fanbox.deleteConfirm' => 'Delete this comment?',
			'fanbox.send' => 'Send',
			'fanbox.save' => 'Save post',
			'fanbox.saved' => 'Saved',
			'fanbox.download' => 'Download',
			'fanbox.downloadAll' => 'Download all media',
			'fanbox.downloadCreator' => 'Download creator posts',
			'fanbox.fanCard' => 'Fan card',
			'fanbox.previous' => 'Previous post',
			'fanbox.next' => 'Next post',
			'fanbox.unknown' => 'This content format is not supported yet. Open the original post to view it.',
			'fanbox.openOriginal' => 'Open original',
			'fanbox.openLink' => 'Open link',
			'fanbox.sessionExpired' => 'Your FANBOX session is invalid or expired. Please sign in again.',
			'fanbox.requestFailed' => 'Unable to load FANBOX. Check your connection or retry.',
			'fanbox.accessDenied' => 'FANBOX denied this request. Check your access or open the website.',
			'fanbox.rateLimited' => 'Too many requests. Please try again later.',
			'fanbox.loginFailed' => 'Could not validate the session. Check the Cookie and proxy settings.',
			'fanbox.working' => 'Working',
			'fanbox.cancel' => 'Cancel',
			'fanbox.retry' => 'Retry',
			'fanbox.done' => 'Done',
			'fanbox.newNotice' => 'Unread',
			'fanbox.unknownNotice' => 'FANBOX activity',
			'fanbox.chooseFolder' => 'Choose download folder',
			'fanbox.unsupportedUrl' => 'This link cannot be opened.',
			'fanbox.restrictedInfo' => 'This post remains visible, but its content requires a qualifying support plan.',
			'fanbox.noPlans' => 'No available plans',
			'fanbox.downloadPreparing' => 'Collecting accessible posts',
			'fanbox.downloadQueued' => ({required Object count}) => '${count} files added to the download queue',
			'fanbox.downloadNothingNew' => 'Everything here is already in the download queue',
			'fanbox.browserLogin' => 'Log in with browser',
			'fanbox.manualLogin' => 'Enter Cookie manually',
			'fanbox.browserHelp' => 'Complete sign-in on the official website. This window closes after your session is verified.',
			'fanbox.browserCheck' => 'I am signed in',
			'fanbox.browserCheckFailed' => 'Verification failed. Choose “I am signed in” to retry.',
			'fanbox.browserUnavailable' => 'Could not open or read the login page. Retry or enter a Cookie manually.',
			'fanbox.browserProxyUnsupported' => 'This browser cannot use the configured proxy. Use a supported HTTP/SOCKS5 proxy, a system proxy, or enter a Cookie manually.',
			'fanbox.browserCleanupFailed' => 'Signed out, but browser data could not be cleared. Cleanup will be retried before the next browser login.',
			'fanbox.browserTimedOut' => 'Login timed out. Close this window and start again.',
			'fanbox.browserBusy' => 'Another login window is still closing. Please try again shortly.',
			'fanbox.runtimeTitle' => 'Install login component',
			'fanbox.runtimeMissing' => 'WebView2 Runtime is missing or unavailable. Install it, then check again.',
			'fanbox.runtimeInstall' => 'Get WebView2 from Microsoft',
			'fanbox.runtimeHelp' => 'Choose Evergreen Runtime on the Microsoft website. If the online installer fails, use the standalone installer. Other app features remain available.',
			'fanbox.runtimeRecheck' => 'Check again',
			'pixivision.title' => 'pixivision',
			'pixivision.searchHint' => 'Search articles',
			'pixivision.latest' => 'Latest',
			'pixivision.ranking' => 'Monthly ranking',
			'pixivision.recommended' => 'Recommended',
			'pixivision.tags' => 'Tags',
			'pixivision.allCategories' => 'All categories',
			'pixivision.empty' => 'No articles found',
			'pixivision.requestFailed' => 'Could not load content. Please retry.',
			'pixivision.loadMore' => 'Load more',
			'pixivision.openOriginal' => 'Open original',
			'pixivision.openFailed' => 'Could not open the link',
			'pixivision.translations' => 'Languages',
			'pixivision.previous' => 'Previous',
			'pixivision.next' => 'Next',
			'pixivision.unsupported' => 'This content can be viewed on the original page.',
			'pixivision.userId' => ({required Object id}) => 'User ID: ${id}',
			'pixivision.userName' => ({required Object name}) => 'User: ${name}',
			'artworkCard.ai' => 'AI',
			'artworkCard.ugoira' => 'Animation',
			'artworkCard.semantics' => ({required Object title, required Object author}) => '${title} by ${author}',
			'artworkCard.menuHeader' => ({required Object title, required Object author}) => '${title} · ${author}',
			'artworkCard.openAuthor' => 'Open author',
			'illustDetail.downloadGif' => 'Download GIF',
			'illustDetail.copyGif' => 'Copy GIF',
			'illustDetail.pause' => 'Pause',
			'illustDetail.ugoira.metadata' => 'Loading the animation',
			'illustDetail.ugoira.frames' => 'Downloading frames',
			'illustDetail.ugoira.extracting' => 'Extracting frames',
			'illustDetail.ugoira.preparing' => 'Preparing playback',
			'illustDetail.ugoira.composing' => 'Composing the GIF',
			'illustDetail.ugoira.saving' => 'Saving the GIF',
			'illustDetail.bookmarkCount' => ({required Object count}) => 'Bookmark ${count}',
			'illustDetail.copyId' => 'Copy ID',
			'illustDetail.views' => ({required Object count}) => '${count} views',
			'illustDetail.pages' => ({required Object count}) => '${count} pages',
			'illustDetail.copyTag' => 'Copy tag',
			'illustDetail.allComments' => ({required Object count}) => 'View all ${count} comments',
			'illustDetail.moreRelated' => 'View more',
			'illustDetail.missing' => 'This work does not exist or is not visible to you',
			'viewer.position' => ({required Object title, required Object page, required Object total}) => '${title} · ${page} / ${total}',
			'viewer.loading' => 'Loading the original image',
			'userPage.copyLink' => 'Copy profile link',
			'userPage.linkCopied' => 'Link copied',
			'userPage.openInBrowser' => 'Open in browser',
			'userPage.copyBio' => 'Copy bio',
			'userPage.bioCopied' => 'Bio copied',
			'userPage.copyFailed' => 'Could not copy',
			'userPage.openFailed' => 'Could not open the link',
			'novelDetail.missing' => 'This novel does not exist or is not visible to you',
			'novelDetail.bookmark' => 'Bookmark',
			'novelDetail.bookmarked' => 'Bookmarked',
			'novelDetail.bookmarks' => ({required Object count}) => '${count} bookmarks',
			'novelDetail.related' => 'Related novels',
			'novelDetail.noRelated' => 'No related novels',
			'novelDetail.authorNovels' => 'More by the author',
			'commentsPage.empty' => 'No comments yet. Write the first one',
			'searchPage.minWidth' => 'Minimum width',
			'searchPage.minHeight' => 'Minimum height',
			'searchPage.clearFilters' => 'Clear filters',
			'searchPage.noUserFilters' => 'User search has no filters',
			'downloadsPage.all' => 'All',
			'downloadsPage.inProgress' => 'In progress',
			'downloadsPage.nothingInProgress' => 'No downloads in progress',
			'downloadsPage.nothingDone' => 'Nothing downloaded yet',
			'downloadsPage.failedGroup' => ({required Object count}) => '${count} failed',
			'loginPage.intro' => 'Sign in with your Pixiv account in the browser, then come back here',
			'loginPage.signIn' => 'Sign in in the browser',
			'loginPage.waiting' => 'Finish signing in in the browser',
			'loginPage.reopen' => 'Open the browser again',
			'fanboxPage.groupFeed' => 'Feed',
			'fanboxPage.groupDiscover' => 'Discover',
			'fanboxPage.groupMine' => 'Mine',
			'fanboxPage.searchPlaceholder' => 'Search FANBOX',
			'fanboxPage.openCreator' => ({required Object id}) => 'Open creator @${id}',
			'fanboxPage.searchCreators' => ({required Object query}) => 'Search creators for “${query}”',
			'fanboxPage.searchTags' => ({required Object query}) => 'Search tags for “${query}”',
			'fanboxPage.accountSettings' => 'FANBOX account settings',
			'fanboxPage.localOnly' => 'Saved posts stay on this device only',
			'fanboxPage.creatorPage' => 'Open creator',
			'fanboxPage.noComments' => 'No comments yet',
			'fanboxPage.collecting' => 'Collecting posts',
			'discoverPage.noArticles' => 'No articles right now',
			'privacy.label' => 'Visibility',
			'privacy.public' => 'Public',
			'privacy.private' => 'Private',
			'bookmarkOptions.title' => 'Bookmark options',
			'bookmarkOptions.tags' => 'Tags',
			'bookmarkOptions.addTag' => 'Add a tag and press Enter',
			'bookmarkOptions.noTags' => 'No tags to choose from yet',
			'bookmarkOptions.remove' => 'Remove bookmark',
			'bookmarkOptions.save' => 'Save',
			'bookmarkOptions.failed' => 'Could not save the bookmark',
			'bookmarkOptions.loadFailed' => 'Could not load the bookmark',
			'series.title' => 'Series',
			'series.link' => ({required Object title}) => 'Series · ${title}',
			'series.episodes' => ({required Object count}) => '${count} episodes',
			'series.concluded' => 'Completed',
			'series.ongoing' => 'Ongoing',
			'series.watch' => 'Follow up',
			'series.watching' => 'Following up',
			'series.watchFailed' => 'Could not change the follow-up',
			'series.startFromFirst' => 'Start from episode 1',
			'series.empty' => 'This series has no works yet',
			'watchlist.title' => 'Follow-ups',
			'watchlist.manga' => 'Manga',
			'watchlist.novels' => 'Novels',
			'watchlist.emptyManga' => 'No manga series followed up yet',
			'watchlist.emptyNovels' => 'No novel series followed up yet',
			'watchlist.unavailable' => 'This series cannot be shown',
			'watchlist.updated' => ({required Object date}) => 'Updated ${date}',
			'profileEdit.title' => 'Edit profile',
			'profileEdit.name' => 'Nickname',
			'profileEdit.nameRequired' => 'Enter a nickname',
			'profileEdit.gender' => 'Gender',
			'profileEdit.genderUnknown' => 'Not specified',
			'profileEdit.genderMale' => 'Male',
			'profileEdit.genderFemale' => 'Female',
			'profileEdit.birthday' => 'Birthday',
			'profileEdit.notSet' => 'Not set',
			'profileEdit.region' => 'Region',
			'profileEdit.country' => 'Country',
			'profileEdit.job' => 'Occupation',
			'profileEdit.website' => 'Website',
			'profileEdit.twitter' => 'Twitter',
			'profileEdit.bio' => 'Bio',
			'profileEdit.save' => 'Save',
			'profileEdit.saved' => 'Saved',
			'profileEdit.failed' => 'Could not save',
			'profileEdit.discardTitle' => 'Discard your changes?',
			'profileEdit.discardMessage' => 'Your changes have not been saved.',
			'profileEdit.discard' => 'Discard',
			'profileEdit.keepEditing' => 'Keep editing',
			'workspaceEdit.title' => 'Workspace',
			'workspaceEdit.pc' => 'Computer',
			'workspaceEdit.monitor' => 'Monitor',
			'workspaceEdit.tool' => 'Software',
			'workspaceEdit.scanner' => 'Scanner',
			'workspaceEdit.tablet' => 'Tablet',
			'workspaceEdit.mouse' => 'Mouse',
			'workspaceEdit.printer' => 'Printer',
			'workspaceEdit.desktop' => 'On the desk',
			'workspaceEdit.music' => 'Music',
			'workspaceEdit.desk' => 'Desk',
			'workspaceEdit.chair' => 'Chair',
			'workspaceEdit.comment' => 'Other',
			_ => null,
		};
	}
}
