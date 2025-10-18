#!/usr/bin/env python3
"""
sec - A gopass credential management tool for copying and generating credentials.
"""

import argparse
import os
import random
import string
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

# Embedded Neovim configuration content
NVIM_INIT_LUA = """-- Neovim configuration for sec password manager

-- Disable swap, backup, undo files, and shada for gopass temporary files
-- This ensures sensitive password data is not written to disk
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "/dev/shm/gopass*",
	callback = function()
		vim.opt_local.swapfile = false
		vim.opt_local.backup = false
		vim.opt_local.undofile = false
		vim.opt.shada = ""
	end,
})

-- Create commands to generate and insert credentials
vim.api.nvim_create_user_command("SecGenUsername", function()
	-- Generate username and insert at cursor position
	local result = vim.fn.system("sec gen username")
	local username = vim.fn.trim(result)
	vim.api.nvim_put({ username }, "c", true, true)
end, {})

vim.api.nvim_create_user_command("SecGenPassword", function()
	-- Generate password and insert at cursor position
	local result = vim.fn.system("sec gen password")
	local password = vim.fn.trim(result)
	vim.api.nvim_put({ password }, "c", true, true)
end, {})

vim.api.nvim_create_user_command("SecGenPassphrase", function()
	-- Generate passphrase using words and insert at cursor position
	local result = vim.fn.system("sec gen password --words")
	local passphrase = vim.fn.trim(result)
	vim.api.nvim_put({ passphrase }, "c", true, true)
end, {})

-- Set leader key to space
vim.g.mapleader = " "

-- Create key mappings for the commands
-- Delete from cursor to end of line before inserting
vim.keymap.set("n", "<leader>su", "D:SecGenUsername<CR>", { desc = "Generate and insert username" })
vim.keymap.set("n", "<leader>sp", "D:SecGenPassword<CR>", { desc = "Generate and insert password" })
vim.keymap.set("n", "<leader>sw", "D:SecGenPassphrase<CR>", { desc = "Generate and insert passphrase" })

-- Create key mappings for the commands in normal and insert mode
-- Delete from cursor to end of line before inserting
vim.keymap.set("n", "<M-u>", "D:SecGenUsername<CR>", { desc = "Generate and insert username" })
vim.keymap.set("i", "<M-u>", "<Esc>D:SecGenUsername<CR>a", { desc = "Generate and insert username" })

vim.keymap.set("n", "<M-p>", "D:SecGenPassword<CR>", { desc = "Generate and insert password" })
vim.keymap.set("i", "<M-p>", "<Esc>D:SecGenPassword<CR>a", { desc = "Generate and insert password" })

vim.keymap.set("n", "<M-w>", "D:SecGenPassphrase<CR>", { desc = "Generate and insert passphrase" })
vim.keymap.set("i", "<M-w>", "<Esc>D:SecGenPassphrase<CR>a", { desc = "Generate and insert passphrase" })
"""

# Embedded zsh aliases content
ZSH_ALIASES = """# ----- GENERATED SEC ALIASES START -----
alias sa='sec add'
alias sc='sec copy'
alias se='sec edit'
alias sg='sec gen entry'
alias sp='sec practice'
alias ss='sec show'
alias glo='git log --oneline --decorate --graph --all'
alias pwstore="cd $HOME/.local/share/gopass/stores/root"
# ----- GENERATED SEC ALIASES END -----
"""


@dataclass
class CopyArgs:
    """Arguments for the copy command."""

    fields: list[str]
    path: Optional[str] = None


@dataclass
class EditArgs:
    """Arguments for the edit command."""

    path: Optional[str] = None


@dataclass
class GenArgs:
    """Arguments for the gen command."""

    type: str
    path: Optional[str] = None
    words: bool = False


@dataclass
class PracticeArgs:
    """Arguments for the practice command."""

    path: Optional[str] = None


@dataclass
class ShowArgs:
    """Arguments for the show command."""

    path: Optional[str] = None


@dataclass
class AddArgs:
    """Arguments for the add command."""

    path: str


@dataclass
class InstallArgs:
    """Arguments for the install command."""

    target: str


@dataclass
class Args:
    """Top-level arguments container."""

    command: str
    add: Optional[AddArgs] = None
    copy: Optional[CopyArgs] = None
    edit: Optional[EditArgs] = None
    gen: Optional[GenArgs] = None
    install: Optional[InstallArgs] = None
    practice: Optional[PracticeArgs] = None
    show: Optional[ShowArgs] = None


