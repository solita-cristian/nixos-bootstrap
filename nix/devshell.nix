# SPDX-License-Identifier: Apache-2.0
{ inputs, lib, ... }:
{
  imports = [ inputs.devshell.flakeModule ];
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      devshells.default = {
        devshell = {
          name = "Systems devshell";
          meta.description = "Systems development environment";
          packages = [
            pkgs.cachix
            pkgs.nix-eval-jobs
            pkgs.nix-fast-build
            pkgs.nix-output-monitor
            pkgs.nix-tree
            pkgs.nixVersions.latest
            pkgs.ssh-to-age
            config.treefmt.build.wrapper
          ]
          ++ lib.attrValues config.treefmt.build.programs;
        };

        commands = [
        ];
      };
    };
}
