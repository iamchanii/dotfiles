{ ... }:

let
  # Karabiner(home/karabiner.nix)가 만드는 Hyper(⌘⌃⌥⇧)를 Amethyst 모디파이어로 쓴다.
  # Amethyst 는 실제 눌린 모디파이어 조합을 보므로 Hyper 가 합성하는 키들을 적는다.
  hyper = [ "command" "control" "option" "shift" ];

  # Hyper + 1..0 → 현재 포커스된 창을 1~10번 공간(Space)으로 보낸다.
  # 10번은 키보드 숫자 0 에 매핑한다.
  throwSpace = builtins.listToAttrs (map (n: {
    name = "throw-space-${toString n}";
    value = {
      mod = "mod1";
      key = if n == 10 then "0" else toString n;
    };
  }) (builtins.genList (i: i + 1) 10));
in
{
  # Amethyst 동작을 Nix 로 선언적으로 관리한다.
  # Amethyst 는 ~/.amethyst.yml 을 읽는다. YAML 은 JSON 의 상위집합이라
  # builtins.toJSON 출력이 그대로 유효한 YAML 이므로 karabiner.json 과 같은 방식을 쓴다.
  # home.file 이 읽기 전용 심볼릭 링크로 만들므로 GUI 편집·저장은 불가하다. 변경은 여기서.
  home.file.".amethyst.yml".text = builtins.toJSON ({
    mod1 = hyper;

    # 순환할 레이아웃 목록.
    layouts = [ "tall" "wide" "fullscreen" "column" ];

    # 마우스로 창 위치 교환·크기 조절 허용.
    mouse-swaps-windows = true;
    mouse-resizes-windows = true;

    # 창 사이·화면 가장자리 여백.
    window-margins = true;
    window-margin-size = 8;
    screen-padding-left = 8;
    screen-padding-right = 8;
    screen-padding-top = 8;
    screen-padding-bottom = 8;

    # 현재 포커스된 창을 인접 공간(왼/오른쪽)으로 보낸다.
    throw-space-left = { mod = "mod1"; key = "left"; };
    throw-space-right = { mod = "mod1"; key = "right"; };
  } // throwSpace);
}
