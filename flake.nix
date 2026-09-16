{
  description = "OxCaml package set";

  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
    flake-utils.url = "github:numtide/flake-utils";

    oxcaml-opam-repository = {
      url = "github:oxcaml/opam-repository/bb4555262936283daf5cbc82423509d4e7069b15";
      flake = false;
    };

    opam-repository = {
      url = "github:ocaml/opam-repository";
      flake = false;
    };
  };

  outputs = {
    self,
    opam-nix,
    flake-utils,
    oxcaml-opam-repository,
    opam-repository,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        on = opam-nix.lib.${system};

        scope =
          on.queryToScope {
            repos = [
              oxcaml-opam-repository
              opam-repository
            ];
          } {
            ocaml-variants = "5.2.0+ox";
            dune = "3.22.2+ox";
          };
      in {
        packages = {
          dune = scope.dune;
          default = scope.dune;
        };

        legacyPackages = scope;
      }
    );
}
