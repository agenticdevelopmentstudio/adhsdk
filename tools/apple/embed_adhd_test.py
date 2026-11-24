#!/usr/bin/env python3
"""embed_adhd.py: the stamp, the configuration, and how a missing dependency fails.

    python3 -m pytest tools/apple/embed_adhd_test.py -q

Nothing here runs xcodebuild, xcodegen, git, otool or codesign: every command
goes through a fake runner. The dependency closure itself is the toolkit's
`embed_transitive_frameworks.py`, tested in the toolkit
(`embed_transitive_frameworks_test.py`); these tests pin that embed_adhd hands
it the right directories and surfaces its failures.
"""

from __future__ import annotations

import fcntl
import subprocess
import sys
import tempfile
import threading
import unittest
from pathlib import Path
from typing import Sequence
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

import embed_adhd  # noqa: E402


class FakeRunner:
    """Records every command and answers by its program name. `xcodebuild`
    drops an `adhd` into the products directory, as a real build would."""

    def __init__(self, products: Path, head: str = "abc123", embedder_exit: int = 0,
                 embedder_stderr: str = "", nested: Sequence[Path] = ()):
        self.products = products
        self.head = head
        # The nested submodules `git submodule foreach --recursive pwd` names.
        self.nested = list(nested)
        self.embedder_exit = embedder_exit
        self.embedder_stderr = embedder_stderr
        self.commands: list[list[str]] = []

    def __call__(self, command, **_kwargs):
        self.commands.append(list(command))
        program = Path(command[0]).name
        stdout, stderr, code = "", "", 0
        if program == "git" and "rev-parse" in command:
            stdout = self.head + "\n"
        elif program == "git" and "ls-files" in command:
            # Untracked files, as git would list them: every file under the
            # repository that is not inside a nested repository.
            root = Path(command[2])
            inner = [n for n in self.nested if n != root and n.is_relative_to(root)]
            names = [str(f.relative_to(root)) for f in sorted(root.rglob("*"))
                     if f.is_file() and not any(f.is_relative_to(n) for n in inner)]
            stdout = "".join(name + "\0" for name in names)
        elif program == "git" and "pwd" in command:
            stdout = "".join(f"{n}\n" for n in self.nested)
        elif program == "xcodebuild":
            self.products.mkdir(parents=True, exist_ok=True)
            (self.products / "adhd").write_text("binary")
        elif command[1:2] and command[1].endswith("embed_transitive_frameworks.py"):
            code, stderr = self.embedder_exit, self.embedder_stderr
        return subprocess.CompletedProcess(command, code, stdout, stderr)

    def ran(self, program: str) -> list[list[str]]:
        return [c for c in self.commands if Path(c[0]).name == program]


class EmbedAdhdTestCase(unittest.TestCase):
    def setUp(self):
        self.temp = Path(tempfile.mkdtemp())
        self.repo = self.temp / "kitchen"
        (self.repo / embed_adhd.PROJECT_DIR).mkdir(parents=True)
        (self.repo / embed_adhd.PROJECT_DIR / "project.yml").write_text("name: ADHDaemon\n")
        self.checkout = embed_adhd.Checkout(self.repo, "adkitchen")
        self.home = self.temp / "home"
        self.patch = mock.patch.object(Path, "home", return_value=self.home)
        self.patch.start()
        self.addCleanup(self.patch.stop)
        self.xcodegen = self.make_tool(self.temp / "tools" / "xcodegen")

    @staticmethod
    def make_tool(path: Path) -> Path:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("#!/bin/sh\n")
        path.chmod(0o755)
        return path

    def environ(self, configuration: str = "Debug") -> dict[str, str]:
        return {
            "XCODEGEN": str(self.xcodegen),
            "CONFIGURATION": configuration,
            "TARGET_BUILD_DIR": str(self.temp / "Products" / configuration),
            "WRAPPER_NAME": "Kitchen.app",
            "DERIVED_FILE_DIR": str(self.temp / "DerivedSources"),
            "EXPANDED_CODE_SIGN_IDENTITY": "ABCDEF",
            "HOME": str(self.home),
            "SDKROOT": "/should/not/leak",
        }

    def runner(self, configuration: str = "Debug", **kwargs) -> FakeRunner:
        return FakeRunner(embed_adhd.products_directory(self.checkout, configuration), **kwargs)

    def embed(self, configuration: str = "Debug", **kwargs) -> Path:
        return embed_adhd.embed_adhd(self.environ(configuration), self.checkout, **kwargs)


