{
  description = "Catalog backend";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    flake-utils,
    nixpkgs,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.actionlint
            pkgs.deno
            pkgs.pgformatter
            pkgs.postgres-language-server
            pkgs.postgresql
            pkgs.supabase-cli
          ];
        };
        formatter = pkgs.alejandra;
      }
    );
}
