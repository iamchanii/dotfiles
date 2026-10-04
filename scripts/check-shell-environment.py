#!/usr/bin/env python3
"""Exercise a built env.nu without activating it or loading the user's config.nu."""

import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

FIELDS = """PATH JAVA_HOME ANDROID_HOME BUN_INSTALL XDG_CACHE_HOME XDG_CONFIG_HOME
XDG_DATA_HOME XDG_STATE_HOME XDG_DATA_DIRS TERMINFO_DIRS MANPATH NIX_PROFILES
NIX_SSL_CERT_FILE DISPLAY WAYLAND_DISPLAY"""
PROBE = f"print ($env | select --optional {' '.join(FIELDS.split())} | to json --raw)"


def nu_string(value):
    # JSON string escapes are also valid in Nushell double-quoted literals.
    return json.dumps(str(value), ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--nu", required=True, type=Path)
    parser.add_argument("--env-file", required=True, type=Path)
    parser.add_argument("--home", default=os.environ["HOME"])
    args = parser.parse_args()
    nu = str(args.nu.absolute())
    env_file = str(args.env_file.absolute())
    source = f"source {nu_string(env_file)}"

    with tempfile.TemporaryDirectory(prefix="check-shell-env-") as directory:
        work = Path(directory)
        empty_config = work / "config.nu"
        empty_config.write_text("", encoding="utf-8")
        base = {"HOME": args.home, "USER": Path(args.home).name,
                "PATH": "/usr/bin:/bin", "TERM": "dumb", "LANG": "C.UTF-8"}

        def run(code=PROBE, *, environment=None, mode="interactive"):
            flags = {
                "interactive": ["--interactive"],
                "login": ["--login"],
                "script": ["--no-config-file"],
            }[mode]
            if mode != "script":
                flags += ["--env-config", env_file, "--config", str(empty_config)]
            result = subprocess.run(
                [nu, *flags, "-c", code], env=base if environment is None else environment,
                cwd=work, stdin=subprocess.DEVNULL, capture_output=True,
                text=True, timeout=30, check=False,
            )
            if result.returncode != 0 or result.stderr:
                raise AssertionError(f"nu exit {result.returncode}: {result.stderr}")
            return json.loads(result.stdout)

        class EnvironmentTests(unittest.TestCase):
            def test_declared_environment_available_before_prompt_config(self):
                state = run()
                for name in ("JAVA_HOME", "ANDROID_HOME"):
                    self.assertTrue(Path(state[name]).is_dir(), name)
                self.assertIn("/nix/var/nix/profiles/default", state["NIX_PROFILES"].split())
                self.assertTrue(Path(state["NIX_SSL_CERT_FILE"]).is_file())
                self.assertIn("/usr/share", state["XDG_DATA_DIRS"].split(":"))
                for value in state.values():
                    if isinstance(value, str):
                        self.assertNotIn("${", value)
                self.assertEqual(len(state["PATH"]), len(set(state["PATH"])))
                self.assertTrue(all(Path(p).is_absolute() for p in state["PATH"]))

            def test_login_nonlogin_and_explicit_script_source_agree(self):
                expected = run()
                self.assertEqual(run(mode="login"), expected)
                self.assertEqual(run(f"{source}; {PROBE}", mode="script"), expected)

            def test_repeated_initialization_and_nested_shell_are_idempotent(self):
                expected = run()
                self.assertEqual(run(f"{source}; {source}; {PROBE}", mode="script"), expected)
                nested = (f"$env.__HM_SESS_VARS_SOURCED = '1'; "
                          f"$env.__ETC_PROFILE_NIX_SOURCED = '1'; "
                          f'let child = (run-external {nu_string(nu)} "--no-config-file" "-c" '
                          f"{nu_string(source + '; ' + PROBE)} | complete); "
                          "if $child.exit_code != 0 { error make {msg: $child.stderr} }; "
                          "print $child.stdout")
                self.assertEqual(run(nested), expected)

            def test_project_and_runtime_overrides_survive(self):
                overrides = {
                    "JAVA_HOME": str(work / "project jdk"),
                    "XDG_CACHE_HOME": str(work / "project-cache"),
                    "DISPLAY": ":99", "WAYLAND_DISPLAY": "wayland-test",
                    "NIX_SSL_CERT_FILE": str(work / "custom-ca.pem"),
                }
                project_path = [str(work / "project-bin"), "/usr/bin", "/bin"]
                state = run(environment=base | overrides | {
                    "PATH": ":".join(project_path + [project_path[0]]),
                    "XDG_DATA_DIRS": "/project/share:/usr/share:/project/share",
                    "MANPATH": "/project/man:",
                })
                for key, value in overrides.items():
                    self.assertEqual(state[key], value, key)
                self.assertEqual(state["PATH"][:3], project_path)
                self.assertEqual(len(state["PATH"]), len(set(state["PATH"])))
                self.assertEqual(state["XDG_DATA_DIRS"].split(":")[:2], ["/project/share", "/usr/share"])
                self.assertEqual(state["MANPATH"].split(":")[:2], ["/project/man", ""])

            def test_empty_defaults_and_missing_path_are_initialized(self):
                for path in (None, ""):
                    with self.subTest(path=path):
                        environment = base | {"JAVA_HOME": "", "BUN_INSTALL": "", "XDG_CACHE_HOME": ""}
                        if path is None:
                            environment.pop("PATH")
                        else:
                            environment["PATH"] = path
                        state = run(environment=environment)
                        self.assertTrue(Path(state["JAVA_HOME"]).is_dir())
                        self.assertTrue(Path(state["BUN_INSTALL"]).is_absolute())
                        self.assertNotIn("", state["PATH"])
                        commands = run("print (which nix bun | get command | to json --raw)",
                                       environment=environment)
                        self.assertEqual(commands, ["nix", "bun"])

            def test_bun_install_and_lookup_paths_agree(self):
                code = "print ({bin: (bun pm bin -g | str trim), path: $env.PATH, root: $env.BUN_INSTALL} | to json --raw)"
                normal = run(code)
                moved_cache = run(code, environment=base | {"XDG_CACHE_HOME": str(work / "other-cache")})
                self.assertEqual(moved_cache["bin"], normal["bin"])
                self.assertIn(normal["bin"], normal["path"])
                root = work / "bun 'custom' = root"
                global_project = root / "install/global"
                global_project.mkdir(parents=True)
                (global_project / "package.json").write_text('{"private": true}', encoding="utf-8")
                custom = run(code, environment=base | {"BUN_INSTALL": str(root)})
                self.assertEqual(custom["root"], str(root))
                self.assertEqual(custom["bin"], str(root / "bin"))
                self.assertIn(custom["bin"], custom["path"])

            def test_nix_evaluation_works_without_parent_initialization(self):
                result = run("print (nix --extra-experimental-features nix-command eval --expr '1 + 1' | into int | to json --raw)")
                self.assertEqual(result, 2)

        result = unittest.TextTestRunner(verbosity=2).run(
            unittest.defaultTestLoader.loadTestsFromTestCase(EnvironmentTests)
        )
        return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
