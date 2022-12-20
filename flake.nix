{
  inputs = {
    devenv.url = "github:cachix/devenv";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , fenix
    , devenv
    } @ inputs:
    flake-utils.lib.eachDefaultSystem (system:
    let pkgs = import nixpkgs {
      inherit system;
    };
    in
    {
      devShell = devenv.lib.mkShell {
        inherit inputs pkgs;

        modules = [
          {
            packages = with pkgs; [
              solc
            ] ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk; [
              libiconv
              frameworks.Security
            ]);

            # https://devenv.sh/languages/
            languages.nix.enable = true;
            languages.rust = {
              enable = true;
              version = "stable";
            };

            # https://devenv.sh/pre-commit-hooks/
            pre-commit = {
              tools = with pkgs; {
                rustfmt = lib.mkOverride 49 (fenix.packages.${pkgs.system}.latest.rustfmt);
              };
              hooks = {
                shellcheck.enable = true;

                # nightly fmt is required here:
                # https://github.com/gakonst/ethers-rs/blob/master/.github/workflows/ci.yml#L123
                # while devenv doesn't yet support customizing it:
                # https://github.com/cachix/devenv/issues/211
                rustfmt.enable = true;
              };
            };
          }
        ];
      };
    });
}
