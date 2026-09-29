_: {
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      name = "leif-dev-shell";
      inputsFrom = [ ];
      nativeBuildInputs = with pkgs; [
        nixpkgs-fmt
        sops
        ssh-to-age
        (callPackage ./_sops-enroll-host.nix { })
        (python3.withPackages (pythonPackages: [
          pythonPackages.pillow
        ]))
      ];
    };
  };
}
