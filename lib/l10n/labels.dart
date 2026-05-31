import '../models/playlist.dart';
import 'app_localizations.dart';

/// Nombre a mostrar de una playlist, localizando las protegidas
/// (General/Favoritos), cuyos nombres se guardan como datos.
String playlistDisplayName(AppLocalizations l10n, Playlist pl) {
  if (pl.id == Playlist.generalId) return l10n.playlistGeneral;
  if (pl.id == Playlist.favoritesId) return l10n.favorites;
  return pl.name;
}
