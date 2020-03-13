{ stdenv, fetchFromGitHub, makeWrapper
, clang_9, llvm_9, which, gmp, python3
}:

let
  aflplusplus = stdenv.mkDerivation rec {
    pname = "aflplusplus";
    version = "2.62c";

    src = fetchFromGitHub {
      owner = "vanhauser-thc";
      repo = pname;
      rev = "${version}";
      sha256 = "0cns93ya1fpnh10z7jxszwil1ksdvsc5jzsab4rcpdz51s6nb5fm";
    };
    enableParallelBuilding = true;

    nativeBuildInputs = [ makeWrapper which clang_9 ];
    buildInputs = [ llvm_9 gmp python3 ];

    makeFlags = [ "PREFIX=$(out)" ];
    postBuild = ''
      make source-only $makeFlags -j$NIX_BUILD_CORES
    '';
    postInstall = ''
      # Patch shebangs before wrapping
      patchShebangs $out/bin

      # Wrap afl-clang-fast(++) with a *different* AFL_PATH, because it
      # has totally different semantics in that case(?) - and also set a
      # proper AFL_CC and AFL_CXX so we don't pick up the wrong one out
      # of $PATH.
      for x in $out/bin/afl-clang-fast $out/bin/afl-clang-fast++; do
        wrapProgram $x \
          --prefix AFL_PATH : "$out/lib/afl" \
          --run 'export AFL_CC=''${AFL_CC:-${clang_9}/bin/clang} AFL_CXX=''${AFL_CXX:-${clang_9}/bin/clang++}'
      done
    '';

    meta = {
      description = "Powerful fuzzer via genetic algorithms and instrumentation";
      longDescription = ''
        American fuzzy lop is a fuzzer that employs a novel type of
        compile-time instrumentation and genetic algorithms to
        automatically discover clean, interesting test cases that
        trigger new internal states in the targeted binary. This
        substantially improves the functional coverage for the fuzzed
        code. The compact synthesized corpora produced by the tool are
        also useful for seeding other, more labor or resource-intensive
        testing regimes down the road.
      '';
      homepage    = "https://github.com/vanhauser-thc/AFLplusplus";
      license     = stdenv.lib.licenses.asl20;
      platforms   = ["x86_64-linux" "i686-linux"];
      maintainers = with stdenv.lib.maintainers; [ Mindavi ];
    };
  };
in aflplusplus
