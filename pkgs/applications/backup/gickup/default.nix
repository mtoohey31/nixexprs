{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gickup";
  version = "0.10.26";
  src = fetchFromGitHub {
    owner = "cooperspencer";
    repo = pname;
    rev = "v${version}";
    sha256 = "GYYmoGNYiwarMZw1w8tdH8zKl19XQ2R+EaJFK8iacwI=";
  };
  vendorHash = "sha256-vyDzGho9vcdCmBP7keccp5w3tXWHlSaFoncS1hqnBoc=";
}
