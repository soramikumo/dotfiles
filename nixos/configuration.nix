{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # --- ブートローダ(UEFI) ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- ホスト名・時刻 ---
  networking.hostName = "homelab";
  time.timeZone = "Asia/Tokyo";

  # --- SSH(鍵認証のみ) ---
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # --- ユーザー + 公開鍵 ---
  users.users.sora = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # docker は sudo 無しで docker コマンドを使うため
    # コンソール用パスワードは git に置かない。VM 上で `sudo passwd sora` で設定。
    # SSH は鍵のみ(PasswordAuthentication = false)なので、これが無くても普段は困らない。
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPVbxcuOUEOu39ITOp0cx3sgcgVSVoLtQ8s9PdL5YYCg homelab"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCmMxbi/LMxDX+WW9DihPlcmurxs/iDwOK044upTCzStjEeAOTMV2PPZGMzf7PpA+Cc/njX6Lc2TVQ7dw7RTLQzWgQF4jdLAQx45pim9nFiHvlfKUm4rL4zyLO1h/NHiwFH4onIFd01FoPZnxa/2paROeE6pAH19SRjRq1dM5z9AD9nXOOi7TrxtOyWqtQAQfAsy36NOkd2pVE4bxKFbVujs1ZDYq4BcLT1voj0ynMKKaX8ujkjObzd2wBN5OfGG3MzEkgtbE5DaH48JOltgMhnPccblkZiGEgbKcY0LdN1K2iWzyCLrn1Ok1TcnEE6xVyBKEu/5/RNd76F8XAHBbJkFYzJbAA8t6eJS7E3m33OKCbrfDesmjVoLCIorJeM2XK0tpNgx2PnZ9UE4SfSpLx1yVkg5hzl2wUw5rcp2avwotchTsUpY7c7NnIkl6afCD+KHy+8RnTNCp/Av1LPbZLadoUUdVDkWgFndz7tDqQy5yZaeWMf0UAY+zvziYpqDOs= mikumo-sora@intelmac2020.local"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  # --- flake / nix 設定 ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # --- 基本パッケージ ---
  environment.systemPackages = with pkgs; [ git vim ];

  # --- VMware ゲスト連携 ---
  virtualisation.vmware.guest.enable = true;

  # --- Docker(コンテナ基盤) ---
  virtualisation.docker.enable = true;

  # --- L3 動作確認用: nginx hello-world コンテナ(宣言的に常駐) ---
  virtualisation.oci-containers = {
    backend = "docker";
    containers.hello = {
      image = "nginx:alpine";
      ports = [ "8080:80" ];
    };
  };

  system.stateVersion = "26.05";
}
