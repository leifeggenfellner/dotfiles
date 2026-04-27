_: {
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      name = "leif-dev-shell";
      inputsFrom = [ ];
      nativeBuildInputs = with pkgs; [
        nixpkgs-fmt
      ];
    };
  };
}
