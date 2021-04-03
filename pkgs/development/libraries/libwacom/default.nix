{ lib, stdenv, fetchFromGitHub, meson, ninja, glib, pkg-config, udev, libgudev, doxygen, python3 }:

stdenv.mkDerivation rec {
  pname = "libwacom";
  version = "unstable-2021-04-06";

  outputs = [ "out" "dev" ];

  src = fetchFromGitHub {
    owner = "linuxwacom";
    repo = "libwacom";
    #rev = "libwacom-${version}";
    rev = "327f1258057c45c4f6fbb2133842c30f1969b3ea";
    #sha256 = "sha256-o1xCSrWKPzz1GePEVB1jgx2cGzRtw0I6c4wful08Vx4=";
    sha256 = "sha256-mBEh+ZtuPFm7Ie1peohtHTnjx3/pv0FRkIaYvswfkK0=";
  };

  nativeBuildInputs = [ pkg-config meson ninja doxygen python3 ];

  mesonFlags = [ "-Dtests=disabled" ];

  buildInputs = [ glib udev libgudev ];

  meta = with lib; {
    platforms = platforms.linux;
    homepage = "https://linuxwacom.github.io/";
    description = "Libraries, configuration, and diagnostic tools for Wacom tablets running under Linux";
    maintainers = teams.freedesktop.members;
    license = licenses.mit;
  };
}
