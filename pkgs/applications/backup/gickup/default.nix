{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gickup";
  version = "0.10.30";
  src = fetchFromGitHub {
    owner = "cooperspencer";
    repo = pname;
    rev = "v${version}";
    sha256 = "knnc4FAzGk1hV/Pzoc+klm4dt1cFrn4BYZx1lY7iLp8=";
  };
  vendorHash = "sha256-XxDsEmi945CduurQRsH7rjFAEu/SMX3rSd63Dwq2r8A=";
}
