{
  description = "Commit message generator for INIAD students using the INIAD OpenAI API";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        system: pkgs:
        let
          iniad-commit = pkgs.stdenvNoCC.mkDerivation {
            pname = "iniad-commit";
            version = "0.2.0";

            src = ./.;

            nativeBuildInputs = [
              pkgs.makeWrapper
            ];

            installPhase = ''
              runHook preInstall

              install -Dm755 git-iniad-commit-msg $out/libexec/git-iniad-commit-msg
              install -Dm755 git-auto-commit $out/bin/git-auto-commit
              patchShebangs $out/libexec/git-iniad-commit-msg
              patchShebangs $out/bin/git-auto-commit

              wrapProgram $out/bin/git-auto-commit \
                --set GIT_AUTO_COMMIT_PYTHON ${pkgs.python3}/bin/python3 \
                --set GIT_AUTO_COMMIT_SCRIPT $out/libexec/git-iniad-commit-msg \
                --prefix PATH : ${lib.makeBinPath [ pkgs.git ]}

              runHook postInstall
            '';

            meta = {
              description = "Git subcommand that generates commit messages with the INIAD OpenAI API";
              homepage = "https://github.com/tenelol/iniad-commit";
              license = lib.licenses.mit;
              mainProgram = "git-auto-commit";
              platforms = lib.platforms.all;
            };
          };
        in
        {
          default = iniad-commit;
          inherit iniad-commit;
        }
      );

      apps = forAllSystems (system: _pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${system}.iniad-commit}/bin/git-auto-commit";
          meta = {
            description = "Run git auto-commit";
          };
        };
        iniad-commit = {
          type = "app";
          program = "${self.packages.${system}.iniad-commit}/bin/git-auto-commit";
          meta = {
            description = "Run git auto-commit";
          };
        };
      });
    };
}
