{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    oxcaml-nix.url = "github:lloyd-g-w/oxcaml-nix";
  };

  outputs = {
    nixpkgs,
    oxcaml-nix,
    ...
  }: let
    system = "x86_64-linux";

    pkgs = nixpkgs.legacyPackages.${system};

    oxpkgs = oxcaml-nix.lib.${system}.oxcamlPackages [
      "oxcaml"
      "dune"
      "tsdl"
      "odoc"
    ];
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        oxpkgs.oxcaml
        oxpkgs.dune
        oxpkgs.tsdl
        oxpkgs.odoc
      ];
    };
  };
}
