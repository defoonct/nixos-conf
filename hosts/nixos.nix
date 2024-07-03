{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix = {
    package = pkgs.nixFlakes;

    extraOptions = ''
      experimental-features = nix-command flakes
      # warn-dirty = false
    '';
  };

  nixpkgs.config.allowUnfree = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    enableCryptodisk = true;
  };

  boot.initrd = {
    luks.devices."root" = {
      # 'device' must match 'fileSystems."/".device = "dev/disk/by-label/root"' defined on 'hardware-configuration.nix'
      device = "/dev/disk/by-uuid/3de63480-3b0f-41b5-b43d-ca110a724344";
      preLVM = true;
      keyFile = "/keyfile.bin";
      allowDiscards = true;
    };
    secrets = {
      "keyfile.bin" = "/etc/secrets/initrd/keyfile.bin";
    };
  };

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Stockholm";

  i18n.defaultLocale = "en_US.utf8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.utf8";
    LC_IDENTIFICATION = "sv_SE.utf8";
    LC_MEASUREMENT = "sv_SE.utf8";
    LC_MONETARY = "sv_SE.utf8";
    LC_NAME = "sv_SE.utf8";
    LC_NUMERIC = "sv_SE.utf8";
    LC_PAPER = "sv_SE.utf8";
    LC_TELEPHONE = "sv_SE.utf8";
    LC_TIME = "sv_SE.utf8";
  };

  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel")) {
            if (action.id.startsWith("org.freedesktop.udisks2.")) {
                return polkit.Result.YES;
            }
        }
    });
  '';

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs.gnome; [ geary ];

  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  services.xserver = {
    xkb.layout = "latam";
    xkb.variant = "";
  };

  console.keyMap = "la-latin1";

  services.printing.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.esc = {
    isNormalUser = true;
    extraGroups = [
      "docker"
      "libvirtd"
      "networkmanager"
      "wheel"
      "video"
    ];
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnomeExtensions.go-to-last-workspace
    gnomeExtensions.tactile
    vim
  ];

  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-tty;
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      address="/kubernetes.foobar.local/192.168.121.240";
      server = [
        "8.8.8.8"
        "8.8.4.4"
      ];
    };
    resolveLocalQueries = true;
  };

  networking.search = [
    "kubernetes.foobar.local"
  ];

  networking.resolvconf.extraConfig = "domain=kubernetes.foobar.local";

  system.stateVersion = "22.05";

  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings = {
    dns = [ "8.8.8.8" "1.1.1.1" ];
  };

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.verbatimConfig = ''
    group = "libvirtd"
  '';

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Hack" ]; })
  ];

  programs.nix-ld.enable = true;
}
