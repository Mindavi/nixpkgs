{ stdenv, stdenvNoCC, fetchFromGitHub, callPackage, makeWrapper
, clang, llvm, gcc, which, libcgroup, python, perl, gmp
, file, fetchpatch
}:

let
  #libdislocator = callPackage ./libdislocator.nix { inherit aflplusplus; };
  #libtokencap = callPackage ./libtokencap.nix { inherit aflplusplus; };
  aflplusplus = stdenvNoCC.mkDerivation rec {
    pname = "aflplusplus";
    version = "3.0c";

    src = fetchFromGitHub {
      owner = "AFLplusplus";
      repo = "AFLplusplus";
      rev = version;
      sha256 = "12rp7sxbsnnv1wrj1h0z3bl7g4jv5zbbd9pq7bvx8dazamcjkaxw";
    };
    enableParallelBuilding = true;

    # Note: libcgroup isn't needed for building, just for the afl-cgroup
    # script.
    nativeBuildInputs = [ makeWrapper which clang gcc ];
    buildInputs = [ llvm python gmp ];

    postPatch = ''
      # Replace the CLANGPP_BIN variables with the correct path
      # Replace "gcc" and friends with full paths in afl-gcc
      # Prevents afl-gcc picking up any (possibly incorrect) gcc from the path
      substituteInPlace src/afl-cc.c \
        --replace "USE_BINDIR" "true" \
        --replace 'getenv("AFL_PATH")' "(getenv(\"AFL_PATH\") ? getenv(\"AFL_PATH\") : \"$out/lib/afl\")" \
        --replace '"gcc"' '"${gcc}/bin/gcc"' \
        --replace '"g++"' '"${gcc}/bin/g++"' \
        --replace '"clang"' '"${clang}/bin/clang"' \
        --replace '"clang++"' '"${clang}/bin/clang++"' \
        --replace "LLVM_BINDIR" '"${clang}/bin"'

      substituteInPlace utils/aflpp_driver/GNUmakefile \
        --replace "\$(LLVM_BINDIR)clang" "${clang}/bin/clang"

      substituteInPlace src/afl-ld-lto.c \
        --replace "LLVM_BINDIR" "${llvm}/bin"

      #substituteInPlace GNUmakefile.llvm \
      #  --replace "@ln -sf afl-cc" "# REMOVED_FOR_NIX_  "
  '';

    makeFlags = [ "PREFIX=$(out)" ];
    buildPhase = ''
      export BIN_DIR="${clang}/bin"
      common="$makeFlags -j$NIX_BUILD_CORES"
      make source-only $common
      #make all $common
      #make radamsa $common
      #make -C gcc_plugin CC=${gcc}/bin/gcc CXX=${gcc}/bin/g++ $common
      #make -C llvm_mode $common
      #make -C qemu_mode/libcompcov $common
      #make -C qemu_mode/unsigaction $common
    '';

    postInstall = ''
      patchShebangs $out/bin
    '';

    installCheckInputs = [ perl file ];
    doInstallCheck = true;
    installCheckPhase = ''
      # replace references to tools in build directory with references to installed locations
      #substituteInPlace test/test.sh \
      #  --replace '../libcompcov.so' '`$out/bin/get-afl-qemu-libcompcov-so`' \
      #  --replace '../libdislocator.so' '`$out/bin/get-libdislocator-so`' \
      #  --replace '../libtokencap.so' '`$out/bin/get-libtokencap-so`'
      #perl -pi -e 's|(?<!\.)(?<!-I)(\.\./)([^\s\/]+?)(?<!\.c)(?<!\.s?o)(?=\s)|\$out/bin/\2|g' test/test.sh
      #cd test && ./test.sh
    '';

    meta = {
      description = ''
        A heavily enhanced version of AFL, incorporating many features
        and improvements from the community
      '';
      homepage    = "https://aflplus.plus";
      license     = stdenv.lib.licenses.asl20;
      platforms   = ["x86_64-linux" "i686-linux"];
      maintainers = with stdenv.lib.maintainers; [ ris mindavi ];
    };
  };
in aflplusplus
