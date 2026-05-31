// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get navPlaylists => 'Your playlists';

  @override
  String get navImport => 'Import';

  @override
  String get navSettings => 'Settings';

  @override
  String get playlistsHeader => 'PLAYLISTS';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get quickSearch => 'Search music';

  @override
  String get quickDownloads => 'Your downloads';

  @override
  String get quickImport => 'Import';

  @override
  String get favorites => 'Favorites';

  @override
  String get playlistGeneral => 'General';

  @override
  String get recentlyPlayed => 'Recently played';

  @override
  String get yourPlaylists => 'Your playlists';

  @override
  String get emptyHomeTitle => 'You don\'t have music yet';

  @override
  String get emptyHomeSubtitle => 'Search and download songs to listen offline';

  @override
  String songsCount(int count) {
    return '$count songs';
  }

  @override
  String get searchHint => 'What do you want to listen to?';

  @override
  String get searchButton => 'Search';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get inDownloadsHint =>
      'In your downloads · tap \"Search\" to search YouTube';

  @override
  String get noLocalMatches =>
      'No matches in your downloads. Tap \"Search\" to search YouTube.';

  @override
  String get searchInitialHint =>
      'Type to filter your downloads, or tap \"Search\" for YouTube';

  @override
  String get download => 'Download';

  @override
  String get moreOptions => 'More options';

  @override
  String get playNext => 'Play next';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get remove => 'Remove';

  @override
  String get removeFromPlaylist => 'Remove from playlist';

  @override
  String get play => 'Play';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get select => 'Select';

  @override
  String get selectAll => 'Select all';

  @override
  String get selectNone => 'None';

  @override
  String get deselect => 'Deselect';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String deleteCount(int count) {
    return 'Delete ($count)';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get sortBy => 'Sort:';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortDate => 'Date';

  @override
  String get downloads => 'Downloads';

  @override
  String get noDownloads => 'You don\'t have downloads yet';

  @override
  String get deleteDownloadsTitle => 'Delete downloads';

  @override
  String deleteDownloadsBody(int count) {
    return 'Delete $count downloaded song(s)?';
  }

  @override
  String get deleteDownloadTitle => 'Delete download';

  @override
  String deleteDownloadBody(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get newButton => 'New';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get playlistNameHint => 'Name';

  @override
  String get create => 'Create';

  @override
  String get options => 'Options';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String deletePlaylistBody(String name) {
    return 'Delete \"$name\"? Downloaded songs are kept.';
  }

  @override
  String get playlistLabel => 'PLAYLIST';

  @override
  String get rename => 'Rename';

  @override
  String get renamePlaylist => 'Rename playlist';

  @override
  String get emptyPlaylist => 'This playlist is empty';

  @override
  String deletePlaylistDetailBody(String name, int count) {
    return 'The playlist \"$name\" will be deleted and its $count songs removed from the list. Downloaded ones stay in your library.';
  }

  @override
  String get importTitle => 'Import playlists';

  @override
  String get importSubtitle =>
      'Paste a public Spotify playlist link, or import a CSV (Exportify / TuneMyMusic). Songs are searched and downloaded from YouTube.';

  @override
  String get importEmpty => 'Import from Spotify or a CSV to start';

  @override
  String get spotify => 'Spotify';

  @override
  String get csv => 'CSV';

  @override
  String get importSpotifyTitle => 'Import from Spotify';

  @override
  String get importSpotifyDesc =>
      'Paste a Spotify playlist, album or song link (including editorial ones). No login required.';

  @override
  String get importSpotifyHint =>
      'https://open.spotify.com/playlist/... (or /album/, /track/)';

  @override
  String get importAction => 'Import';

  @override
  String addToListCount(int count) {
    return 'Add to list ($count)';
  }

  @override
  String downloadCount(int count) {
    return 'Download ($count)';
  }

  @override
  String get searching => 'Searching…';

  @override
  String get nowPlaying => 'NOW PLAYING';

  @override
  String get nothingPlaying => 'Nothing is playing';

  @override
  String get queue => 'Queue';

  @override
  String get emptyQueue => 'Queue empty';

  @override
  String get radio => 'Radio';

  @override
  String get addToList => 'Add to list';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get downloading => 'Downloading…';

  @override
  String addedTo(String name) {
    return 'Added to $name';
  }

  @override
  String get settings => 'Settings';

  @override
  String get localLibrary => 'Local library';

  @override
  String get localMusicFolder => 'Local music folder';

  @override
  String get notSelected => 'Not selected';

  @override
  String audioFilesFound(int count) {
    return '$count audio files found';
  }

  @override
  String get chooseFolder => 'Choose folder';

  @override
  String get playFolder => 'Play folder';

  @override
  String get storage => 'Storage';

  @override
  String downloadedSongsCount(int count) {
    return '$count downloaded songs';
  }

  @override
  String mbOnDisk(String mb) {
    return '$mb MB on disk';
  }

  @override
  String get about => 'About';

  @override
  String get appTagline => 'Desktop player · v1.0';
}
