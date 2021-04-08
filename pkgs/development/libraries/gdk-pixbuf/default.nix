{ stdenv
, fetchurl
, nixosTests
, fixDarwinDylibNames
, meson
, ninja
, pkg-config
, gettext
, python3
, libxml2
, libxslt
, docbook-xsl-nons
, docbook_xml_dtd_43
, gtk-doc
, glib
, libtiff
, libjpeg
, libpng
, gnome3
, gobject-introspection
, doCheck ? false
, makeWrapper
, lib
, buildPackages
}:

let
  isCross = stdenv.hostPlatform != stdenv.buildPlatform;
in
stdenv.mkDerivation rec {
  pname = "gdk-pixbuf";
  version = "2.42.2";

  outputs = [ "out" "dev" "man" ] ++ lib.optionals (!isCross) [ "devdoc" "installedTests" ];

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${lib.versions.majorMinor version}/${pname}-${version}.tar.xz";
    sha256 = "05ggmzwvrxq9w4zcvmrnnd6qplsmb4n95lj4q607c7arzlf6mil3";
  };

  patches = [
    # Move installed tests to a separate output
    ./installed-tests-path.patch
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    gettext
    python3
    libxml2
    libxslt
    docbook-xsl-nons
    docbook_xml_dtd_43
    makeWrapper
    glib
  ] ++ lib.optional stdenv.isDarwin fixDarwinDylibNames
    ++ lib.optionals (!isCross) [
    gobject-introspection
    gtk-doc
  ];

  propagatedBuildInputs = [
    glib
    libtiff
    libjpeg
    libpng
  ];

  mesonFlags = [
    "-Dgtk_doc=${if isCross then "false" else "true"}"
    "-Dintrospection=${if (gobject-introspection != null && (!isCross)) then "enabled" else "disabled"}"
    "-Dgio_sniffing=false"
  ];

  postPatch = ''
    chmod +x build-aux/* # patchShebangs only applies to executables
    patchShebangs build-aux

    substituteInPlace tests/meson.build --subst-var-by installedtestsprefix "$installedTests"
  '';

  postInstall =
    # meson erroneously installs loaders with .dylib extension on Darwin.
    # Their @rpath has to be replaced before gdk-pixbuf-query-loaders looks at them.
    lib.optionalString stdenv.isDarwin ''
      for f in $out/${passthru.moduleDir}/*.dylib; do
          install_name_tool -change @rpath/libgdk_pixbuf-2.0.0.dylib $out/lib/libgdk_pixbuf-2.0.0.dylib $f
          mv $f ''${f%.dylib}.so
      done
    ''
    # All except one utility seem to be only useful during building.
    + ''
      moveToOutput "bin" "$dev"
      moveToOutput "bin/gdk-pixbuf-thumbnailer" "$out"
    '' + lib.optionalString (stdenv.hostPlatform == stdenv.buildPlatform) ''
      # We need to install 'loaders.cache' in lib/gdk-pixbuf-2.0/2.10.0/
      $dev/bin/gdk-pixbuf-query-loaders --update-cache
    '' + lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
      # librsvg depends on this file being available
      # maybe other things do too (but implicitly)
      # so let's build the cache file using an emulator
      ${buildPackages.qemu}/bin/qemu-aarch64 $dev/bin/gdk-pixbuf-query-loaders --update-cache
    '';

  # The fixDarwinDylibNames hook doesn't patch binaries.
  preFixup = lib.optionalString stdenv.isDarwin ''
    for f in $out/bin/* $dev/bin/*; do
        install_name_tool -change @rpath/libgdk_pixbuf-2.0.0.dylib $out/lib/libgdk_pixbuf-2.0.0.dylib $f
    done
  '';

  preInstall = ''
    PATH=$PATH:$out/bin # for install script
  '';

  # The tests take an excessive amount of time (> 1.5 hours) and memory (> 6 GB).
  inherit doCheck;

  setupHook = ./setup-hook.sh;

  separateDebugInfo = stdenv.isLinux;

  passthru = {
    updateScript = gnome3.updateScript {
      packageName = pname;
    };

    tests = {
      installedTests = nixosTests.installed-tests.gdk-pixbuf;
    };

    # gdk_pixbuf_moduledir variable from gdk-pixbuf-2.0.pc
    moduleDir = "lib/gdk-pixbuf-2.0/2.10.0/loaders";
  };

  meta = with lib; {
    description = "A library for image loading and manipulation";
    homepage = "https://gitlab.gnome.org/GNOME/gdk-pixbuf";
    maintainers = [ maintainers.eelco ] ++ teams.gnome.members;
    license = licenses.lgpl21Plus;
    platforms = platforms.unix;
  };
}
