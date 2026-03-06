let
  sources = import ./npins;
  pkgs = import sources.nixpkgs { };
  treefmt = import sources.treefmt-nix;
in
treefmt.mkWrapper pkgs {
  projectRootFile = ".git/config";
  programs = {
    nixfmt = {
      enable = true;
      strict = true;
    };
  };
}
