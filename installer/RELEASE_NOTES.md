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

### 🐧 Linux — `Sonora-linux-x86_64.AppImage`
```bash
chmod +x Sonora-linux-x86_64.AppImage
./Sonora-linux-x86_64.AppImage
```
Funciona en la mayoría de distros sin instalar nada.