def parse_args() -> Args:
    """Parse command-line arguments into structured dataclasses."""
    parser = argparse.ArgumentParser(
        description="Manage gopass credentials with copy and generate commands"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Add subcommand
    add_parser = subparsers.add_parser("add", help="Add a new credentials entry")
    add_parser.add_argument(
        "path",
        help="Path for the new credentials entry",
    )

    # Copy subcommand
    copy_parser = subparsers.add_parser("copy", help="Copy credentials to clipboard")
    copy_parser.add_argument(
        "--fields",
        "-f",
        type=str,
        default="user_id,password,totp",
        help="Comma-separated field names to copy (default: user_id,password,totp)",
    )

    # Edit subcommand
    edit_parser = subparsers.add_parser("edit", help="Edit a credentials entry")
    edit_parser.add_argument(
        "path",
        nargs="?",
        default=None,
        help="Path to the credentials entry (uses fzf if not provided)",
    )

    # Gen subcommand
    gen_parser = subparsers.add_parser(
        "gen", help="Generate username, password, or complete credentials entry"
    )
    gen_parser.add_argument(
        "type",
        choices=["username", "password", "entry"],
        help="Type of credential to generate",
    )
    gen_parser.add_argument(
        "path",
        nargs="?",
        default=None,
        help="Path for the credentials entry (required for 'entry' type)",
    )
    gen_parser.add_argument(
        "--words",
        "-w",
        action="store_true",
        help="Generate a passphrase using xkcdpass instead of pwgen (for password/entry)",
    )

    # Install subcommand
    install_parser = subparsers.add_parser(
        "install", help="Install configurations (e.g., nvim, zsh)"
    )
    install_parser.add_argument(
        "target",
        choices=["nvim", "zsh"],
        help="Installation target",
    )

    # Practice subcommand
    practice_parser = subparsers.add_parser(
        "practice", help="Practice memorizing a password"
    )
    practice_parser.add_argument(
        "path",
        nargs="?",
        default=None,
        help="Path to the credentials entry (uses fzf if not provided)",
    )

    # Show subcommand
    show_parser = subparsers.add_parser("show", help="Show credentials entry details")
    show_parser.add_argument(
        "path",
        nargs="?",
        default=None,
        help="Path to the credentials entry (uses fzf if not provided)",
    )

    parsed = parser.parse_args()

    # Build structured Args based on command
    match parsed.command:
        case "add":
            return Args(command="add", add=AddArgs(path=parsed.path))
        case "copy":
            fields_list = [f.strip() for f in parsed.fields.split(",")]
            return Args(command="copy", copy=CopyArgs(fields=fields_list))
        case "edit":
            return Args(command="edit", edit=EditArgs(path=parsed.path))
        case "gen":
            return Args(
                command="gen",
                gen=GenArgs(type=parsed.type, path=parsed.path, words=parsed.words),
            )
        case "install":
            return Args(command="install", install=InstallArgs(target=parsed.target))
        case "practice":
            return Args(command="practice", practice=PracticeArgs(path=parsed.path))
        case "show":
            return Args(command="show", show=ShowArgs(path=parsed.path))
        case _:
            return Args(command=parsed.command)


def select_path_with_fzf() -> Optional[str]:
    """Prompt user to select a gopass path using fzf."""
    # Get list of gopass paths
    gopass_list = subprocess.run(
        ["gopass", "ls", "--flat"],
        capture_output=True,
        text=True,
        check=True,
    )

    # Pipe to fzf for selection
    fzf_result = subprocess.run(
        ["fzf"],
        input=gopass_list.stdout,
        capture_output=True,
        text=True,
    )

    # Return selected path, stripping whitespace
    selected = fzf_result.stdout.strip()
    return selected if selected else None


def has_totp_key(path: str) -> bool:
    """Check if a gopass entry has a totp key configured."""
    try:
        # Check if totp field exists - returns non-zero if not present
        subprocess.run(
            ["gopass", "show", path, "totp"],
            capture_output=True,
            check=True,
        )
        return True
    except subprocess.CalledProcessError:
        return False


def copy_field_to_clipboard(args: Args, field: str) -> bool:
    """Copy a field from gopass directly to clipboard."""
    assert args.copy is not None
    assert args.copy.path is not None

    try:
        # Use gopass's built-in clipboard functionality
        match field.lower():
            case "password":
                subprocess.run(
                    ["gopass", "show", "-c", args.copy.path],
                    check=True,
                )
            case "totp":
                # Check if totp key exists before attempting to copy
                if not has_totp_key(args.copy.path):
                    return False
                subprocess.run(
                    ["gopass", "totp", "-c", args.copy.path],
                    check=True,
                )
            case _:
                subprocess.run(
                    ["gopass", "show", "-c", args.copy.path, field],
                    check=True,
                )
        return True

    except subprocess.CalledProcessError:
        print(
            f"Error: Could not copy field '{field}' from {args.copy.path}",
            file=sys.stderr,
        )
        return False


def add_credentials(args: Args):
    """Create a new empty credentials entry and open it in the editor."""
    assert args.add is not None

    # Create an empty credentials entry
    subprocess.run(
        ["gopass", "insert", "-m", args.add.path],
        input="",
        text=True,
        check=True,
    )

    # Open in editor for user to fill in
    subprocess.run(
        ["gopass", "edit", args.add.path],
        check=True,
    )


def copy_credentials(args: Args):
    """Copy credentials to clipboard in sequence."""
    assert args.copy is not None

    # Select path if not provided
    if not args.copy.path:
        args.copy.path = select_path_with_fzf()

    if not args.copy.path:
        print("No path selected. Exiting.", file=sys.stderr)
        return

    # Copy each field in sequence
    for i, field in enumerate(args.copy.fields):
        if copy_field_to_clipboard(args, field):
            print(f"Copied '{field}' to clipboard")

        # Wait for Enter before copying next field (except for last field)
        if i < len(args.copy.fields) - 1:
            input("Press Enter to copy next field...")


def generate_random_user_id() -> str:
    """Generate a random user_id: 5 chars from [a-z0-9] with at most 1 number."""
    # Start with 5 lowercase letters
    chars = random.choices(string.ascii_lowercase, k=5)

    # Randomly decide if we include a number (50% chance)
    if random.choice([True, False]):
        # Replace a random position with a number
        position = random.randint(0, 4)
        chars[position] = random.choice(string.digits)

    return "".join(chars)


def generate_password(use_words: bool) -> str:
    """Generate a password using pwgen or xkcdpass."""
    if use_words:
        # Generate 20-word passphrase using xkcdpass
        result = subprocess.run(
            ["xkcdpass", "-n", "20"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()

    # Generate random length between 20-30
    length = random.randint(20, 30)
    result = subprocess.run(
        [
            "pwgen",
            str(length),
            "1",
            "--secure",
            "--capitalize",
            "--numerals",
            "--symbols",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def generate_credentials_file(path: str, use_words: bool):
    """Generate a new gopass credentials entry with random user_id and password."""
    user_id = generate_random_user_id()
    password = generate_password(use_words)

    # Create the credentials content
    content = f"{password}\nuser_id: {user_id}\n"

    # Insert into gopass using echo and pipe
    subprocess.run(
        ["gopass", "insert", "-m", path],
        input=content,
        text=True,
        check=True,
    )

    print(f"Created credentials at: {path}")

    # Open in editor for further customization
    subprocess.run(
        ["gopass", "edit", path],
        check=True,
    )


def edit_credentials(args: Args):
    """Edit a credentials entry in the editor."""
    assert args.edit is not None

    # Select path if not provided
    if not args.edit.path:
        args.edit.path = select_path_with_fzf()

    if not args.edit.path:
        print("No path selected. Exiting.", file=sys.stderr)
        return

    # Open the credentials entry in the editor
    subprocess.run(
        ["gopass", "edit", args.edit.path],
        check=True,
    )


def gen_and_copy(args: Args):
    """Generate username, password, or complete credentials entry."""
    assert args.gen is not None

    # Generate the credential based on type
    match args.gen.type:
        case "entry":
            # Handle entry type separately - it doesn't copy to clipboard
            if not args.gen.path:
                print("Error: path is required for 'entry' type", file=sys.stderr)
                sys.exit(1)
            generate_credentials_file(args.gen.path, args.gen.words)
            return
        case "username":
            credential = generate_random_user_id()
            # Print credential to stdout for capture, message to stderr
            print(credential)
        case "password":
            credential = generate_password(args.gen.words)
            # Print credential to stdout for capture, message to stderr
            print(credential)
        case _:
            raise ValueError(f"Unknown type: {args.gen.type}")

    # Copy to clipboard using xclip
    subprocess.run(
        ["xclip", "-selection", "clipboard"],
        input=credential,
        text=True,
        check=True,
    )


def practice_password(args: Args):
    """Practice memorizing a password by repeatedly entering it."""
    assert args.practice is not None

    # Select path if not provided
    if not args.practice.path:
        args.practice.path = select_path_with_fzf()

    if not args.practice.path:
        print("No path selected. Exiting.", file=sys.stderr)
        return

    # Retrieve the password from gopass
    try:
        result = subprocess.run(
            ["gopass", "show", "--password", args.practice.path],
            capture_output=True,
            text=True,
            check=True,
        )
        actual_password = result.stdout.strip()
    except subprocess.CalledProcessError:
        print(
            f"Error: Could not retrieve password from {args.practice.path}",
            file=sys.stderr,
        )
        return

    # Practice loop - continue until user enters correct password
    print(f"Practice mode for: {args.practice.path}")
    print("Type 'show' to reveal the password, or enter the password to check.")

    try:
        while True:
            user_input = input("Enter password: ")

            # Check if user wants to see the password
            if user_input == "show":
                print(f"Password: {actual_password}")
                continue

            # Check if the entered password matches
            if user_input == actual_password:
                print("Success! Password correct.")
                break
            else:
                print("Incorrect. Try again.")
    except KeyboardInterrupt:
        print("\nPractice cancelled.")
        return


def show_credentials(args: Args):
    """Display credentials entry using gopass show."""
    assert args.show is not None

    # Select path if not provided
    if not args.show.path:
        args.show.path = select_path_with_fzf()

    if not args.show.path:
        print("No path selected. Exiting.", file=sys.stderr)
        return

    # Display the credentials entry using gopass show
    subprocess.run(
        ["gopass", "show", args.show.path],
        check=True,
    )


def install_nvim(args: Args):
    """Install neovim configuration for sec."""
    assert args.install is not None

    # Determine neovim config directory
    config_dir = Path.home() / ".config" / "nvim"
    init_lua_path = config_dir / "init.lua"
    init_vim_path = config_dir / "init.vim"

    # Check if either init file already exists
    if init_lua_path.exists() or init_vim_path.exists():
        print(
            "Error: Neovim configuration file already exists. Please back it up or remove it before installing.",
            file=sys.stderr,
        )
        sys.exit(1)

    # Create config directory if it doesn't exist
    config_dir.mkdir(parents=True, exist_ok=True)

    # Write the init.lua file
    init_lua_path.write_text(NVIM_INIT_LUA)

    print(f"Successfully installed neovim configuration to {init_lua_path}")


def install_zsh(args: Args):
    """Install zsh aliases for sec into .zshrc."""
    assert args.install is not None

    # Determine .zshrc path
    zshrc_path = Path.home() / ".zshrc"

    # Check if aliases already exist by looking for the start marker
    if zshrc_path.exists():
        content = zshrc_path.read_text()
        if "# ----- GENERATED SEC ALIASES START -----" in content:
            print("sec aliases already installed in .zshrc", file=sys.stderr)
            return

    # Append aliases to .zshrc
    with open(zshrc_path, "a") as f:
        f.write("\n" + ZSH_ALIASES)

    print(f"Successfully installed sec aliases to {zshrc_path}. Reload your shell.")


def main():
    """Main entry point for the sec script."""
    args = parse_args()

    match args.command:
        case "add":
            add_credentials(args)
        case "copy":
            copy_credentials(args)
        case "edit":
            edit_credentials(args)
        case "gen":
            gen_and_copy(args)
        case "install":
            # Route to appropriate install function based on target
            assert args.install is not None
            match args.install.target:
                case "nvim":
                    install_nvim(args)
                case "zsh":
                    install_zsh(args)
                case _:
                    raise ValueError(f"Unknown install target: {args.install.target}")
        case "practice":
            practice_password(args)
        case "show":
            show_credentials(args)
        case _:
            raise ValueError(f"Unknown command: {args.command}")


if __name__ == "__main__":
    main()
