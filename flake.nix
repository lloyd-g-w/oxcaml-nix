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

        pkgs =
          opam-nix.inputs.nixpkgs.legacyPackages.${system};

        baseScope =
          on.queryToScope {
            repos = [
              oxcaml-opam-repository
              opam-repository
            ];
          } {
            ocaml-variants = "*";
            oxcaml = "*";
            dune = "*";

            tsdl = "*";
            ctypes = "*";

            ocamlformat = "*";
            merlin = "*";
            ocaml-lsp-server = "*";
            utop = "*";
            parallel = "*";
            core_unix = "*";
            odoc = "*";
          };

        scope = baseScope.overrideScope (
          final: prev: {
            "oxcaml-compiler" = prev."oxcaml-compiler".overrideAttrs (old: {
              nativeBuildInputs =
                (old.nativeBuildInputs or [])
                ++ [
                  pkgs.autoconf
                  pkgs.rsync
                ];

              postPatch =
                (old.postPatch or "")
                + ''
                  substituteInPlace Makefile Makefile.ox \
                    --replace-fail \
                      "SHELL = /usr/bin/env bash" \
                      "SHELL = ${pkgs.bash}/bin/bash"
                '';
            });
          }
        );
      in {
        legacyPackages = scope;

        packages = {
          oxcaml = scope.oxcaml;
          dune = scope.dune;
          tsdl = scope.tsdl;
          ctypes = scope.ctypes;
          ctypes-foreign = scope.ctypes-foreign;
          odoc = scope.odoc;
          default = scope.oxcaml;
        };
      }
    );
}
