#!/bin/bash
git clone https://github.com/ZestCommunity/ZestCode.git && cd ZestCode  && git switch build/meson-init && sed -i 's/-mfloat-abi=hard/-mfloat-abi=softfp/g' scripts/v5.ini && meson setup --cross-file scripts/v5.ini builddir && meson compile -C builddir
# meson setup --cross-file scripts/v5.ini builddir
# meson compile -C builddir