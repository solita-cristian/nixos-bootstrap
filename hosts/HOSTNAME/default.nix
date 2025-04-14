# SPDX-License-Identifier: MIT
{
  self,
  lib,
  inputs,
  pkgs,
  ...
}:
{
  #Set the baseline with common.nix
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-10th-gen
    self.nixosModules.common-client
  ];

  boot = {
    # ensure the latest kernel
    kernelPackages = pkgs.linuxPackages_latest;

    #boot.initrd.systemd.enable is true from srvos
    #setup the bootloader with systemd-boot enabled
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
    };

    # Allow some emulated systems to run
    # this is needed for some cross-compilation cases
    binfmt.emulatedSystems = [
      "aarch64-linux"
    ];
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "conservative";
  };

  hardware = {
    enableRedistributableFirmware = true;
    enableAllFirmware = true;
  };

  networking = {

    #TODO Replace this with the name of the nixosConfiguration so it can be common
    # Define your hostname
    hostName = lib.mkDefault "HOSTNAME";

    enableIPv6 = false;
    nftables.enable = true;
    #Open ports in the firewall?
    firewall = {
      enable = true;
      #TODO currently allows provisioning server and ssh
      allowedTCPPorts = [
        8080
        22
      ];
      allowedUDPPorts = [
        8080
        22
      ];
    };
  };

  console.useXkbConfig = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
