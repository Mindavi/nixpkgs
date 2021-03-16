{ lib, stdenv, stdenvNoCC, fetchFromGitHub, callPackage, makeWrapper
, clang, llvm, gcc, which, libcgroup, python, perl, gmp
, file, wine ? null, fetchpatch
}:
let
  aflplusplus = stdenvNoCC.mkDerivation rec {
    pname = "aflplusplus";
    version = "3.10c";

    src = fetchFromGitHub {
      owner = "AFLplusplus";
      repo = "AFLplusplus";
      rev = version;
      sha256 = "olFT+GpaThukeppTznK+l/qhgN/jax/AB33o0ZQw77w=";
    };
    enableParallelBuilding = true;

    # Note: libcgroup isn't needed for building, just for the afl-cgroup
    # script.
    nativeBuildInputs = [ makeWrapper which clang gcc ];
    buildInputs = [ llvm python gmp ]
      ++ lib.optional (wine != null) python.pkgs.wrapPython;


    postPatch = ''
      # Replace the CLANG_BIN variables with the correct path
      # Replace "gcc" and friends with full paths in afl-gcc
      # Prevents afl-gcc picking up any (possibly incorrect) gcc from the path
      substituteInPlace src/afl-cc.c \
        --replace "CLANGPP_BIN" '"${clang}/bin/clang++"' \
        --replace "CLANG_BIN" '"${clang}/bin/clang"' \
        --replace 'getenv("AFL_PATH")' "(getenv(\"AFL_PATH\") ? getenv(\"AFL_PATH\") : \"$out/lib/afl\")" \
        --replace '"gcc"' '"${gcc}/bin/gcc"' \
        --replace '"g++"' '"${gcc}/bin/g++"' \
        --replace '"clang"' '"${clang}/bin/clang"' \
        --replace '"clang++"' '"${clang}/bin/clang++"'
    '';

    makeFlags = [ "PREFIX=$(out)" ];
    buildPhase = ''
      common="$makeFlags -j$NIX_BUILD_CORES"
      make distrib $common
    '';

    postInstall = ''
      patchShebangs $out/bin
    '';

    installCheckInputs = [ perl file ];
    #doInstallCheck = true;
    doCheck = true;

    meta = {
      description = ''
        A heavily enhanced version of AFL, incorporating many features
        and improvements from the community
      '';
      homepage    = "https://aflplus.plus";
      license     = lib.licenses.asl20;
      platforms   = ["x86_64-linux" "i686-linux"];
      maintainers = with lib.maintainers; [ ris mindavi ];
    };
  };
in aflplusplus
