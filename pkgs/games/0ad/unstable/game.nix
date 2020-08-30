{ stdenv, lib, perl, fetchFromGitLab, python2
, pkgconfig, spidermonkey_45, boost, icu, libxml2, libpng, libsodium
, libjpeg, zlib, curl, libogg, libvorbis, enet, miniupnpc
, openal, libGLU, libGL, xorgproto, libX11, libXcursor, nspr, SDL2
, nvidia-texture-tools, libidn
}:

stdenv.mkDerivation rec {
  pname = "0ad";
  package_version = "r23960";
  # required for 0ad-data
  version = "0.0.23b";

  src = fetchFromGitLab {
    domain = "gitlab.com";
    owner = "0ad";
    repo = pname;
    rev = "b553caa3b511a500c513d2587b05049943900836";
    sha256 = "02p7h6xph0byk65b01l24gl3ckrm9phq0zscv00639pzgq5yiqhg";
  };

  nativeBuildInputs = [ python2 perl pkgconfig ];

  buildInputs = [
    spidermonkey_45 boost icu libxml2 libpng libjpeg
    zlib curl libogg libvorbis enet miniupnpc openal
    libGLU libGL xorgproto libX11 libXcursor nspr SDL2
    nvidia-texture-tools libsodium libidn
  ];

  NIX_CFLAGS_COMPILE = toString [
    "-I${xorgproto}/include/X11"
    "-I${libX11.dev}/include/X11"
    "-I${libXcursor.dev}/include/X11"
    "-I${SDL2}/include/SDL2"
  ];

  patches = [
    ../rootdir_env.patch
  ];

  configurePhase = ''
    # Delete shipped libraries which we don't need.
    rm -rf libraries/source/{enet,miniupnpc,nvtt,spidermonkey}

    # Workaround invalid pkgconfig name for mozjs
    mkdir pkgconfig
    ln -s ${spidermonkey_45}/lib/pkgconfig/js.pc pkgconfig/mozjs-45.pc
    PKG_CONFIG_PATH="$PWD/pkgconfig:$PKG_CONFIG_PATH"

    # Update Makefiles
    pushd build/workspaces
    ./update-workspaces.sh \
      --with-system-nvtt \
      --with-system-mozjs45 \
      --without-lobby \
      --bindir="$out"/bin \
      --libdir="$out"/lib/0ad \
      --without-tests \
      -j $NIX_BUILD_CORES
    popd

    # Move to the build directory.
    pushd build/workspaces/gcc
  '';

  enableParallelBuilding = true;

  installPhase = ''
    popd

    # Copy executables.
    install -Dm755 binaries/system/pyrogenesis "$out"/bin/0ad

    # Copy l10n data.
    install -Dm755 -t $out/share/0ad/data/l10n binaries/data/l10n/*

    # Copy libraries.
    install -Dm644 -t $out/lib/0ad        binaries/system/*.so

    # Copy icon.
    install -D build/resources/0ad.png     $out/share/icons/hicolor/128x128/0ad.png
    install -D build/resources/0ad.desktop $out/share/applications/0ad.desktop
  '';

  meta = with stdenv.lib; {
    description = "A free, open-source game of ancient warfare";
    homepage = "https://play0ad.com/";
    license = with licenses; [
      gpl2 lgpl21 mit cc-by-sa-30
      licenses.zlib # otherwise masked by pkgs.zlib
    ];
    platforms = subtractLists platforms.i686 platforms.linux;
  };
}
