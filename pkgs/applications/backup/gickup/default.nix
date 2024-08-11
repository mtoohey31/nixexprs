{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gickup";
  version = "0.10.31";
  src = fetchFromGitHub {
    owner = "cooperspencer";
    repo = pname;
    rev = "v${version}";
    sha256 = "6du9x5QQN1VJzAABJ+8Fm3YscfoRwKVYZO9tTMz22AQ=";
  };
  vendorHash = "sha256-Nmt7T6sDWVHQZuINvON24Mq638Q04r5bpOBnz2vp4vM=";
}