class ConfigurationTests(EmbedAdhdTestCase):
    def test_the_configuration_is_passed_through(self):
        runner = self.runner("Release")
        self.embed("Release", runner=runner)
        [build] = runner.ran("xcodebuild")
        self.assertEqual(build[build.index("-configuration") + 1], "Release")
        self.assertEqual(build[build.index("-scheme") + 1], "adhd")

    def test_the_build_gets_its_own_derived_data_and_no_xcode_settings(self):
        runner = self.runner()
        env_seen = {}

        def capture(command, **kwargs):
            if Path(command[0]).name == "xcodebuild":
                env_seen.update(kwargs.get("env") or {})
            return runner(command, **kwargs)

        self.embed(runner=capture)
        [build] = runner.ran("xcodebuild")
        derived = build[build.index("-derivedDataPath") + 1]
        self.assertIn("ADHDaemon-adkitchen-", derived)
        self.assertNotIn("SDKROOT", env_seen)
        self.assertEqual(env_seen["HOME"], str(self.home))

    def test_the_app_names_the_folder(self):
        other = embed_adhd.Checkout(self.repo, "stenographer")
        self.assertIn("ADHDaemon-stenographer-", str(embed_adhd.adhd_derived_data(other)))
        self.assertNotEqual(embed_adhd.adhd_derived_data(other), embed_adhd.adhd_derived_data(self.checkout))


class StampTests(EmbedAdhdTestCase):
    def test_an_unchanged_submodule_is_not_rebuilt(self):
        first = self.runner()
        self.embed(runner=first)
        self.assertEqual(len(first.ran("xcodebuild")), 1)
        second = self.runner()
        self.embed(runner=second)
        self.assertEqual(second.ran("xcodebuild"), [])
        self.assertEqual(second.ran("xcodegen"), [])

    def test_a_new_head_rebuilds(self):
        self.embed(runner=self.runner(head="one"))
        again = self.runner(head="two")
        self.embed(runner=again)
        self.assertEqual(len(again.ran("xcodebuild")), 1)

    def submodule(self) -> Path:
        return self.repo / embed_adhd.SUBMODULE

    def test_an_edit_to_an_untracked_file_rebuilds(self):
        """f4: porcelain status names an untracked file but never reads it."""
        new_file = self.submodule() / "Sources/NewThing.swift"
        new_file.parent.mkdir(parents=True)
        new_file.write_text("let one = 1\n")
        self.embed(runner=self.runner())
        new_file.write_text("let one = 2\n")
        again = self.runner()
        self.embed(runner=again)
        self.assertEqual(len(again.ran("xcodebuild")), 1)

    def test_an_edit_to_an_untracked_file_in_a_nested_submodule_rebuilds(self):
        nested = self.submodule() / "external/adhsdk"
        deeper = nested / "external/agenticdaemon"
        deeper.mkdir(parents=True)
        new_file = deeper / "Thing.swift"
        new_file.write_text("a\n")
        self.embed(runner=self.runner(nested=[nested, deeper]))
        new_file.write_text("b\n")
        again = self.runner(nested=[nested, deeper])
        self.embed(runner=again)
        self.assertEqual(len(again.ran("xcodebuild")), 1)
        listed = [Path(c[2]) for c in again.ran("git") if "ls-files" in c]
        self.assertEqual(listed, [self.submodule(), nested, deeper])

    def test_unchanged_untracked_files_do_not_rebuild(self):
        new_file = self.submodule() / "Notes.txt"
        new_file.write_text("same\n")
        self.embed(runner=self.runner())
        again = self.runner()
        self.embed(runner=again)
        self.assertEqual(again.ran("xcodebuild"), [])

    def test_another_configuration_rebuilds(self):
        self.embed("Debug", runner=self.runner("Debug"))
        release = self.runner("Release")
        self.embed("Release", runner=release)
        self.assertEqual(len(release.ran("xcodebuild")), 1)


