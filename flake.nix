{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    poetry2nix.url = "github:nix-community/poetry2nix";
  };
  outputs = { self, nixpkgs, poetry2nix }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { config = { }; overlays = [ ]; inherit system; };
      lib = pkgs.callPackage ./lib.nix { inherit poetry2nix; };
    in
    {
      packages.${system}.default = lib.build;
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.stow
          pkgs.python3
        ];
      };
      inherit lib;
    };
}
