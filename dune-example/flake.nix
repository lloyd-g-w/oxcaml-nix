{
  description = "Dune from OxCaml package set";

  inputs = {
    oxcamlPackages.url = "path:..";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    oxcamlPackages,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        ox = oxcamlPackages.legacyPackages.${system};
      in {
        packages.default = ox.dune;
      }
    );
}
