{
  description = "Pandora single-node k3s and Cilium homelab";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = [
      "aarch64-darwin"
      "x86_64-linux"
      "x86_64-darwin"
    ];

    forEachSystem = function:
      nixpkgs.lib.genAttrs systems (system:
        function {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = package:
              builtins.elem (nixpkgs.lib.getName package) ["terraform"];
          };
        });
  in {
    devShells = forEachSystem ({pkgs}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          alejandra
          bashInteractive
          cilium-cli
          colima
          hubble
          kubeconform
          kubernetes-helm
          jq
          kubectl
          openssh
          shellcheck
          shfmt
          terraform
          yamllint
        ];

        shellHook = ''
          export KUBECONFIG="''${KUBECONFIG:-$HOME/.kube/mac-mini-k3s.yaml}"
          echo "Pandora development shell"
          echo "KUBECONFIG=$KUBECONFIG"
        '';
      };
    });

    formatter = forEachSystem ({pkgs}: pkgs.alejandra);

    checks = forEachSystem ({pkgs}: {
      flake-format =
        pkgs.runCommand "pandora-flake-format" {
          nativeBuildInputs = [pkgs.alejandra];
        } ''
          alejandra --check ${self}/flake.nix
          touch $out
        '';
    });
  };
}
