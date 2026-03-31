{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        version = "0.2.1";
      in
      {
        packages = rec {
          picoclaw = pkgs.buildGoModule {
            pname = "picoclaw";
            version = version;
            src = self;

            subPackages = [
              "cmd/picoclaw"
              "cmd/picoclaw-launcher-tui"
              "web/backend"
            ];

            proxyVendor = true;
            vendorHash = "sha256-K9LssS1Hff19dv6oa8EaFOUZIRnOtAqC5jgnY5HuWTk=";
            preBuild = "go generate ./...";
            ldflags = [
              "-s"
              "-w"
              "-X github.com/sipeed/picoclaw/cmd/picoclaw/internal.version=${version}"
            ];
            doInstallCheck = true;
            nativeInstallCheckInputs = [ pkgs.versionCheckHook ];
            versionCheckProgramArg = "version";
            checkFlags =
              let
                skippedTests = [
                  "TestGetVersion"
                  "TestCodexCliProvider_MockCLI_Success"
                  "TestCodexCliProvider_MockCLI_Error"
                  "TestCodexCliProvider_MockCLI_WithModel"
                ];
              in
              [ "-skip=^${builtins.concatStringsSep "$|^" skippedTests}$" ];

            meta = {
              description = "Tiny, Fast, and Deployable anywhere - automate the mundane, unleash your creativity";
              homepage = "https://github.com/sipeed/picoclaw";
              license = lib.licenses.mit;
              mainProgram = "picoclaw";
              platforms = lib.platforms.unix;
            };
          };

          default = picoclaw;
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.picoclaw}/bin/picoclaw";
        };
      }
    );
}
