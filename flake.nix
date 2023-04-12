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
    ruby-nix.url = "github:sagittaros/ruby-nix";
    bob-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bundix = {
      url = "github:sagittaros/bundix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, bob-ruby, ruby-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        _module.args.pkgs = import self.inputs.nixpkgs {
          inherit system;
          overlays = [
            bob-ruby.overlays.default
            ruby-nix.overlays.ruby
          ];
        };
        devShells.default =
          let
            rubyNix = ruby-nix.lib pkgs;
            ruby = pkgs."ruby-3.2";
            rubyProject = rubyNix {
              inherit ruby;
              name = "ruby-project";
              gemset = ./gemset.nix;

            };
          in
          pkgs.mkShell {
            buildInputs = [
              rubyProject.env
              rubyProject.ruby
              inputs'.bundix.packages.default
            ];
          };
      };
    };
}
