# SPDX-License-Identifier: Apache-2.0
{
  flake.nixosModules.users = {
    imports = [
      ./user.nix
      ./groups.nix
      ./root.nix
    ];
  };
}
