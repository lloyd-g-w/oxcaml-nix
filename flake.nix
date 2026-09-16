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

        # The oxcaml meta-package has:
        #
        #   dev-repo: "...#main"
        #
        # opam-nix refuses floating git revisions in pure evaluation.
        # Pin it to the commit corresponding to oxcaml 5.2.0minus39.
        patchedOxcamlOpamRepository = pkgs.runCommand "oxcaml-opam-repository-patched" {} ''
          mkdir -p "$out"
          cp -R ${oxcaml-opam-repository}/. "$out/"

          chmod u+w \
            "$out/packages/oxcaml/oxcaml.latest/opam"

          substituteInPlace \
            "$out/packages/oxcaml/oxcaml.latest/opam" \
            --replace-fail \
              'git+https://github.com/oxcaml/oxcaml.git#main' \
              'git+https://github.com/oxcaml/oxcaml.git#2515546fea38e21e8143cc41db663bd56efc8d06'
        '';

        patchScope = scope:
          scope.overrideScope (
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

        oxcamlPackages = names: let
          query =
            {
              ocaml-variants = "5.2.0+ox";
            }
            // builtins.listToAttrs (
              map
              (name: {
                inherit name;
                value = "*";
              })
              names
            );

          scope = patchScope (
            on.queryToScope {
              repos = [
                patchedOxcamlOpamRepository
                opam-repository
              ];
            }
            query
          );
        in
          map
          (name:
            if name == "oxcaml"
            then scope."oxcaml-compiler"
            else scope.${name})
          names;

        oxcaml = builtins.head (
          oxcamlPackages [
            "oxcaml"
          ]
        );
      in {
        lib = {
          inherit oxcamlPackages;
        };

        packages = {
          inherit oxcaml;
          default = oxcaml;
        };
      }
    );
}
