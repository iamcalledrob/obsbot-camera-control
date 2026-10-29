{
  lib,
  stdenv,
  cmake,
  qt6,
  autoPatchelfHook,
  patchelf,
  lsof,
}:

stdenv.mkDerivation {
  pname = "obsbot-camera-control";
  version = "1.3.0";

  # Not lib.cleanSource: it drops *.so files, including the vendored SDK.
  src = lib.fileset.toSource {
    root = ./..;
    fileset = lib.fileset.unions [
      ../CMakeLists.txt
      ../src
      ../sdk
      ../resources
      ../obsbot-control.desktop
      ../README.md
      ../LICENSE
    ];
  };

  nativeBuildInputs = [
    cmake
    qt6.wrapQtAppsHook
    autoPatchelfHook
    patchelf
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtmultimedia
    stdenv.cc.cc.lib
  ];

  # CMakeLists.txt has no install rules and writes the binaries to
  # $src/bin, so install by hand, mirroring the PKGBUILD.
  installPhase = ''
    runHook preInstall

    cd ..

    install -Dm755 bin/obsbot-gui $out/bin/obsbot-gui
    install -Dm755 bin/obsbot-cli $out/bin/obsbot-cli

    install -Dm755 sdk/lib/libdev.so.1.0.2 $out/lib/libdev.so.1.0.2
    ln -s libdev.so.1.0.2 $out/lib/libdev.so.1
    ln -s libdev.so.1.0.2 $out/lib/libdev.so

    # The vendored libdev.so carries a RUNPATH pointing at an OBSBOT
    # developer's machine, and the binaries one pointing at the build tree.
    # autoPatchelfHook adds back the store paths they actually need.
    patchelf --remove-rpath $out/bin/obsbot-gui
    patchelf --remove-rpath $out/bin/obsbot-cli
    patchelf --remove-rpath $out/lib/libdev.so.1.0.2

    install -Dm644 obsbot-control.desktop $out/share/applications/obsbot-control.desktop
    install -Dm644 resources/icons/camera.svg \
      $out/share/icons/hicolor/scalable/apps/obsbot-control.svg
    install -Dm644 README.md $out/share/doc/obsbot-camera-control/README.md

    runHook postInstall
  '';

  # obsbot-cli doesn't use Qt; only wrap the GUI, and give it lsof for
  # detecting when the camera is in use by another application.
  dontWrapQtApps = true;
  postFixup = ''
    wrapQtApp $out/bin/obsbot-gui --prefix PATH : ${lib.makeBinPath [ lsof ]}
  '';

  meta = {
    description = "Native Linux control app for OBSBOT cameras with PTZ, auto-framing, presets, and live preview";
    homepage = "https://github.com/aaronsb/obsbot-camera-control";
    license = lib.licenses.mit;
    # libdev.so is a prebuilt binary from the OBSBOT SDK.
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryNativeCode
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "obsbot-gui";
  };
}
