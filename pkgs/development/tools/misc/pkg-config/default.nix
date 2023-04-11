{ lib, stdenv, fetchurl, libiconv, vanilla ? false }:

stdenv.mkDerivation rec {
  pname = "pkg-config";
  version = "0.29.2";

  src = fetchurl {
    #url = "https://pkg-config.freedesktop.org/releases/${pname}-${version}.tar.gz";
    url = "https://github.com/skeeto/u-config/archive/refs/tags/v0.31.0.tar.gz";
    hash = "sha256-XgDqPCH8hqZqReLOew7YkPeY4P3RbaVZGcNRI0Lr61s=";
  };

  outputs = [ "out" ];
  strictDeps = true;

  buildInputs = [ libiconv ];

  buildPhase = ''
    runHook preBuild

    $CC -Os -o pkg-config generic_main.c

    runHook postBuild
  '';

  enableParallelBuilding = true;
  doCheck = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 pkg-config $out/bin/pkg-config

    runHook postInstall
  '';

  meta = with lib; {
    description = "A tool that allows packages to find out information about other packages";
    homepage = "http://pkg-config.freedesktop.org/wiki/";
    platforms = platforms.all;
    license = licenses.gpl2Plus;
  };
}
