{ pkgs, ... }:

{
  # Allow sshfs/fuse mounts to be visible to other local users, e.g. the
  # hermes service user reading /home/run/remotePC when mounted by run.
  programs.fuse.userAllowOther = true;

  environment.systemPackages = with pkgs; [
    sshfs
  ];
}
