# Home Manager의 POSIX 초기화는 Bash에서 평가하고 선언된 환경만 가져온다.
# 상속한 값은 명시적인 사용자/프로젝트 설정으로 취급한다.
do --env {
  let session = (run-external @bash@ "--noprofile" "--norc" @loader@ | complete)
  if $session.exit_code != 0 {
    error make {msg: $"Session environment initialization failed: ($session.stderr | str trim)"}
  }
  if ($session.stderr | is-not-empty) {
    print --stderr ($session.stderr | str trim)
  }

  let search_vars = @searchVars@
  let entries = (
    $session.stdout
    | split row (char nul)
    | where {|entry| $entry != "" }
    | parse --regex '(?s)^(?<name>[^=]+)=(?<value>.*)$'
  )
  for entry in $entries {
    let inherited = ($env | get --optional $entry.name)
    if $entry.name in $search_vars {
      let previous = if $inherited == null {
        []
      } else if ($inherited | describe) == "string" {
        $inherited | split row (char esep)
      } else {
        $inherited
      }
      let paths = ($previous | append ($entry.value | split row (char esep)) | uniq)
      if $entry.name == "PATH" {
        # 빈 PATH 항목은 현재 디렉터리를 실행 경로로 만들므로 가져오지 않는다.
        load-env {PATH: ($paths | where {|path| $path != "" })}
      } else {
        # MANPATH 등의 빈 항목은 시스템 기본 검색 경로라는 의미를 보존한다.
        load-env {($entry.name): ($paths | str join (char esep))}
      }
    } else if $inherited == null or $inherited == "" {
      load-env {($entry.name): $entry.value}
    }
  }
}
