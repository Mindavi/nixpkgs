{ alsa-lib
, fetchFromGitHub
, makeWrapper
, openssl
, pkg-config
, python3
, rustPlatform
, lib
, wayland
, xorg
, vulkan-loader
, jre_minimal
, cairo
, gtk3
, wrapGAppsHook
, gsettings-desktop-schemas
, glib
}:

rustPlatform.buildRustPackage rec {
  pname = "ruffle";
  version = "nightly-2023-07-10";

  src = fetchFromGitHub {
    owner = "ruffle-rs";
    repo = pname;
    rev = version;
    hash = "sha256-ot51ElIDGKOugi1+7I8etZzyANrpsL7NuC33FW9S4nw=";
  };

  nativeBuildInputs = [
    glib
    gsettings-desktop-schemas
    jre_minimal
    makeWrapper
    pkg-config
    python3
    wrapGAppsHook
  ];

  buildInputs = [
    alsa-lib
    cairo
    gtk3
    openssl
    wayland
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    xorg.libxcb
    xorg.libXrender
    vulkan-loader
  ];

  dontWrapGApps = true;

  postFixup = ''
    # This name is too generic
    mv $out/bin/exporter $out/bin/ruffle_exporter

    vulkanWrapperArgs+=(
      --prefix LD_LIBRARY_PATH ':' ${vulkan-loader}/lib
    )

    wrapProgram $out/bin/ruffle_exporter \
      "''${vulkanWrapperArgs[@]}"

    wrapProgram $out/bin/ruffle_desktop \
      "''${vulkanWrapperArgs[@]}" \
      "''${gappsWrapperArgs[@]}"
  '';

  cargoBuildFlags = [ "--workspace" ];

  # Currently, buildRustPackage can't handle having both the Crates.io dasp-0.11
  # and the git dasp-0.11, as it tries to symlink both to the same place. For
  # now, unify both dasp versions to the (newer) Git version.
  # Related issues: #22177, #183344
  cargoPatches = [ ./unify-dasp-version.patch ];
  postPatch = ''
    sed -i 's/dasp_sample 0.11.0.*"/dasp_sample"/' Cargo.lock
    sed -i '1129,1134d' Cargo.lock
    sed -i 's;git+https://github.com/RustAudio/dasp?rev=f05a703#f05a703d247bb504d7e812b51e95f3765d9c5e94;git+https://github.com/RustAudio/dasp?rev=f05a703d247bb504d7e812b51e95f3765d9c5e94#f05a703d247bb504d7e812b51e95f3765d9c5e94;' Cargo.lock
    sed -i 's;rev = "f05a703";rev = "f05a703d247bb504d7e812b51e95f3765d9c5e94";' core/Cargo.toml
  '';

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "dasp-0.11.0" = "sha256-CZNgTLL4IG7EJR2xVp9X9E5yre8foY6VX2hUMRawxiI=";
      "flash-lso-0.5.0" = "sha256-9uH3quxRzLtmHJs5WF/GRxWkXL/KFyOl182HKcHNnuc=";
      "gc-arena-0.3.1" = "sha256-lSwQKWRAg/dMCd3/EVNfpxMhfnKs6DGOl93nuHEMJUA=";
      "h263-rs-0.1.0" = "sha256-4kBg09VHyiQTvUbvcTb5g/BVcOpRFZ1fVEuRWXv5XwE=";
      "nellymoser-rs-0.1.2" = "sha256-GykDQc1XwySOqfxW/OcSxkKCFJyVmwSLy/CEBcwcZJs=";
      "nihav_codec_support-0.1.0" = "sha256-rE9AIiQr+PnHC9xfDQULndSfFHSX4sqKkCAQYVNaJcQ=";
    };
  };

  meta = with lib; {
    description = "An Adobe Flash Player emulator written in the Rust programming language.";
    homepage = "https://ruffle.rs/";
    license = with licenses; [ mit asl20 ];
    maintainers = with maintainers; [ govanify ];
    platforms = platforms.linux;
  };
}
