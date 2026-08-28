{
  description = "Pandora single-node k3s and Cilium homelab";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    forEachSystem = function:
      nixpkgs.lib.genAttrs systems (system:
        function {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    devShells = forEachSystem ({pkgs}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          alejandra
          bashInteractive
          cilium-cli
          colima
          helm
          jq
          kubectl
          openssh
          shellcheck
          shfmt
          terraform
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
