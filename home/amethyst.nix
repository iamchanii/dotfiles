{ ... }:
let
  # Karabiner(home/karabiner.nix)가 만드는 모디파이어를 Amethyst 모디파이어로 그대로 쓴다.
  # Amethyst 는 실제로 눌린 모디파이어 조합을 보므로, Hyper/Meh 가 합성하는 키들을 적는다.
  #   mod1 = Meh   (⌃⌥⇧)   — Karabiner 가 우측 Option 에 매핑. 주 명령(포커스·레이아웃·창 교환).
  #   mod2 = Hyper (⌘⌃⌥⇧)  — Karabiner 가 우측 Command 에 매핑. 공간·화면 이동 등 큰 이동.
  meh = [ "control" "option" "shift" ];
  hyper = [ "command" "control" "option" "shift" ];

  # mod2(Hyper) + 1..9 → 현재 창을 1~9번 공간(Space)으로 보낸다.
  throwSpace = builtins.listToAttrs (map (n: {
    name = "throw-space-${toString n}";
    value = {
      mod = "mod2";
      key = toString n;
    };
  }) (builtins.genList (i: i + 1) 9));
in
{
  # Amethyst 키맵·동작을 Nix 로 선언적으로 관리한다.
  # Amethyst 는 ~/.amethyst.yml 을 읽는다. YAML 은 JSON 의 상위집합이라
  # builtins.toJSON 출력이 그대로 유효한 YAML 이므로 karabiner.json 과 같은 방식을 쓴다.
  # home.file 이 읽기 전용 심볼릭 링크로 만들므로 GUI 편집·저장은 불가하다. 변경은 여기서.
  home.file.".amethyst.yml".text = builtins.toJSON ({
    mod1 = meh;
    mod2 = hyper;

    # 순환할 레이아웃 목록 (mod1+space 로 이 순서대로 넘어간다).
    layouts = [ "tall" "wide" "fullscreen" "column" ];

    # 창 사이·화면 가장자리 여백.
    window-margins = true;
    window-margin-size = 8;
    screen-padding-left = 8;
    screen-padding-right = 8;
    screen-padding-top = 8;
    screen-padding-bottom = 8;

    # 레이아웃 순환
    cycle-layout = { mod = "mod1"; key = "space"; };
    cycle-layout-backward = { mod = "mod2"; key = "space"; };

    # 메인 영역 크기 조절
    shrink-main = { mod = "mod1"; key = "h"; };
    expand-main = { mod = "mod1"; key = "l"; };
    increase-main = { mod = "mod1"; key = ","; };
    decrease-main = { mod = "mod1"; key = "."; };

    # 포커스 이동
    focus-ccw = { mod = "mod1"; key = "j"; };
    focus-cw = { mod = "mod1"; key = "k"; };
    focus-main = { mod = "mod1"; key = "m"; };

    # 창 위치 교환
    swap-ccw = { mod = "mod2"; key = "j"; };
    swap-cw = { mod = "mod2"; key = "k"; };
    swap-main = { mod = "mod1"; key = "enter"; };

    # 레이아웃 직접 선택
    select-tall-layout = { mod = "mod1"; key = "a"; };
    select-wide-layout = { mod = "mod1"; key = "s"; };
    select-fullscreen-layout = { mod = "mod1"; key = "d"; };
    select-column-layout = { mod = "mod1"; key = "f"; };

    # 화면(모니터) 간 이동
    focus-screen-ccw = { mod = "mod1"; key = "p"; };
    focus-screen-cw = { mod = "mod1"; key = "n"; };
    swap-screen-ccw = { mod = "mod2"; key = "p"; };
    swap-screen-cw = { mod = "mod2"; key = "n"; };

    # 공간(Space) 간 이동
    throw-space-left = { mod = "mod2"; key = "left"; };
    throw-space-right = { mod = "mod2"; key = "right"; };

    # 기타
    toggle-float = { mod = "mod1"; key = "t"; };
    toggle-tiling = { mod = "mod2"; key = "t"; };
    display-current-layout = { mod = "mod1"; key = "i"; };
    reevaluate-windows = { mod = "mod1"; key = "z"; };
    toggle-focus-follows-mouse = { mod = "mod2"; key = "x"; };
    relaunch-amethyst = { mod = "mod2"; key = "r"; };
  } // throwSpace);
}
