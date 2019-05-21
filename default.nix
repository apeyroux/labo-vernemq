with import <nixpkgs> {};

let
  drv = (haskellPackages.override {
    overrides = haskellPackagesNew: haskellPackgesOld: rec {
    };
  }).callCabal2nix "labo-vernemq" ./. {};
in if lib.inNixShell then drv.env.overrideAttrs (old: {
  buildInputs = old.buildInputs ++ [ haskellPackages.ghcid cabal-install ];
}) else drv
