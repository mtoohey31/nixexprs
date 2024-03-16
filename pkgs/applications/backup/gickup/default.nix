{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gickup";
  version = "0.10.28";
  src = fetchFromGitHub {
    owner = "cooperspencer";
    repo = pname;
    rev = "v${version}";
    sha256 = "IGzwMSpbGiUjlO7AtxL20m72VXYW3MJemLpO5BN2rMo=";
  };
  vendorHash = "sha256-sINmTwUERhxZ/qEAhKiJratWV6fDxrP21cJg97RBKVc=";
}
