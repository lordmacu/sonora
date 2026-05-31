## Sonora

Binarios para macOS, Windows y Linux. **No están firmados** (por ahora no se paga
firma de Apple ni de Windows), así que el sistema mostrará una advertencia la
primera vez. Es normal; así se abren:

### 🍎 macOS — `Sonora-macos.dmg`
1. Abre el `.dmg` y arrastra **Sonora** a la carpeta **Aplicaciones**.
2. Si dice *"no se puede abrir porque procede de un desarrollador no identificado"*:
   - Clic derecho sobre la app → **Abrir** → **Abrir**, **o**
   - En Terminal: `xattr -dr com.apple.quarantine /Applications/Sonora.app`

### 🪟 Windows — `Sonora-windows-setup.exe`
- Si aparece *"Windows protegió tu PC"* (SmartScreen):
  **Más información** → **Ejecutar de todas formas**.

### 🐧 Linux
**Opción A — `.deb` (Debian/Ubuntu, aparece en el menú de aplicaciones):**
```bash
sudo apt install ./Sonora-linux-amd64.deb
```
Queda en el menú como "Sonora". Para desinstalar: `sudo apt remove sonora`.

**Opción B — `.AppImage` (portátil, cualquier distro, sin instalar):**
```bash
chmod +x Sonora-linux-x86_64.AppImage
./Sonora-linux-x86_64.AppImage
```
Para que el AppImage también salga en el menú, usa
[AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher).

Requisitos: x86_64, glibc ≥ 2.35 (Ubuntu 22.04+/Debian 12+/Fedora 36+…).
