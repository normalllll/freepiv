# Application icon

The icon is the freepiv FP monogram with cat ears, whiskers and a blue dot, drawn on
a 150-unit grid: 90-wide strokes, 60-wide gaps, and a dot concentric with the bowl.

| Master | Used for |
| --- | --- |
| `app_icon.svg` | Every size above 48 px, and the Linux scalable icon |
| `app_icon_small.svg` | 48 px and below: no whiskers, solid ears, heavier strokes |
| `app_icon_monochrome.svg` | Android themed icon |

Platform exports are committed so that builds do not need Python. After changing a
master, regenerate them from the repository root:

```sh
uv run tool/generate_app_icons.py
```

| Platform | Treatment |
| --- | --- |
| Windows | Transparent, no tile. `app_icon.ico` holds 16–256 px frames. |
| Linux | Transparent `hicolor` PNGs from 16 to 512 px, plus a scalable SVG. |
| macOS | Transparent art on Apple's 824/1024 grid. macOS 26 and later may place non-rounded icons on a system tile. |
| iOS | Full-bleed opaque pale pink background; the system applies the mask. |
| Android | Adaptive foreground inside the safe zone, pale pink background, themed monochrome, and a rounded legacy icon for API levels below 26. |
| In-app | `assets/icon-512.png`, transparent. The root `icon-512.png` is the same image. |
