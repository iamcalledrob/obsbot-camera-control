self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.obsbot-camera-control;
in
{
  options.programs.obsbot-camera-control = {
    enable = lib.mkEnableOption "OBSBOT Camera Control";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "obsbot-camera-control.packages.\${system}.default";
      description = "The obsbot-camera-control package to use.";
    };

    virtualCamera = {
      enable = lib.mkEnableOption "the OBSBOT virtual camera (a v4l2loopback device)";

      deviceNumber = lib.mkOption {
        type = lib.types.int;
        default = 42;
        description = "The /dev/videoN number for the virtual camera. The app expects 42.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      { environment.systemPackages = [ cfg.package ]; }

      # Equivalent of the PKGBUILD's modprobe.d config and systemd unit.
      (lib.mkIf cfg.virtualCamera.enable {
        boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
        boot.kernelModules = [ "v4l2loopback" ];
        boot.extraModprobeConfig = ''
          options v4l2loopback video_nr=${toString cfg.virtualCamera.deviceNumber} card_label="OBSBOT Virtual Camera" exclusive_caps=1
        '';
      })
    ]
  );
}
