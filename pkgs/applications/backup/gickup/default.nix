{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gickup";
  version = "0.10.23";
  src = fetchFromGitHub {
    owner = "cooperspencer";
    repo = pname;
    rev = "v${version}";
    sha256 = "IiiYmzFr4EVBIFr0tZRRq/FPVSE3goA1XiSPJS0QkJM=";
  };
  vendorHash = "sha256-kEy6Per8YibUHRp7E4jzkOgATq3Ub5WCNIe0WiHo2Ro=";
}
