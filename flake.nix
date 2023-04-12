{
  description = "ruby-project";
  nixConfig = {
    extra-substituters = "https://nixpkgs-ruby.cachix.org";
    extra-trusted-public-keys =
      "nixpkgs-ruby.cachix.org-1:vrcdi50fTolOxWCZZkw0jakOnUI1T19oYJ+PRYdK4SM=";
  };
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ flake-parts, nixpkgs-ruby, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          ruby = nixpkgs-ruby.lib.packageFromRubyVersionFile {
            file = ./.ruby-version;
            inherit system;
          };
          gems = pkgs.bundlerEnv {
            inherit ruby;
            name = "ruby-project";
            gemdir = ./.;
          };
        in
        {
          devShells.default = with pkgs; mkShell {
            buildInputs = [ gems gems.wrappedRuby bundix ];
          };
        };
    };
}
