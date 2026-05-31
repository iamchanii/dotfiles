{ ... }:
let
  # Hyper = ⌘⌃⌥⇧. 모디파이어 4개를 동시에 누른 상태를 만들기 위해
  # left_shift 키에 나머지 3개(cmd/ctrl/opt)를 modifiers 로 얹는 관용적 방식.
  hyper = {
    key_code = "left_shift";
    modifiers = [ "left_command" "left_control" "left_option" ];
  };
  # Meh = ⌃⌥⇧. Hyper 에서 ⌘ 만 뺀 조합으로, ⌘ 기반 시스템 단축키와 덜 충돌한다.
  meh = {
    key_code = "left_shift";
    modifiers = [ "left_control" "left_option" ];
  };
in
{
  # Karabiner 키맵을 Nix 로 선언적으로 관리한다.
  # home.file 은 이 파일을 nix store 로의 "읽기 전용" 심볼릭 링크로 만들므로,
  # Karabiner GUI 에서 편집해 저장하는 것은 불가능하다. 모든 변경은 여기서 한다.
  # (자동 백업은 별도 디렉터리 ~/.config/karabiner/automatic_backups 로 가므로 무관)
  home.file.".config/karabiner/karabiner.json".text = builtins.toJSON {
    global.show_in_menu_bar = false;

    profiles = [
      {
        name = "Default";
        selected = true;
        virtual_hid_keyboard.keyboard_type_v2 = "ansi";

        complex_modifications.rules = [
          {
            description = "Right Command → Hyper (⌘⌃⌥⇧)";
            manipulators = [
              {
                type = "basic";
                from = {
                  key_code = "right_command";
                  modifiers.optional = [ "any" ];
                };
                to = [ hyper ];
              }
            ];
          }
          {
            description = "Right Option → Meh (⌃⌥⇧)";
            manipulators = [
              {
                type = "basic";
                from = {
                  key_code = "right_option";
                  modifiers.optional = [ "any" ];
                };
                to = [ meh ];
              }
            ];
          }
        ];
      }
    ];
  };
}
