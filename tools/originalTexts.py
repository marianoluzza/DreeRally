"""Genera ui/util/originalTexts.c con las tablas de textos del dr.exe original.

El port solo transcribio la primera variante de cada tabla (la del Vagabond, la del primer
prestamo) y el resto del codigo las indexaba como &cadena[800 * coche], saliendose de ellas.
Las direcciones son las del decompilado; dr.exe es el de DeathRallyWin_10.exe.

    7z e DeathRallyWin_10.exe dr.exe -o.local/original-exe
    python tools/originalTexts.py .local/original-exe/dr.exe
"""
import sys

DATA_VA, DATA_RAW, DATA_END = 0x445000, 0x45000, 0x457000

# nombre, direccion, variantes, lineas, ancho de linea
TABLES = [
    ("sponsorWinStreakTexts", 0x447388, 6, 10, 80),   # racha de victorias, bono por coche
    ("sponsorNoPaintJobTexts", 0x448648, 6, 10, 80),  # sin un rasguno
    ("sponsorAllCarsCrashTexts", 0x449908, 6, 10, 80),  # todos los rivales destruidos
    ("loanGrantedTexts", 0x452528, 6, 6, 40),         # prestamo concedido / denegado
    ("loanOfferTexts", 0x452078, 6, 6, 40),           # oferta de prestamo
]


def read(exe, va, size):
    if not DATA_VA <= va < DATA_END:
        raise ValueError(hex(va))
    off = va - DATA_VA + DATA_RAW
    return exe[off:off + size]


def c_string(raw):
    text = raw.split(b"\0")[0].decode("latin-1")
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main(path):
    exe = open(path, "rb").read()
    out = [
        "//Generado por tools/originalTexts.py desde el dr.exe original. No editar a mano.",
        '#include "originalTexts.h"',
        "",
    ]
    for name, va, variants, lines, width in TABLES:
        out.append("//%s: %d variantes de %d lineas, desde 0x%X" % (name, variants, lines, va))
        out.append("const char %s[%d][%d][%d] = {" % (name, variants, lines, width))
        for v in range(variants):
            rows = [c_string(read(exe, va + v * lines * width + l * width, width)) for l in range(lines)]
            out.append("  {")
            out.extend("    %s," % r for r in rows)
            out.append("  },")
        out.append("};")
        out.append("")
    with open("ui/util/originalTexts.c", "w", encoding="latin-1", newline="\n") as f:
        f.write("\n".join(out))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".local/original-exe/dr.exe")
