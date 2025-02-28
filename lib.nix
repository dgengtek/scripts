{ stdenv, lib, pkgs, python_env }:
{
  script_files = lib.fileset.fileFilter (file: (file.hasExt "sh" || file.hasExt "py") && file.name != "install.sh") ./.;
  build =
    stdenv.mkDerivation {
      name = "scripts";
      src = ./.;
      buildInputs = [ python_env pkgs.findutils pkgs.fd pkgs.jq ];
      installPhase = ''
        mkdir -p $out/bin
        fd -t f -e py -e sh -E install.sh --print0 | xargs --verbose -0 -I {} cp -v {} $out/bin/
      '';
      buildPhase = "true";
    };
}
