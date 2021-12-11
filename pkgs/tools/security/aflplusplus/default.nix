{ lib, stdenv, stdenvNoCC, fetchFromGitHub, callPackage, makeWrapper
, clang, llvm, gcc, which, libcgroup, python3, perl, gmp, llvmPackages
, file, fetchpatch
}:
let
  aflplusplus = stdenvNoCC.mkDerivation rec {
    pname = "aflplusplus";
    version = "3.14c";

    src = fetchFromGitHub {
      owner = "AFLplusplus";
      repo = "AFLplusplus";
      rev = version;
      sha256 = "sha256-VLq+00TGxLmD6BrnBoXss8/zvvb6hPBcEioh4CEr2Tk=";
    };
    enableParallelBuilding = true;

    # Note: libcgroup isn't needed for building, just for the afl-cgroup
    # script.
    nativeBuildInputs = [ makeWrapper which clang gcc ];
    buildInputs = [ llvm python3 gmp ];

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

    makeFlags = [
      "PREFIX=$(out)"
      "AFL_REAL_LD=${llvmPackages.bintools}/bin/ld.lld"
      # Set LLVM_BINDIR to the empty string to prevent the Makefile from trying
      # to find clang in that directory and other things that don't work well in nixpkgs.
      "LLVM_BINDIR="
    ];
    buildPhase = ''
      common="$makeFlags -j$NIX_BUILD_CORES"
      make source-only $common
    '';

    postInstall = ''
      patchShebangs $out/bin
    '';

    installCheckInputs = [ perl file ];
    doInstallCheck = true;
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
