<!-- Copied from https://github.com/teamniteo/claude/blob/main/rules/conventions.md.
     Managed in ~/.dotfiles/claude/CLAUDE.md (https://github.com/myrheimb/dotfiles) - edit there, not in ~/.claude.
     If you have project-specific instructions to add, README.md is the best place. -->

# Conventions

Push back if you see a better angle. Tell the user if they are asking for the wrong thing.

## A question is a question

When I ask a question, answer it. When I report what I see, diagnose and explain. Neither is a go-ahead.

"Should we use X?" is not "migrate everything to X." "What would it take to add Y?" is not "add Y."

When in doubt, assume it's a question. Answer first. Act when I say go.

## Key principles

1. No fluff, ever — Every word needs to earn its place. "i think we could potentially consider trying..." becomes "try this:"
2. Surgical intervention only — Touch what needs touching. Nothing else. The code works? Don't "improve" it while you're in there. Fix the bug, verify the fix, get out.
3. Simplicity is the goal, not a compromise — The cleanest solution wins. Not the clever one. Not the elegant abstraction that will "scale better." The one that a tired human at 3am can read and understand without context.
4. Verify everything — "Did this actually work?" — mandatory question after every action. No assumptions. No "it should work." No "that usually fixes it." Check. Confirm. Then move on.
5. Obsessive evolution — Every interaction is data. What confused the user? What took three attempts when it should have taken one? Propose CLAUDE.md updates. Don't edit it unasked.
6. Automation over discipline — Don't rely on user's discipline, prefer automated enforcement.
7. DRY tests, WET code — DRY in code is bad, but DRY in tests is good.

## Security
1. Never print secret values, even when a file is readable.
2. Sending anything outward (Slack, ClickUp, email, PR or issue comments) needs an explicit go.
3. Ask before any command that can destroy uncommitted work, whatever form it takes.

## Write less code

The best code is the code never written. Before writing any, stop at the first rung that holds:

1. Does this need to be built at all? (YAGNI)
2. Does the standard library already do it? Use it.
3. Does a native platform feature cover it? Use it.
4. Does an already-installed dependency solve it? Use it.
5. Can it be one line? Make it one line.
6. Only then: write the minimum code that works.

Lazy means efficient, not careless. Deletion over addition, boring over clever, fewest files possible. Never cut corners on input validation, error handling, security, accessibility, or anything explicitly requested.

## Tools
- If a CLI tool is missing, run it with `/run/current-system/sw/bin/nix-shell -p <package> --run '<command>'`. Don't install it.
- For one-off Python packages, use `/run/current-system/sw/bin/nix-shell -p python314Packages.<package> --run '<command>'`. Don't use pip or uv.
- Run Nix commands as a call of their own, without `cd`, redirects or `$(...)`. Otherwise they stay sandboxed and can't reach the Nix daemon.

## Code Style

- Follow existing code style in the file being edited. Read similar files to learn how things are done.
- Whenever we have a multiline list in a config file, alphabetically sort it.
- Write variable names in full, not single characters, including loop variables, comprehensions, lambdas, and exceptions.
- Python: `import typing as t`, then `t.Any`. This applies to `typing` only.
- Python: Separate control-flow blocks from surrounding simple statements with blank lines to make logical sections visually clear. Keep single guard clauses (`if not items: return`) tight against the code they protect.
- Always ask clarifying questions when there are multiple valid approaches to a task.
- After editing, run the repo's checks (`task lint` and `task type` if the Taskfile has them) to ensure code style compliance.
- When using camelCase, treat abbreviations just like ordinary words (e.g., `getHttpUrl` not `getHTTPURL`, `parseJsonApi` not `parseJSONAPI`).

## Comments

Code should be self-documenting, expressing the truth rather than pointing to its source. If a comment is needed to explain what the code does, consider refactoring the code to make its intent clearer instead of adding the comment.

Comments are only acceptable when they explain WHY something is done a certain way, and may include a link to the GitHub issue or comment that explains the reasoning.

### Unacceptable Comments
- Comments that repeat what code does
- Commented-out code (delete it)
- Obvious comments ("increment counter")
- Comments instead of good naming
- Comments about updates to old code ("<- now supports xyz")

## Markdown

Do not use bold emphasis in replies, documentation, PR descriptions, or other prose. This includes both double-asterisk and double-underscore Markdown. Use plain text and clear wording. Preserve required syntax in code, such as Python keyword arguments and glob patterns.

Use semicolons sparingly in prose, preferring commas where grammatically appropriate. Keep the sentence structure when it reads well. Preserve semicolons required by code or configuration syntax.

Never hard-wrap prose in Markdown files. Write each paragraph as a single line and let the editor soft-wrap. Hard wraps make diffs noisy — a one-word edit reflows the whole paragraph.

## git

NEVER push directly to `main`. Always work on a feature branch and leave the pushing to the user. This rule has NO exceptions — not even for "quick fixes" or single commits. If you have clear instructions, make a branch based on the naming convention below. If not, ask.

If `git config commit.gpgsign` is true, commits must be signed, and the sandbox can't reach the GPG keyring. Never disable signing or use `--no-gpg-sign`. Prepare the commits instead (staged changes, or a script that creates them) and hand them over for me to run.

### Branch naming convention

Each branch name should start with a type prefix, followed by a slash, and then a concise description of the work being done. Use hyphens to separate words in the description.

The prefix can be one of the following:
- `feat`: for new features or enhancements
- `fix`: for bug fixes
- `chore`: other

If the branch contains a `chore` and a `fix` commit, use `fix` as the prefix. If the branch contains a `chore` and a `feat` commit, use `feat` as the prefix. If the branch contains a `fix` and a `feat` commit, use `feat` as the prefix.

When working in a feature branch, always try to merge new work into the previous commits on this branch. 

### Commit message convention

Each commit message should start with a type prefix, followed by a colon, a space, and an uppercase letter.

The prefix can be one of the following:
- `feat`: for new features or enhancements
- `fix`: for bug fixes
- `chore`: other

Commit titles should be limited to 50 characters and other lines to 72 characters. This is not a hard limit, if it makes sense, you can break it.

If there is additional cleanup included in the commit, end the body with it. One item is a sentence, like "Also, drop the crontab and its pre-commit hook." List several like so:

```
Also:
- clean up X
- update Y
- remove Z
```

Describe the change, not its history. No references to past implementations, earlier bugs, or what the code used to do — we don't host legacy versions and we clean up as we go, so the old state is noise to whoever reads this next.

Write the body for a teammate reading `git log` a year from now: why the change was needed and what it changes, in plain words. Two to four sentences is typical, and a small chore needs one ("pgcrypto is in core Postgres now, and we don't use hstore.").

- Lead with the purpose a person cares about, not the mechanism: "Make it obvious which vendors were invited", not the new relationship and how it is loaded.
- Give the one or two numbers that make the case, rounded: "2s of work", not "0.5-1.7s". No event counters, load averages or exit codes.
- Leave out the implementation: edge cases, defensive handling, file modes, config keys, how a guarantee is enforced. The diff shows them.
- Leave out how it was verified ("make check passes", "verified on Lara"), how the problem was investigated, and what is still pending. CI shows the checks, and the issue holds the investigation and the follow-ups.
- Prefer everyday words to internal ones: "the CI job", not "the fleet".
- Write like a teammate, "we" is fine.
- One idea per bullet.

Before keeping a sentence, ask: would a teammate reading `git log` in a year miss it? If not, cut it.

NEVER append "Authored by Claude Code", a `Co-Authored-By` trailer for Claude, or any other line crediting Claude to commit messages.

## Documentation

After finishing your work, look for the `docs/` folder. It contains our documentation as Markdown. If applicable, update it based on the work you have just performed.

Also update any README.md files you encounter, if applicable.

## Enums

Enums should have standardized values across the stack: snake_case in Python and Postgres, camelCase in API JSON, human-readable labels via `x-labels`.

In Python:

* <enum>.name: snake_case, for DB storage, Python code, logging, metrics.
* <enum>.value: camelCase, for building response dicts, which happens automatically with `enum_adapter` in the JSON renderer, so you never need to call `.value` directly.
* <enum>.label: human-readable, for auditlog messages, emails, PDF/CVS exports.
