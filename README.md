<div align="center">

<img src="logo.png" alt="Sonora" width="128" height="128" />

# Sonora

**Reproductor de música de escritorio** — busca, escucha y descarga desde YouTube Music,
e importa tus playlists de Spotify sin login ni API.

[![Release](https://img.shields.io/github/v/release/lordmacu/sonora)](https://github.com/lordmacu/sonora/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-Desktop-02569B?logo=flutter)](https://flutter.dev)
![Platforms](https://img.shields.io/badge/macOS%20%C2%B7%20Windows%20%C2%B7%20Linux-grey)

[⬇️ Descargas](#-descargas) · [✨ Features](#-features) · [🚀 Cómo empezar](#-cómo-empezar)

</div>

---

<div align="center">
  <img src="home.png" alt="Sonora — pantalla principal" width="900" />
</div>

---

## ⬇️ Descargas

Descarga la última versión para tu sistema operativo:

| Sistema | Archivo | Descarga |
|--------|---------|----------|
| 🍎 **macOS** | `Sonora-macos.dmg` | [Descargar](https://github.com/lordmacu/sonora/releases/latest/download/Sonora-macos.dmg) |
| 🪟 **Windows** | `Sonora-windows-setup.exe` | [Descargar](https://github.com/lordmacu/sonora/releases/latest/download/Sonora-windows-setup.exe) |
| 🐧 **Linux** | `Sonora-linux-x86_64.AppImage` | [Descargar](https://github.com/lordmacu/sonora/releases/latest/download/Sonora-linux-x86_64.AppImage) |

> 📦 ¿Buscas una versión específica? Mira todas las [releases](https://github.com/lordmacu/sonora/releases).

> ⚠️ **Los binarios no están firmados** (aún no se paga la firma de Apple ni de Windows),
> así que el sistema mostrará una advertencia la primera vez. Es normal — abajo está cómo abrirlos.

### Cómo abrir cada plataforma

<details>
<summary>🍎 <b>macOS</b></summary>

1. Abre el `.dmg` y arrastra **Sonora** a la carpeta **Aplicaciones**.
2. Si dice *"no se puede abrir porque procede de un desarrollador no identificado"*:
   - Clic derecho sobre la app → **Abrir** → **Abrir**, **o**
   - En Terminal: `xattr -dr com.apple.quarantine /Applications/sonora.app`

</details>

<details>
<summary>🪟 <b>Windows</b></summary>

- Si aparece *"Windows protegió tu PC"* (SmartScreen):
  **Más información** → **Ejecutar de todas formas**.

</details>

<details>
<summary>🐧 <b>Linux</b></summary>

```bash
chmod +x Sonora-linux-x86_64.AppImage
./Sonora-linux-x86_64.AppImage
```
Funciona en la mayoría de distros sin instalar nada.

</details>

---

## ✨ Features

### 🎵 Reproducción
- Reproductor de escritorio basado en **media_kit / libmpv** (audio nativo y estable).
- Reproduce **archivos locales**, **streaming de YouTube** y colas tipo **radio**.
- **Cola inteligente**: shuffle, anterior/siguiente y modo radio que se autoextiende con relacionados.
- **Reanudación**: recuerda la posición de reproducción y recupera la sesión tras un cierre.
- **Reproductor expandido** a pantalla completa con carátula grande.
- **Barra "Now Playing"** siempre visible con controles rápidos.

### 🔎 Búsqueda y descarga
- **Búsqueda en YouTube Music** (InnerTube WEB_REMIX) con fallback automático.
- **Descarga de audio** con barra de progreso y **cola con concurrencia limitada**.
- **Caché automática a disco**: las canciones de streaming se guardan al escucharlas para uso offline.
- **Radio / relacionados** desde una sola canción, sin necesidad de IA.

### 📥 Importar tu biblioteca
- **Importar desde Spotify sin API ni login** — lee el JSON público de la página `embed`.
  Funciona incluso con playlists editoriales/algorítmicas (`37i9…`) que la API oficial bloquea.
- **Importar desde CSV** (formato Exportify / TuneMyMusic).
- Selecciona qué canciones importar y elige **"Agregar a lista"** (resuelve en YouTube sin descargar)
  o **"Descargar"** para tenerlas offline.
- Si ya existe una playlist con el mismo nombre, **reutiliza la existente** en vez de duplicarla.

### 📁 Playlists y biblioteca
- Crea, gestiona y **elimina playlists** (con confirmación; las protegidas quedan excluidas).
- **Covers en mosaico** estilo Spotify (1/2/3/4+ imágenes según las canciones).
- **Favoritos**, **escuchado recientemente** y vista de **descargas**.
- Agregar canciones a cualquier playlist desde la búsqueda o la biblioteca.

### ⚙️ Ajustes
- Elige una **carpeta de música local** y escanea tus archivos de audio.
- Reproduce una carpeta completa de un clic.
- Resumen de canciones descargadas.

### 🖥️ Escritorio
- App multiplataforma: **macOS · Windows · Linux**.
- Gestión de ventana nativa (tamaño, controles) con `window_manager`.
- Interfaz oscura inspirada en reproductores modernos.

---

## 🚀 Cómo empezar

¿Solo quieres usar Sonora? Ve a [Descargas](#-descargas). Para compilar desde el código:

### Requisitos
- [Flutter](https://docs.flutter.dev/get-started/install) (SDK Dart `^3.10.1`), con soporte de escritorio habilitado.
- Dependencias nativas de `media_kit` según tu sistema (libmpv en Linux).

### Compilar y ejecutar
```bash
git clone https://github.com/lordmacu/sonora.git
cd sonora
flutter pub get

# Ejecutar en desarrollo
flutter run -d macos      # o: windows / linux

# Compilar release
flutter build macos       # o: windows / linux
```

---

## 🛠️ Stack

| Área | Tecnología |
|------|-----------|
| UI | Flutter (Material) · `provider` |
| Audio | `media_kit` + `media_kit_libs_audio` (libmpv) |
| YouTube | `youtube_explode_dart` + InnerTube |
| Red | `http` |
| Almacenamiento | `shared_preferences` · `path_provider` |
| Ventana | `window_manager` |
| Imágenes | `cached_network_image` |

---

## 📄 Licencia

Proyecto personal. Úsalo bajo tu propia responsabilidad — Sonora no aloja ni distribuye
contenido; solo reproduce y organiza lo que el usuario decide buscar e importar.
