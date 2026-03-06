Prepare a pull request for the current branch:

1. Run `git log main...HEAD --oneline` to see commits in this branch
2. Run `git diff main...HEAD --stat` to see changed files
3. Run `git diff main...HEAD` to analyze the actual changes
4. Generate a PR with:
   - **Title**: Following conventional commit format (feat/fix/refactor: description)
   - **Summary**: 2-3 bullet points of main changes
   - **Test Plan**: How to verify the changes work
   - **Breaking Changes**: List any breaking changes (if applicable)
5. Create the PR using `gh pr create` with the generated title and body
