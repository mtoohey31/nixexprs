{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gickup";
  version = "0.10.22";
  src = fetchFromGitHub {
    owner = "cooperspencer";
    repo = pname;
    rev = "v${version}";
    sha256 = "pF8sckOSmih5rkDv7kvSL9gU4XwBrEIycjzEce01i64=";
  };
  vendorSha256 = "kEy6Per8YibUHRp7E4jzkOgATq3Ub5WCNIe0WiHo2Ro=";
}
