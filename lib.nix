{ stdenv, lib, pkgs, poetry2nix }:
rec
{
  python_deps =
    let
      poetry = poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
      overrides = poetry.defaultPoetryOverrides.extend
        (self: super: {
          click = super.click.overridePythonAttrs
            (
              old: {
                buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
              }
            );
        });

    in
    poetry.mkPoetryEnv {
      projectDir = ./.;
      overrides = [ overrides ];
      groups = [ ];
      checkGroups = [ ];
      extras = [ ];
    };
  script_files = lib.fileset.fileFilter (file: (file.hasExt "sh" || file.hasExt "py") && file.name != "install.sh") ./.;
  build =
    stdenv.mkDerivation {
      name = "scripts";
      src = ./.;
      buildInputs = [ python_deps pkgs.findutils pkgs.fd pkgs.jq ];
      installPhase = ''
        mkdir -p $out/bin
        fd -t f -e py -e sh -E install.sh --print0 | xargs --verbose -0 -I {} cp -v {} $out/bin/
      '';
      buildPhase = "true";
    };
}
