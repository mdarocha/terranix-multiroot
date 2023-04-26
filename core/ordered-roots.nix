{ pkgs, normalizedRoots }:

# Calculates a proper roots order taking into account the
# dependencies defined in "depends". Uses tsort utility.

# TODO add tests
# TODO validate depends (if they point to an existing root, don't point to
# themselves, etc.)
let
  inherit (pkgs.lib) concatStringsSep;
  inherit (builtins) map length;

  mapDepends = root: map (d: "${root.name} ${d}") root.depends;
  allRootDepends = root:
    if length root.depends == 0
    then "${root.name} ${root.name}"
    else concatStringsSep "\n" (mapDepends root);
  allRootsDepends = map allRootDepends normalizedRoots;

  tsort-input = pkgs.writeText "tsort-input" (concatStringsSep "\n" allRootsDepends);
in
pkgs.runCommand "tsort-roots" {
  PATH = pkgs.lib.makeBinPath [ pkgs.coreutils ];
} ''
  tsort ${tsort-input} | tac | tr '\n' ' '> $out
''
