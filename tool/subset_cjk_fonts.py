"""Rebuild the bundled CJK font subsets in assets/fonts.

Sources (SIL Open Font License 1.1, see assets/fonts/OFL-NotoSansCJK.txt):
  https://github.com/google/fonts/raw/main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf
  https://github.com/google/fonts/raw/main/ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf

Save them as NotoSansSC-VF.ttf and NotoSansJP-VF.ttf next to this script's
output directory, then run with fontTools installed:
  python3 tool/subset_cjk_fonts.py assets/fonts

The subsets keep the variable weight axis and cover the frequently used
character sets (GB 2312 and Big5 level 1 for Chinese, JIS X 0208 for
Japanese) plus Latin, punctuation, kana and full-width forms. Rarer
characters fall back to the platform's CJK fonts.
"""
import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont


def charset(codec, leads, trails):
    chars = set()
    for lead in leads:
        for trail in trails:
            try:
                chars.add(bytes([lead, trail]).decode(codec))
            except UnicodeDecodeError:
                pass
    return chars


def block(start, end):
    return {chr(c) for c in range(start, end)}


gb2312 = charset('gb2312', range(0xA1, 0xF8), range(0xA1, 0xFF))
big5_level1 = charset('big5', range(0xA4, 0xC7), list(range(0x40, 0x7F)) + list(range(0xA1, 0xFF)))
jis0208 = charset('euc_jp', range(0xA1, 0xF5), range(0xA1, 0xFF))

common = (
    block(0x20, 0x250)  # Latin, Latin-1, Latin Extended
    | block(0x2000, 0x2070)  # general punctuation
    | block(0x2100, 0x2190)  # letterlike symbols, number forms
    | block(0x2200, 0x2300)  # math operators
    | block(0x2460, 0x2500)  # enclosed alphanumerics
    | block(0x2500, 0x25A0)  # box drawing, block elements
    # Arrows, geometric shapes, miscellaneous symbols and dingbats are left
    # out: many are emoji-capable, and a bundled text glyph would win over the
    # platform's colour emoji font in the fallback chain.
    | block(0x3000, 0x3100)  # CJK punctuation, kana
    | block(0x31F0, 0x3200)  # katakana phonetic extensions
    | block(0xFF00, 0xFFF0)  # full-width forms
)

TARGETS = {
    'SC': gb2312 | big5_level1 | common,
    'JP': jis0208 | common,
}


def main(directory):
    for name, chars in TARGETS.items():
        options = subset.Options()
        options.layout_features = ['*']
        options.name_IDs = ['*']
        options.notdef_outline = True
        options.hinting = False
        font = TTFont(os.path.join(directory, f'NotoSans{name}-VF.ttf'))
        subsetter = subset.Subsetter(options)
        subsetter.populate(unicodes=[ord(c) for c in chars])
        subsetter.subset(font)
        font.save(os.path.join(directory, f'NotoSans{name}-Subset.ttf'))


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'assets/fonts')
