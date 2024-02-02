let
  ymstnt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBFMbDkjW4Bei6BIQRNzoAyed+1klLFjumE6Og6GhMsz";
  gep = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3olHivyTuztxmwefBJ5EtsaG2Kff7kDGVUacrFMIFQ";

  raspi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK3vrYOUtZIZhwoYihWYUzglxs7w8GGq647OX9vNcPRP";

  keys = [ ymstnt gep raspi ];
in
{
  "moe-token.age".publicKeys = keys;
  "moe-owners.age".publicKeys = keys;
  "mysql.age".publicKeys = keys;
  "transmission.json.age".publicKeys = keys;
  "acme-email.age".publicKeys = keys;
  "runner1.age".publicKeys = keys;
  "miniflux.age".publicKeys = keys;
  "c2fmzq.age".publicKeys = keys;
}