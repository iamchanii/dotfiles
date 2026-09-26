{ inputs, lib, pkgs, ... }:
let
  flavour = "Mocha";
  accent = "Blue";
  decoration = "Classic";
  globalTheme = "Catppuccin-${flavour}-${accent}";
  colorScheme = "Catppuccin${flavour}${accent}";
  auroraeTheme = "Catppuccin${flavour}-${decoration}";
  splashTheme = "${globalTheme}-splash";

  catppuccinKde = pkgs.runCommand "catppuccin-kde-${lib.toLower flavour}-${lib.toLower accent}" { } ''
    source=${inputs.catppuccin-kde}
    share="$out/share"

    mkdir -p \
      "$share/color-schemes" \
      "$share/aurorae/themes" \
      "$share/plasma/look-and-feel/${globalTheme}/contents/splash/images" \
      "$share/plasma/look-and-feel/${globalTheme}/contents/previews"

    cp "$source/generated/color-schemes/${colorScheme}.colors" \
      "$share/color-schemes/${colorScheme}.colors"

    cp -R "$source/Resources/Aurorae/${auroraeTheme}" \
      "$share/aurorae/themes/${auroraeTheme}"
    chmod -R u+w "$share/aurorae/themes/${auroraeTheme}"
    cp "$source/Resources/Aurorae/Common/Catppuccin-${decoration}rc" \
      "$share/aurorae/themes/${auroraeTheme}/${auroraeTheme}rc"

    cp -R "$source/Resources/LookAndFeel/Catppuccin-${flavour}-Global/contents/." \
      "$share/plasma/look-and-feel/${globalTheme}/contents/"
    chmod -R u+w "$share/plasma/look-and-feel/${globalTheme}"
    cp "$source/generated/look-and-feel/${decoration}/${globalTheme}/metadata.desktop" \
      "$share/plasma/look-and-feel/${globalTheme}/metadata.desktop"
    cp "$source/generated/look-and-feel/${decoration}/${globalTheme}/metadata.json" \
      "$share/plasma/look-and-feel/${globalTheme}/metadata.json"
    cp "$source/generated/look-and-feel/${decoration}/${globalTheme}/contents/defaults" \
      "$share/plasma/look-and-feel/${globalTheme}/contents/defaults"

    cp "$source/generated/splash/${splashTheme}/contents/splash/images/busywidget.svg" \
      "$share/plasma/look-and-feel/${globalTheme}/contents/splash/images/busywidget.svg"
    cp "$source/generated/splash-qml/Catppuccin${flavour}-Splash.qml" \
      "$share/plasma/look-and-feel/${globalTheme}/contents/splash/Splash.qml"
    cp "$source/Resources/splash-screen/contents/splash/images/Logo.png" \
      "$share/plasma/look-and-feel/${globalTheme}/contents/splash/images/Logo.png"
    cp "$source/Resources/splash-previews/${flavour}.png" \
      "$share/plasma/look-and-feel/${globalTheme}/contents/previews/splash.png"
  '';
in
{
  home.packages = [
    catppuccinKde
    pkgs.catppuccin-cursors.mochaBlue
  ];

  home.pointerCursor = {
    package = pkgs.catppuccin-cursors.mochaBlue;
    name = "catppuccin-mocha-blue-cursors";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # look-and-feel 적용은 여러 KDE 설정 파일을 함께 갱신해야 하므로 upstream과
  # 동일하게 Plasma 도구를 쓴다. 비-KDE 세션이나 headless build에서는 건너뛴다.
  home.activation.applyCatppuccinKde = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ "''${XDG_CURRENT_DESKTOP:-}" == *KDE* ]]; then
      export XDG_DATA_DIRS="${catppuccinKde}/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
      run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
        --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false
      run ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-lookandfeel \
        --apply ${globalTheme}
    fi
  '';
}
