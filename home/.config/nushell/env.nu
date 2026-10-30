# 로그인 셸인 Nushell 은 macOS path_helper(/etc/paths)와 POSIX profile 을 거치지 않으므로
# 공통 경로와 세션 변수를 여기서 직접 구성한다. 상속한 PATH 순서는 유지하고 누락분만 보충한다.
$env.CARGO_HOME = ($env.CARGO_HOME? | default ($nu.home-path | path join ".cargo"))
$env.BUN_INSTALL = ($env.BUN_INSTALL? | default ($nu.home-path | path join ".bun"))

let extra_paths = [
    ($nu.home-path | path join ".local/bin")
    ($env.BUN_INSTALL | path join "bin")
    ($env.CARGO_HOME | path join "bin")
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
]

$env.PATH = ($env.PATH | split row (char esep) | append $extra_paths | uniq)

$env.HOMEBREW_PREFIX = "/opt/homebrew"
$env.HOMEBREW_CELLAR = "/opt/homebrew/Cellar"
$env.HOMEBREW_REPOSITORY = "/opt/homebrew"

# mise 와 starship 초기화 스크립트를 생성해 두고 config.nu 에서 불러온다.
let mise_path = $nu.default-config-dir | path join mise.nu
^mise activate nu | save $mise_path --force
let autoload = $nu.data-dir | path join vendor autoload
mkdir $autoload
^mise exec starship -- starship init nu | save ($autoload | path join starship.nu) --force