class SharedFolderTests(EmbedAdhdTestCase):
    """f3: the products folder is shared by every target and run that builds
    into it, so the stamp lives beside the products, and two main checkouts
    never share one folder."""

    def test_the_stamp_lives_beside_the_products_not_in_the_targets_folder(self):
        self.embed(runner=self.runner())
        stamp = embed_adhd.stamp_path(self.checkout, "Debug")
        self.assertTrue(stamp.is_relative_to(embed_adhd.adhd_derived_data(self.checkout)))
        self.assertTrue(stamp.exists())
        self.assertFalse((self.temp / "DerivedSources").exists())

    def test_a_build_from_other_sources_into_the_folder_is_not_trusted(self):
        self.embed(runner=self.runner(head="one"))
        # Someone else (another target, another run) builds other sources
        # into the same folder, and so rewrites the stamp beside it.
        self.embed(runner=self.runner(head="two"))
        again = self.runner(head="one")
        self.embed(runner=again)
        self.assertEqual(len(again.ran("xcodebuild")), 1)

    def test_a_failed_build_leaves_no_stamp_vouching_for_the_products(self):
        self.embed(runner=self.runner(head="one"))
        failing = self.runner(head="two")

        def fail_build(command, **kwargs):
            if Path(command[0]).name == "xcodebuild":
                return subprocess.CompletedProcess(command, 65, "", "error: boom")
            return failing(command, **kwargs)

        with self.assertRaises(embed_adhd.EmbedError):
            self.embed(runner=fail_build)
        self.assertFalse(embed_adhd.stamp_path(self.checkout, "Debug").exists())

    def test_two_main_checkouts_get_two_folders(self):
        other = self.temp / "elsewhere" / "kitchen"
        other.mkdir(parents=True)
        (self.repo / ".git").mkdir()
        (other / ".git").mkdir()
        mine, theirs = embed_adhd.worktree_token(self.repo), embed_adhd.worktree_token(other)
        self.assertTrue(mine.startswith("managed-"))
        self.assertNotEqual(mine, theirs)
        self.assertEqual(mine, embed_adhd.worktree_token(self.repo), "the token is stable")

    def test_a_worktree_keeps_its_directory_name(self):
        (self.repo / ".git").write_text("gitdir: /somewhere/.git/worktrees/kitchen\n")
        self.assertEqual(embed_adhd.worktree_token(self.repo), "kitchen")

    def test_a_submodule_checkout_is_not_a_worktree(self):
        """A submodule's `.git` is a file too, pointing into `.git/modules`;
        it gets a main checkout's hashed token, not its directory's name."""
        (self.repo / ".git").write_text("gitdir: ../.git/modules/kitchen\n")
        token = embed_adhd.worktree_token(self.repo)
        self.assertTrue(token.startswith("managed-"), token)

    def test_a_git_file_with_no_gitdir_line_is_not_a_worktree(self):
        (self.repo / ".git").write_text("nonsense\n")
        self.assertTrue(embed_adhd.worktree_token(self.repo).startswith("managed-"))


class XcodegenTests(EmbedAdhdTestCase):
    """f9: an Xcode build phase does not inherit the user's shell PATH."""

    def shell_answering(self, path: str, banner: str = ""):
        calls: list[list[str]] = []

        def runner(command, **kwargs):
            calls.append(list(command))
            return subprocess.CompletedProcess(command, 0, f"{banner}\n{path}", "")

        return runner, calls

    def test_the_override_wins(self):
        runner, calls = self.shell_answering("/nowhere")
        self.assertEqual(embed_adhd.resolve_xcodegen({"XCODEGEN": str(self.xcodegen)}, runner=runner),
                         str(self.xcodegen))
        self.assertEqual(calls, [], "the login shell is not asked when the override is set")

    def test_an_override_that_is_not_executable_is_named(self):
        with self.assertRaises(embed_adhd.EmbedError) as caught:
            embed_adhd.resolve_xcodegen({"XCODEGEN": str(self.temp / "missing")})
        self.assertIn("XCODEGEN=", str(caught.exception))

    def test_the_login_shell_path_is_searched(self):
        mint = self.make_tool(self.temp / "mint/bin/xcodegen")
        runner, calls = self.shell_answering(f"/usr/bin:{mint.parent}", banner="Welcome!")
        found = embed_adhd.resolve_xcodegen({"SHELL": "/bin/zsh", "HOME": str(self.home)}, runner=runner)
        self.assertEqual(found, str(mint))
        self.assertEqual(calls[0][:3], ["/bin/zsh", "-l", "-c"])

    def test_the_fixed_directories_are_the_last_resort(self):
        fallback = self.make_tool(self.temp / "brew/bin/xcodegen")
        runner, _ = self.shell_answering("/usr/bin")
        with mock.patch.object(embed_adhd, "XCODEGEN_FALLBACK_DIRECTORIES", (str(fallback.parent),)):
            self.assertEqual(embed_adhd.resolve_xcodegen({"SHELL": "/bin/zsh"}, runner=runner), str(fallback))

    def test_a_missing_xcodegen_is_named_with_where_it_was_looked_for(self):
        runner, _ = self.shell_answering("/usr/bin")
        with mock.patch.object(embed_adhd, "XCODEGEN_FALLBACK_DIRECTORIES", (str(self.temp / "empty"),)):
            with self.assertRaises(embed_adhd.EmbedError) as caught:
                embed_adhd.resolve_xcodegen({"SHELL": "/bin/zsh"}, runner=runner)
        message = str(caught.exception)
        self.assertIn("xcodegen not found", message)
        self.assertIn("XCODEGEN", message)
        self.assertIn("/usr/bin", message)

    def test_the_build_runs_the_resolved_xcodegen(self):
        runner = self.runner()
        self.embed(runner=runner)
        [generate] = runner.ran("xcodegen")
        self.assertEqual(generate, [str(self.xcodegen), "generate"])


