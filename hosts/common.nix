# SPDX-License-Identifier: MIT
{
  self,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = lib.flatten [
    (with self.nixosModules; [
      basic-system
      users
      scripts
    ])
    [
      inputs.srvos.nixosModules.desktop
      inputs.nix-index-database.nixosModules.nix-index
      inputs.srvos.nixosModules.mixins-nix-experimental
      inputs.srvos.nixosModules.mixins-trusted-nix-caches
    ]
    [
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {
            inherit inputs self;
          };
          #TODO export this from a toplevel login-users module
          users.FIRST_NAME = {
            imports = [ (import ../home/home-client.nix) ] ++ [ inputs.nix-index-database.hmModules.nix-index ];
          };
        };
      }
    ]
  ];

  config = {
    nixpkgs = {
      config.allowUnfree = true;
    };

    # Contents of the user and group files will be replaced on system activation
    # Ref: https://search.nixos.org/options?channel=unstable&show=users.mutableUsers
    users.mutableUsers = true;

    # Enable the SSH daemon and fw updates
    services = {
      openssh.startWhenNeeded = true;
      # enable the fwupdate daemon to install fw changes
      fwupd.enable = true;
      # Enable userborn to take care of managing the default users and groups
      userborn.enable = true;
    };

    # Enable developer documentation (man 3) pages
    documentation = {
      dev.enable = true;
    };

    nix = {
      # This will add each flake input as a registry
      # To make nix3 commands consistent with your flake
      registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
      # This will additionally add your inputs to the system's legacy channels
      # Making legacy nix commands consistent as well
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

      settings = {
        system-features = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];

        # Avoid copying unnecessary stuff over SSH
        builders-use-substitutes = true;
        build-users-group = "nixbld";
        trusted-users = [
          "root"
          "FIRST_NAME"
        ];
        auto-optimise-store = true; # Optimise syslinks
        keep-outputs = true; # Keep outputs of derivations
        keep-derivations = true; # Keep derivations
      };

      # Garbage collection
      optimise.automatic = true;
      gc = {
        automatic = true;
        dates = lib.mkDefault "weekly";
        options = lib.mkDefault "--delete-older-than 7d";
      };

      # extraOptions = ''
      #   plugin-files = ${pkgs.nix-doc}/lib/libnix_doc_plugin.so
      # '';

      #https://nixos.wiki/wiki/Distributed_build#NixOS
      buildMachines = [
        {
          hostName = "hetzarm";
          system = "aarch64-linux";
          maxJobs = 16;
          speedFactor = 1;
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          mandatoryFeatures = [ ];
          #TODO Fix this
          sshUser = "FIRST_NAME";
          sshKey = "/home/FIRST_NAME/.ssh/builder-key";
        }
        {
          hostName = "vedenemo-builder";
          system = "x86_64-linux";
          maxJobs = 16;
          speedFactor = 1;
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          mandatoryFeatures = [ ];
          #TODO Fix this
          sshUser = "FIRST_NAME";
          sshKey = "/home/FIRST_NAME/.ssh/builder-key";
        }
      ];

      distributedBuilds = true;
    };

    # Sometimes it fails if a store path is still in use.
    # This should fix intermediate issues.
    systemd.services.nix-gc.serviceConfig = {
      Restart = "on-failure";
    };

    ## Local config for known hosts
    programs = {
      ssh = {
        startAgent = true;
        extraConfig = ''
          host ghaf-netvm
               user ghaf
               IdentityFile ~/.ssh/builder-key
               hostname 192.168.10.108 # TODO: change this to the actual IP
          host ghaf-host
               user ghaf
               IdentityFile ~/.ssh/builder-key
               hostname 192.168.100.2
               proxyjump ghaf-net
          host ghaf-ui
               user ghaf
               IdentityFile ~/.ssh/builder-key
               hostname 192.168.100.3
               proxyjump ghaf-net
          host hetzarm
               user FIRST_NAME
               HostName 65.21.20.242
               IdentityFile ~/.ssh/builder-key
          host vedenemo-builder
               user FIRST_NAME
               hostname builder.vedenemo.dev
               IdentityFile ~/.ssh/builder-key
        '';
        knownHosts = {
          hetzarm-ed25519 = {
            hostNames = [ "65.21.20.242" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILx4zU4gIkTY/1oKEOkf9gTJChdx/jR3lDgZ7p/c7LEK";
          };
          vedenemo-builder = {
            hostNames = [ "builder.vedenemo.dev" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHSI8s/wefXiD2h3I3mIRdK+d9yDGMn0qS5fpKDnSGqj";
          };
        };
      };
      # Disable in favor of nix-index-database
      command-not-found = {
        enable = false;
      };
    };
  };
}
