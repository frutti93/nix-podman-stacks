{
  lib,
  dummyHash,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];

  npsTests.memorySize = 4096;
  nps.stacks.streaming = {
    enable = true;

    useQbittorrent = false;
    useProwlarr = false;
    useSabnzbd = false;
    jellyfin.oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
  };

  # No GPU in the test VM.
  services.podman.containers.jellyfin.devices = lib.mkForce [];
}
