_: {
  flake.nixosModules.basic-system = {
    imports = [
      ./audio.nix
      ./client-system-packages.nix
      ./desktop-manager.nix
      ./locale-font.nix
      ./system-packages.nix
      ./xdg.nix
      ./yubikey.nix
      ./fail2ban.nix
      ./sshd.nix
    ];
  };
}
