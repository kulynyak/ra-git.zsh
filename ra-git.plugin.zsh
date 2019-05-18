# aliases
# cat .gitconfig
alias cgc='cat ~/.gitconfig'
# open (in vim) all modified files in a git repository
alias gvm="git status --porcelain 2>/dev/null | sed -ne 's/^ M //p' | xargs vi"
## aliases

# gl - git commit browser
unalias gl 2>/dev/null
gl() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --toggle-sort=\` \
      --bind "ctrl-m:execute:
                echo '{}' | grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R'"
}

isGitRepo() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1 ; then
    return 0
  else
    return 1
  fi
}

# fbx - checkout git branch + stash/unstash named changes (ctrl+x,ctrl+b)
fbx() {
  if ! isGitRepo ; then
    echo "Not a git repository"
    return
  fi

  local branchList nBranch nBranchName oBranchName stashName swCmd
  branchList=$(git branch -a)
  oBranchName=$(echo "$branchList" | grep \* | sed 's/ *\* *//g')
  nBranch=$(echo "$branchList" | fzf-tmux -d30 -- -x --select-1 --exit-0 | sed 's/ *//')
  zle reset-prompt
  [[ -n "${nBranch}" ]] || return

  if [[ $nBranch =~ 'origin' ]]; then
    nBranchName=$(echo "$nBranch" | sed "s/.*origin\///")
    swCmd="git checkout -b $nBranchName $nBranch"
  else
    nBranchName=$(echo "$nBranch" | sed "s/.* //")
    swCmd="git checkout $nBranchName"
  fi

  [[ $nBranchName != $oBranchName ]] || return

  stashName=$(git stash list | grep -m 1 "On ${oBranchName}: ==${oBranchName}" | sed -E "s/(stash@\{.*\}): .*/\1/g")
  [[ -n "${stashName}" ]] && git stash drop "$stashName"
  git stash save "==$oBranchName" 2>/dev/null

  eval $swCmd

  stashName=$(git stash list | grep -m 1 "On ${nBranchName}: ==${nBranchName}" | sed -E "s/(stash@\{.*\}): .*/\1/g")
  [[ -n "${stashName}" ]] && git stash apply "${stashName}"
}
zle     -N fbx
bindkey '^x^b' fbx

# fb - checkout git branch (ctrl+x,ctrl+g)
fb() {
  if ! isGitRepo ; then
    echo "Not a git repository"
    return
  fi

  local branches branch
  branches=$(git branch -a)
  branch=$(echo "$branches" | fzf-tmux -d30 -- -x --query="$*" --select-1 --exit-0 | sed 's/ *//')
  if [[ $branch =~ 'origin' ]]; then
      git checkout -b $(echo "$branch" | sed "s/.*origin\///") $branch
  else
      git checkout $(echo "$branch" | sed "s/.* //")
  fi
  zle reset-prompt
}
zle     -N fb
bindkey '^x^g' fb
