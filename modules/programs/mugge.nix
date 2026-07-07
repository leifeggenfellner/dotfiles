_: {
  flake.homeModules.programs-mugge =
    { osConfig
    , pkgs
    , inputs
    , lib
    , ...
    }:
    let
      muggePkgs = inputs.mugge.packages.${pkgs.stdenv.hostPlatform.system};
      muggeHosts = [
        "shitbox"
      ];
      onMuggeHost = lib.elem osConfig.networking.hostName muggeHosts;
    in
    {
      imports = [ inputs.mugge.homeManagerModules.default ];

      services.mugge-chat.enable = onMuggeHost;

      home.packages = lib.mkIf onMuggeHost [
        muggePkgs.mugge-azure
      ];
    };
}
