#!/usr/bin/env python3
"""Genera los iconos de Sonora (macOS, Windows, Linux) SIN dependencias externas.

Reproduce el logo del sidebar (lib/ui/sidebar.dart): un circulo verde
(#1DB954, AppColors.primary) con un ecualizador negro (estilo Icons.graphic_eq)
centrado. Dibuja a mano y codifica PNG/ICO con la libreria estandar (zlib/struct).
"""
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

GREEN = (0x1D, 0xB9, 0x54)   # AppColors.primary
BLACK = (0x00, 0x00, 0x00)   # Colors.black / onPrimary

MASTER = 1024
SS = 2  # supersampling para suavizar bordes

# Ecualizador: 5 barras (centro_x, altura) en una caja de 24 unidades.
BARS = [(4, 7), (8, 13), (12, 20), (16, 13), (20, 7)]


def render_master(N=MASTER, ss=SS):
    """Devuelve bytes RGBA NxN con el circulo verde + ecualizador negro."""
    M = N * ss
    buf = bytearray(M * M * 4)

    cx = cy = (M - 1) / 2.0
    R = (M * 0.98) / 2.0          # circulo inscrito con ~2% de margen
    glyph = M * 0.6               # ratio 18/30 del sidebar
    off = (M - glyph) / 2.0
    u = glyph / 24.0
    hw = (2.6 * u) / 2.0          # medio ancho de barra (extremos redondeados)
    R2 = R * R
    hw2 = hw * hw

    bars = []
    for cu, hu in BARS:
        bxc = off + cu * u
        bh = hu * u
        sy0 = cy - bh / 2.0 + hw  # segmento interior (para capsula)
        sy1 = cy + bh / 2.0 - hw
        bars.append((bxc, sy0, sy1))

    for y in range(M):
        row = y * M
        fy = float(y)
        for x in range(M):
            dx = x - cx
            dy = fy - cy
            if dx * dx + dy * dy > R2:
                continue
            col = GREEN
            for bxc, sy0, sy1 in bars:
                bdx = x - bxc
                if -hw <= bdx <= hw:
                    yy = fy
                    if yy < sy0:
                        yy = sy0
                    elif yy > sy1:
                        yy = sy1
                    bdy = fy - yy
                    if bdx * bdx + bdy * bdy <= hw2:
                        col = BLACK
                        break
            i = (row + x) * 4
            buf[i] = col[0]
            buf[i + 1] = col[1]
            buf[i + 2] = col[2]
            buf[i + 3] = 255

    return downsample(buf, M, N)


def downsample(buf, M, N):
    """Reduce un buffer RGBA MxM a NxN promediando bloques (box filter)."""
    if M == N:
        return bytes(buf)
    out = bytearray(N * N * 4)
    bx = M / N
    by = M / N
    for oy in range(N):
        y0 = int(oy * by)
        y1 = max(y0 + 1, int((oy + 1) * by))
        for ox in range(N):
            x0 = int(ox * bx)
            x1 = max(x0 + 1, int((ox + 1) * bx))
            r = g = b = a = cnt = 0
            for yy in range(y0, y1):
                base = yy * M
                for xx in range(x0, x1):
                    j = (base + xx) * 4
                    r += buf[j]
                    g += buf[j + 1]
                    b += buf[j + 2]
                    a += buf[j + 3]
                    cnt += 1
            o = (oy * N + ox) * 4
            out[o] = r // cnt
            out[o + 1] = g // cnt
            out[o + 2] = b // cnt
            out[o + 3] = a // cnt
    return bytes(out)


def png_bytes(N, rgba):
    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data +
                struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))

    ihdr = struct.pack(">IIBBBBB", N, N, 8, 6, 0, 0, 0)  # RGBA 8-bit
    raw = bytearray()
    stride = N * 4
    for y in range(N):
        raw.append(0)  # filtro None
        raw += rgba[y * stride:(y + 1) * stride]
    idat = zlib.compress(bytes(raw), 9)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) +
            chunk(b"IDAT", idat) + chunk(b"IEND", b""))


def write_png(path, N, rgba):
    data = png_bytes(N, rgba)
    with open(path, "wb") as f:
        f.write(data)
    return data


def write_ico(path, entries):
    """entries: lista de (size, png_bytes). ICO con PNG embebido (Windows Vista+)."""
    n = len(entries)
    out = bytearray(struct.pack("<HHH", 0, 1, n))
    offset = 6 + 16 * n
    blobs = bytearray()
    for size, png in entries:
        b = 0 if size >= 256 else size
        out += struct.pack("<BBBBHHII", b, b, 0, 0, 1, 32, len(png), offset)
        blobs += png
        offset += len(png)
    out += blobs
    with open(path, "wb") as f:
        f.write(out)


def main():
    print("Renderizando icono maestro %dx%d (ss=%d)..." % (MASTER, MASTER, SS))
    master = render_master()

    # Cache de tamanos derivados.
    def at(size):
        return master if size == MASTER else downsample(bytearray(master), MASTER, size)

    # --- macOS ---
    mac_dir = os.path.join(ROOT, "macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    for s in (16, 32, 64, 128, 256, 512, 1024):
        write_png(os.path.join(mac_dir, "app_icon_%d.png" % s), s, at(s))
    print("macOS OK:", mac_dir)

    # --- Windows (.ico) ---
    win_res = os.path.join(ROOT, "windows", "runner", "resources")
    os.makedirs(win_res, exist_ok=True)
    ico_entries = [(s, png_bytes(s, at(s))) for s in (16, 24, 32, 48, 64, 128, 256)]
    write_ico(os.path.join(win_res, "app_icon.ico"), ico_entries)
    print("Windows OK:", os.path.join(win_res, "app_icon.ico"))

    # --- Linux (PNG) ---
    linux_dir = os.path.join(ROOT, "linux", "assets")
    os.makedirs(linux_dir, exist_ok=True)
    write_png(os.path.join(linux_dir, "sonora.png"), 512, at(512))
    print("Linux OK:", os.path.join(linux_dir, "sonora.png"))


if __name__ == "__main__":
    main()
