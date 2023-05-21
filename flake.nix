{
  description = "ruby-project";
  nixConfig = {
    extra-substituters = "https://nixpkgs-ruby.cachix.org";
    extra-trusted-public-keys = "nixpkgs-ruby.cachix.org-1:vrcdi50fTolOxWCZZkw0jakOnUI1T19oYJ+PRYdK4SM=";
  };
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    flake-parts,
    nixpkgs-ruby,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        ruby = nixpkgs-ruby.lib.packageFromRubyVersionFile {
          file = ./.ruby-version;
          inherit system;
        };
        rubyEnv = pkgs.bundlerEnv {
          inherit ruby;
          name = "ruby-project";
          gemdir = ./.;
        };
        updateDeps = pkgs.writeShellScriptBin "updateRubyDeps" ''
          echo "Removing current generated files"
          [ -e ./Gemfile.lock ] && rm ./Gemfile.lock
          [ -e ./gemset.nix ] && rm ./gemset.nix
          echo "Creating a Gemfile.lock by running bundler"
          BUNDLE_FORCE_RUBY_PLATFORM=true ${rubyEnv.bundler}/bin/bundler lock
          echo "Create a gemset.nix by running bundix"
          ${pkgs.bundix}/bin/bundix --lock
          echo "Done"
        '';
      in {
        packages = {
          default = pkgs.writeScriptBin "rails-server" "${rubyEnv}/bin/rails server";
          image = pkgs.dockerTools.buildImage {
            name = "rails-server";
            copyToRoot = pkgs.buildEnv {
              name = "rails-server-root";
              paths = [self'.packages.default];
            };
            config.Entrypoint = ["${self'.packages.default}"];
          };
        };
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              rubyEnv
              rubyEnv.wrappedRuby
              bundix
              updateDeps
            ];
          };
      };
    };
}
