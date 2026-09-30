"""Package PNG representations into Apple's ICNS container."""
import pathlib
import struct
import sys

source, target = map(pathlib.Path, sys.argv[1:])
entries = [
    (b"icp4", "icon_16x16.png"),
    (b"icp5", "icon_32x32.png"),
    (b"icp6", "icon_32x32@2x.png"),
    (b"ic07", "icon_128x128.png"),
    (b"ic08", "icon_256x256.png"),
    (b"ic09", "icon_512x512.png"),
    (b"ic10", "icon_512x512@2x.png"),
    (b"ic11", "icon_16x16@2x.png"),
    (b"ic12", "icon_32x32@2x.png"),
    (b"ic13", "icon_128x128@2x.png"),
    (b"ic14", "icon_256x256@2x.png"),
]
chunks = []
for kind, name in entries:
    png = (source / name).read_bytes()
    assert png.startswith(b"\x89PNG\r\n\x1a\n")
    chunks.append(kind + struct.pack(">I", len(png) + 8) + png)
body = b"".join(chunks)
target.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)
