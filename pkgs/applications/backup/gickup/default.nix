{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gickup";
  version = "0.10.21";
  src = fetchFromGitHub {
    owner = "cooperspencer";
    repo = pname;
    rev = "v${version}";
    sha256 = "o8uLdkk0aZWIj+mKsp/XGKcwpV0rGFcZnmV4MuHKlUg=";
  };
  vendorSha256 = "NAYkQsCt32mtHFXZC0g3OrlrOceUaeGH4bKWF7B08po=";
}
