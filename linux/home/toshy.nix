{ config, inputs, pkgs, ... }:
{
  imports = [ inputs.toshy.homeManagerModules.toshy ];

  home.packages = [
    (pkgs.writeShellScriptBin "toshy-install-user-files" ''
      runtime="${config.home.homeDirectory}/.local/state/toshy/runtime"
      if [ ! -x "$runtime/bin/python" ]; then
        echo "Toshy runtime이 없습니다. 먼저 make switch를 실행하세요." >&2
        exit 1
      fi
      exec "$runtime/bin/python" ${inputs.toshy}/setup_toshy.py install-user-files "$@"
    '')
    (pkgs.writeShellScriptBin "toshy-apply-customizations" ''
      exec ${pkgs.python3}/bin/python ${../../scripts/apply-toshy-customizations.py} "$@"
    '')
  ];

  # 공식 Flake는 런타임만 관리한다. 기존 Toshy 사용자 파일과 서비스는
  # install-user-files가 업데이트하면서 keymapper_api 구간을 보존한다.
  services.toshy.enable = true;
}
