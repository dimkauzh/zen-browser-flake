{
  description = "Zen Browser";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      version = "1.0.2-b.5";
      downloadUrl = {
        url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-x86_64.tar.bz2";
        sha256 = "1yz31q8ykm0myaji73j0q69s34gbf247l7yv81cgb0vgnw4d6z1b";
      };

      pkgs = import nixpkgs {
        inherit system;
      };

      runtimeLibs = with pkgs; [
        libGL libGLU libevent libffi libjpeg libpng libstartup_notification libvpx libwebp
        stdenv.cc.cc fontconfig libxkbcommon zlib freetype
        gtk3 libxml2 dbus xcb-util-cursor alsa-lib libpulseaudio pango atk cairo gdk-pixbuf glib
        udev libva mesa libnotify cups pciutils
        ffmpeg libglvnd pipewire
      ] ++ (with pkgs.xorg; [
        libxcb libX11 libXcursor libXrandr libXi libXext libXcomposite libXdamage
        libXfixes libXScrnSaver
      ]);

    in {
      packages."${system}" = pkgs.stdenv.mkDerivation {
        pname = "zen-browser";
        inherit version;

        src = builtins.fetchTarball {
          url = downloadUrl.url;
          sha256 = downloadUrl.sha256;
        };

        desktopSrc = ./.;

        phases = [ "installPhase" "fixupPhase" ];

        nativeBuildInputs = [ pkgs.makeWrapper pkgs.copyDesktopItems pkgs.wrapGAppsHook ];

        installPhase = ''
          mkdir -p $out/bin && cp -r $src/* $out/bin
          install -D $desktopSrc/zen.desktop $out/share/applications/zen.desktop
          install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
        '';

        fixupPhase = ''
          chmod 755 $out/bin/*
          patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen
          wrapProgram $out/bin/zen --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
            --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --set MOZ_APP_LAUNCHER zen --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
        '';

        meta = {
          mainProgram = "zen";
          description = "Zen Browser";
          license = pkgs.stdenv.lib.licenses.mit;
          maintainers = [ "dimkauzh" ];
          platforms = [ "x86_64-linux" ];
        };
      };
    };
}