class LockTests(EmbedAdhdTestCase):
    """f5: App's and ADNotes' phases share adhd's DerivedData and may run at
    once; the build and the copy happen under an exclusive lock."""

    def lock_is_held(self) -> bool:
        with embed_adhd.lock_path(self.checkout).open("a") as other:
            try:
                fcntl.flock(other, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return True
            fcntl.flock(other, fcntl.LOCK_UN)
            return False

    def test_the_build_and_the_copy_run_under_the_lock(self):
        runner = self.runner()
        held: dict[str, bool] = {}

        def watching(command, **kwargs):
            program = Path(command[0]).name
            if program in ("xcodebuild", "codesign"):
                held[program] = self.lock_is_held()
            return runner(command, **kwargs)

        self.embed(runner=watching)
        self.assertEqual(held, {"xcodebuild": True, "codesign": True})
        self.assertFalse(self.lock_is_held(), "the lock is released afterwards")

    def test_a_second_phase_waits_for_the_first(self):
        order: list[str] = []
        first_building = threading.Event()
        release_first = threading.Event()
        first = self.runner()

        def slow(command, **kwargs):
            if Path(command[0]).name == "xcodebuild":
                order.append("first build starts")
                first_building.set()
                release_first.wait(5)
                order.append("first build ends")
            return first(command, **kwargs)

        builder = threading.Thread(target=self.embed,
                                   kwargs={"runner": slow})
        builder.start()
        self.assertTrue(first_building.wait(5))
        second = self.runner()

        def recording(command, **kwargs):
            if Path(command[0]).name == "git" and "rev-parse" in command:
                order.append("second starts")
            return second(command, **kwargs)

        waiter = threading.Thread(target=self.embed,
                                  kwargs={"runner": recording})
        waiter.start()
        waiter.join(0.3)
        self.assertTrue(waiter.is_alive(), "the second phase is waiting on the lock")
        release_first.set()
        builder.join(5)
        waiter.join(5)
        self.assertEqual(order[:3], ["first build starts", "first build ends", "second starts"])
        self.assertEqual(second.ran("xcodebuild"), [], "the second reuses the first's products")


class CopyTests(EmbedAdhdTestCase):
    def test_the_daemon_lands_in_contents_library_adhd_and_is_signed(self):
        runner = self.runner()
        daemon = self.embed(runner=runner)
        self.assertEqual(daemon, self.temp / "Products/Debug/Kitchen.app/Contents/Library/adhd/adhd")
        self.assertTrue(daemon.exists())
        [embedder] = [c for c in runner.commands if c[1:2] and c[1].endswith("embed_transitive_frameworks.py")]
        self.assertEqual(embedder[2:], [str(daemon.parent),
                                        str(embed_adhd.products_directory(self.checkout, "Debug"))])
        self.assertEqual(Path(embedder[1]), embed_adhd.TRANSITIVE_EMBEDDER)
        self.assertTrue(embed_adhd.TRANSITIVE_EMBEDDER.exists(), "the embedder is the toolkit script beside this one")
        signed = runner.ran("codesign")
        self.assertEqual(signed[-1][-1], str(daemon))
        self.assertIn("ABCDEF", signed[-1])

    def test_a_missing_dependency_fails_with_its_name(self):
        runner = self.runner(embedder_exit=1,
                             embedder_stderr="error: GRDB.framework not found in /products\n")
        with self.assertRaises(embed_adhd.EmbedError) as caught:
            self.embed(runner=runner)
        self.assertIn("GRDB.framework", str(caught.exception))
        self.assertEqual(runner.ran("codesign"), [])

    def test_a_missing_build_setting_fails(self):
        environ = self.environ()
        del environ["WRAPPER_NAME"]
        with self.assertRaises(embed_adhd.EmbedError) as caught:
            embed_adhd.embed_adhd(environ, self.checkout, runner=self.runner())
        self.assertIn("WRAPPER_NAME", str(caught.exception))


class CommandLineTests(unittest.TestCase):
    def test_the_checkout_and_the_app_are_read_in_either_order(self):
        one = embed_adhd.parse_checkout(["embed", "--repo", "/src/kitchen", "--app", "adkitchen"])
        two = embed_adhd.parse_checkout(["embed", "--app", "adkitchen", "--repo", "/src/kitchen"])
        self.assertEqual(one, two)
        self.assertEqual(one.app, "adkitchen")

    def test_a_missing_or_unknown_argument_is_usage(self):
        for argv in (["embed"], ["embed", "--repo", "/src"], ["build", "--repo", "/src", "--app", "x"],
                     ["embed", "--repo", "/src", "--name", "x"], ["embed", "--repo", "/src", "--app", ""]):
            self.assertIsNone(embed_adhd.parse_checkout(argv), argv)
            self.assertEqual(embed_adhd.main(argv), 2)


if __name__ == "__main__":
    unittest.main()
