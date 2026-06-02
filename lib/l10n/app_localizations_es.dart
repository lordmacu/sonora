// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navHome => 'Inicio';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navDownloads => 'Descargas';

  @override
  String get navPlaylists => 'Tus playlists';

  @override
  String get navImport => 'Importar';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get playlistsHeader => 'PLAYLISTS';

  @override
  String get greetingMorning => 'Buenos días';

  @override
  String get greetingAfternoon => 'Buenas tardes';

  @override
  String get greetingEvening => 'Buenas noches';

  @override
  String get quickSearch => 'Buscar música';

  @override
  String get quickDownloads => 'Tus descargas';

  @override
  String get quickImport => 'Importar';

  @override
  String get favorites => 'Favoritos';

  @override
  String get playlistGeneral => 'General';

  @override
  String get recentlyPlayed => 'Escuchado recientemente';

  @override
  String get yourPlaylists => 'Tus playlists';

  @override
  String get emptyHomeTitle => 'Aún no tienes música';

  @override
  String get emptyHomeSubtitle =>
      'Busca y descarga canciones para escucharlas sin conexión';

  @override
  String songsCount(int count) {
    return '$count canciones';
  }

  @override
  String get searchHint => '¿Qué quieres escuchar?';

  @override
  String get searchButton => 'Buscar';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get inDownloadsHint =>
      'En tus descargas · pulsa \"Buscar\" para buscar en YouTube';

  @override
  String get noLocalMatches =>
      'Sin coincidencias en tus descargas. Pulsa \"Buscar\" para buscar en YouTube.';

  @override
  String get searchInitialHint =>
      'Escribe para filtrar tus descargas, o pulsa \"Buscar\" para YouTube';

  @override
  String get download => 'Descargar';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get playNext => 'Reproducir a continuación';

  @override
  String get addToQueue => 'Agregar a la cola';

  @override
  String get addToPlaylist => 'Agregar a playlist';

  @override
  String get remove => 'Eliminar';

  @override
  String get removeFromPlaylist => 'Quitar de la playlist';

  @override
  String get play => 'Reproducir';

  @override
  String get shuffle => 'Aleatorio';

  @override
  String get select => 'Seleccionar';

  @override
  String get selectAll => 'Seleccionar todos';

  @override
  String get selectNone => 'Ninguno';

  @override
  String get deselect => 'Deseleccionar';

  @override
  String selectedCount(int count) {
    return '$count seleccionadas';
  }

  @override
  String deleteCount(int count) {
    return 'Eliminar ($count)';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get sortBy => 'Ordenar:';

  @override
  String get sortTitle => 'Título';

  @override
  String get sortDate => 'Fecha';

  @override
  String get downloads => 'Descargas';

  @override
  String get noDownloads => 'No tienes descargas todavía';

  @override
  String get deleteDownloadsTitle => 'Eliminar descargas';

  @override
  String deleteDownloadsBody(int count) {
    return '¿Eliminar $count canción(es) descargada(s)?';
  }

  @override
  String get deleteDownloadTitle => 'Eliminar descarga';

  @override
  String deleteDownloadBody(String title) {
    return '¿Eliminar \"$title\"?';
  }

  @override
  String get newButton => 'Nueva';

  @override
  String get newPlaylist => 'Nueva playlist';

  @override
  String get playlistNameHint => 'Nombre';

  @override
  String get create => 'Crear';

  @override
  String get options => 'Opciones';

  @override
  String get deletePlaylist => 'Eliminar playlist';

  @override
  String deletePlaylistBody(String name) {
    return '¿Eliminar \"$name\"? Las canciones descargadas no se borran.';
  }

  @override
  String get playlistLabel => 'PLAYLIST';

  @override
  String get rename => 'Renombrar';

  @override
  String get renamePlaylist => 'Renombrar playlist';

  @override
  String get emptyPlaylist => 'Esta playlist está vacía';

  @override
  String deletePlaylistDetailBody(String name, int count) {
    return 'Se eliminará la playlist «$name» y se quitarán sus $count canciones de la lista. Las que estén descargadas seguirán en tu biblioteca.';
  }

  @override
  String get importTitle => 'Importar playlists';

  @override
  String get importSubtitle =>
      'Pega el enlace de una playlist pública de Spotify, o importa un CSV (Exportify / TuneMyMusic). Las canciones se buscan y descargan desde YouTube.';

  @override
  String get importEmpty => 'Importa desde Spotify o un CSV para empezar';

  @override
  String get spotify => 'Spotify';

  @override
  String get csv => 'CSV';

  @override
  String get importSpotifyTitle => 'Importar de Spotify';

  @override
  String get importSpotifyDesc =>
      'Pega el enlace de una playlist, álbum o canción de Spotify (incluidas las editoriales). No requiere login.';

  @override
  String get importSpotifyHint =>
      'https://open.spotify.com/playlist/... (o /album/, /track/)';

  @override
  String get importAction => 'Importar';

  @override
  String addToListCount(int count) {
    return 'Agregar a lista ($count)';
  }

  @override
  String downloadCount(int count) {
    return 'Descargar ($count)';
  }

  @override
  String get searching => 'Buscando…';

  @override
  String get nowPlaying => 'REPRODUCIENDO';

  @override
  String get nothingPlaying => 'No hay nada reproduciéndose';

  @override
  String get queue => 'Cola';

  @override
  String get emptyQueue => 'Cola vacía';

  @override
  String get radio => 'Radio';

  @override
  String get addToList => 'Agregar a lista';

  @override
  String get audioOutput => 'Salida de audio';

  @override
  String get autoOutput => 'Automático (salida del sistema)';

  @override
  String get downloaded => 'Descargada';

  @override
  String get downloading => 'Descargando…';

  @override
  String addedTo(String name) {
    return 'Añadida a $name';
  }

  @override
  String get settings => 'Ajustes';

  @override
  String get localLibrary => 'Biblioteca local';

  @override
  String get localMusicFolder => 'Carpeta de música local';

  @override
  String get notSelected => 'No seleccionada';

  @override
  String audioFilesFound(int count) {
    return '$count archivos de audio encontrados';
  }

  @override
  String get chooseFolder => 'Elegir carpeta';

  @override
  String get playFolder => 'Reproducir carpeta';

  @override
  String get storage => 'Almacenamiento';

  @override
  String downloadedSongsCount(int count) {
    return '$count canciones descargadas';
  }

  @override
  String mbOnDisk(String mb) {
    return '$mb MB en disco';
  }

  @override
  String get about => 'Acerca de';

  @override
  String get appTagline => 'Reproductor de escritorio · v1.0';
}
