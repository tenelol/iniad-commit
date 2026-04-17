# iniad-commit

INIAD OpenAI API を使って、INIAD 生向けの Semantic Commit Message を自動生成するツールです。CLI としては Git subcommand の `git auto-commit` を提供します。

生成形式:

```text
<Type>: <Emoji> <Title>
```

例:

```text
fix: 🐛 Correct macbook darwin option path
```

デフォルトでは上の形式を使いますが、あとから `style.json` で出力形式を変更できます。

## 前提

- `OPENAI_API_KEY` に INIAD OpenAI API の Bearer Token を設定する
  - もしくは macOS Keychain の `iniad-openai-api` から自動で読む
- 必要なら `OPENAI_BASE_URL` を設定する
  - デフォルトは `https://api.openai.iniad.org/api/v1`
- モデルはデフォルトで `gpt-5.4` を使う

macOS では初回実行時に Keychain 未設定なら、その場で API キー入力を求めて保存します。

手動で入れたい場合:

```bash
security add-generic-password -U -a "$USER" -s iniad-openai-api -w '<API_KEY>'
```

## ローカルで使う

```bash
chmod +x ./git-iniad-commit-msg
./git-iniad-commit-msg
```

ステージ済み差分だけを使う:

```bash
./git-iniad-commit-msg --staged
```

生成したメッセージでそのままコミットする:

```bash
./git-iniad-commit-msg --commit
```

## 出力形式をあとから変える

デフォルト設定を出力:

```bash
./git-iniad-commit-msg --print-default-style
```

設定ファイルを作る:

```bash
mkdir -p ~/.config/iniad-commit
./git-iniad-commit-msg --print-default-style > ~/.config/iniad-commit/style.json
```

この `~/.config/iniad-commit/style.json` が存在すると自動で読みます。別の場所を使いたい場合は `--config /path/to/style.json` か `INIAD_COMMIT_STYLE_FILE` を使えます。

たとえば emoji なし Conventional Commits に変えたいなら、こういう設定にできます。

```json
{
  "format": "<type>(<scope>): <title>",
  "system_rules": [
    "Use Conventional Commits without emoji.",
    "type must be one of: feat, fix, docs, style, refactor, test, chore.",
    "Scope is optional.",
    "The title must be concise and written in imperative present tense."
  ],
  "retry_prompt": "The previous response was invalid. Return exactly one valid Conventional Commit line.",
  "validation_regex": "^(feat|fix|docs|style|refactor|test|chore)(?:\\([^)]+\\))?: (.+)$",
  "type_emoji_map": null,
  "title_capture_group": 2
}
```

`type_emoji_map` を `null` にすると emoji 固定チェックは無効になります。

Git サブコマンドとして直接コミットしたい場合は、`git-auto-commit` を使います。

```bash
chmod +x ./git-auto-commit
PATH="/Users/tener/project/AutoCommit:$PATH" git auto-commit
```

`git commit --auto-message` のように既存の `git commit` オプションを後付けすることはできません。代わりに、Git は `git-<name>` という実行ファイルを `git <name>` サブコマンドとして呼べるので、この方法で追加しています。

どのターミナルからでも使うなら、`PATH` に入っている `~/.local/bin` に配置します。

```bash
install -m 755 ./git-auto-commit ~/.local/bin/git-auto-commit
install -m 755 ./git-iniad-commit-msg ~/.local/bin/git-iniad-commit-msg
```

## GitHub から import して使う

このリポジトリを GitHub に置けば、`denix` ベースの `~/.dotfiles` から flake input として取り込めます。

`flake.nix` の `inputs` に追加:

```nix
iniad-commit.url = "github:tenelol/iniad-commit";
```

必要なホストや共通 module で package を入れる:

```nix
{
  pkgs,
    inputs,
  ...
}:
{
  environment.systemPackages = [
    inputs.iniad-commit.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

これで `nh darwin switch . -H macbook` 後に、どのターミナルからでも `git auto-commit` を使えます。
API キー自体は flake に入れず、`OPENAI_API_KEY` か macOS Keychain から runtime で解決します。

単発で試すだけなら `nix run` でも実行できます。

```bash
nix run github:tenelol/iniad-commit
```
