{ config, pkgs, ... }:

{
  imports = [
    ./base.nix
    ../programs/packages
  ];

  home.username = "binker";
  home.homeDirectory = "/home/binker";

  programs.git = {
    enable = true;
    settings = {
      user = {
      	name = "Nathaniel Chappelle";
	      email = "nathaniel@chappelle.dev";
      };
    };
  };

  # starship - an customizable prompt for any shell
  programs.starship = {
    enable = true;
    # custom settings
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };
}
