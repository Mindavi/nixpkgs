{ stdenv, lib, wayland, wayland-protocols, xorgserver, xkbcomp, xkeyboard_config
, epoxy, libxslt, libunwind, makeWrapper, egl-wayland, pkg-config
, withWrapper ? (stdenv.buildPlatform == stdenv.hostPlatform)
, defaultFontPath ? "" }:

with lib;

xorgserver.overrideAttrs (oldAttrs: {

  name = "xwayland-${xorgserver.version}";
  nativeBuildInputs = [
    pkg-config
    wayland
  ];
  buildInputs = oldAttrs.buildInputs ++ [ egl-wayland ];
  propagatedBuildInputs = oldAttrs.propagatedBuildInputs
    ++ [wayland wayland-protocols epoxy libxslt libunwind]
    ++ lib.optional withWrapper makeWrapper;
  configureFlags = [
    "--disable-docs"
    "--disable-devel-docs"
    "--enable-xwayland"
    "--enable-xwayland-eglstream"
    "--disable-xorg"
    "--disable-xvfb"
    "--disable-xnest"
    "--disable-xquartz"
    "--disable-xwin"
    "--enable-glamor"
    "--with-default-font-path=${defaultFontPath}"
    "--with-xkb-bin-directory=${xkbcomp}/bin"
    "--with-xkb-path=${xkeyboard_config}/etc/X11/xkb"
    "--with-xkb-output=$(out)/share/X11/xkb/compiled"
  ];

  postInstall = ''
    rm -fr $out/share/X11/xkb/compiled
  '';

  meta = {
    description = "An X server for interfacing X11 apps with the Wayland protocol";
    homepage = "https://wayland.freedesktop.org/xserver.html";
    license = licenses.mit;
    platforms = platforms.linux;
  };
})
