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

## macOS で使う

- `OPENAI_API_KEY` に INIAD OpenAI API の Bearer Token を設定する
  - もしくは macOS Keychain の `iniad-openai-api` から自動で読む
- 必要なら `OPENAI_BASE_URL` を設定する
  - デフォルトは `https://api.openai.iniad.org/api/v1`
- モデルはデフォルトで `gpt-5.4` を使う

普通の mac ユーザーは、`git-auto-commit` と `git-iniad-commit-msg` を `PATH` の通った場所に置けば使えます。

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/tenelol/iniad-commit/main/git-auto-commit -o ~/.local/bin/git-auto-commit
curl -fsSL https://raw.githubusercontent.com/tenelol/iniad-commit/main/git-iniad-commit-msg -o ~/.local/bin/git-iniad-commit-msg
chmod +x ~/.local/bin/git-auto-commit ~/.local/bin/git-iniad-commit-msg
```

その後は任意の Git repo でこう使えます。

```bash
git auto-commit
```

macOS では初回実行時に Keychain 未設定なら、その場で API キー入力を求めて保存します。キーは INIAD のワークスペースボットに `apikey issue` と送って発行してください。

手動で入れたい場合:

```bash
security add-generic-password -U -a "$USER" -s iniad-openai-api -w '<API_KEY>'
```

ローカル clone から直接試す場合:

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

`git commit --auto-message` のように既存の `git commit` オプションを後付けすることはできません。代わりに、Git は `git-<name>` という実行ファイルを `git <name>` サブコマンドとして呼べるので、この方法で追加しています。

## Nix で使う

Nix から使いたい場合は flake package / app も用意しています。

```bash
nix run github:tenelol/iniad-commit
```

`denix` ベースの `~/.dotfiles` から使うなら、flake input と package import で入れられます。
