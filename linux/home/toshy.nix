{ config, inputs, lib, pkgs, ... }:
let
  upstreamRuntime = builtins.readFile "${inputs.toshy}/nix/toshy-runtime.nix";
  setuptoolsAlias = "pyFinal.setuptools_80";
  i3ipcAnchor = "      # xkbcommon pinned below 1.1";
  patchedRuntime = builtins.toFile "toshy-runtime.nix" (
    assert lib.assertMsg
      (lib.hasInfix setuptoolsAlias upstreamRuntime && lib.hasInfix i3ipcAnchor upstreamRuntime)
      "Toshy runtime의 Python override 구조가 변경되었습니다. 호환 패치를 검토하세요.";
    builtins.replaceStrings
      [ setuptoolsAlias i3ipcAnchor ]
      [
        "pyFinal.setuptools"
        ''
              # i3ipc가 nixpkgs의 python-xlib 0.33을 다시 끌어오지 않도록
              # Toshy가 위에서 고정한 0.31을 transitive dependency에도 사용한다.
              i3ipc = pyPrev.i3ipc.override { xlib = pyFinal.python-xlib; };

        ${i3ipcAnchor}''
      ]
      upstreamRuntime
  );

  # 현재 nixpkgs의 기본 setuptools는 80.x지만 Toshy가 참조하는 버전별 alias는
  # 제거됐다. 해당 참조를 고치고 i3ipc도 upstream의 python-xlib 0.31을 사용하게 한다.
  toshyRuntime = pkgs.callPackage patchedRuntime {
    toshySrc = inputs.toshy;
    keymapperBranch = "main";
  };
in
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
  services.toshy = {
    enable = true;
    runtimePackage = toshyRuntime;
  };
}
