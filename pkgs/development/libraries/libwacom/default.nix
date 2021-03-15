{ lib, stdenv, fetchFromGitHub, meson, ninja, glib, pkg-config, udev, libgudev, doxygen, gcc }:

stdenv.mkDerivation rec {
  pname = "libwacom";
  version = "1.8";

  outputs = [ "out" "dev" ];

  src = fetchFromGitHub {
    owner = "linuxwacom";
    repo = "libwacom";
    rev = "libwacom-${version}";
    sha256 = "sha256-vkBkOE4aVX/6xKjslkqlZkh5jdYVEawvvBLpj8PpuiA=";
  };

  # Required for cross-compilation.
  # They're dependencies of libwacom, and the whole of libwacom is linked to generate the hwdb.
  # Generate-hwdb is build on the build platform for the build platform to run, so dependencies are listed
  # in depsBuildBuild.
  depsBuildBuild = [ pkg-config glib libgudev gcc ];

  nativeBuildInputs = [ pkg-config meson ninja doxygen ];

  mesonFlags = [ "-Dtests=disabled" ];

  buildInputs = [ glib udev libgudev ];

  patches = [
    # This patch is required to generate the hwdb.
    ./generate-hwdb-native.patch
  ];

  meta = with lib; {
    platforms = platforms.linux;
    homepage = "https://linuxwacom.github.io/";
    description = "Libraries, configuration, and diagnostic tools for Wacom tablets running under Linux";
    maintainers = teams.freedesktop.members;
    license = licenses.mit;
  };
}
