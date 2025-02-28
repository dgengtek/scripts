default:
    just --list

d:
    nix develop .#impure

b:
    nix build
