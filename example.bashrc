# ~/.bashrc
# Control flow, assuming invoked as bash without --posix:
#  login:              /etc/profile
#  login:              first_found( ~/.bash_profile ~/.bash_login ~/.profile )
#  interactive-!login: ~/.bashrc
#  #!|!interactive:    if [ -n "$BASH_ENV" ]; then . "$BASH_ENV"; fi (no $PATH)
#  <use>
#  login:              ~/.bash_logout

# Interactive shells have 'i' included in $-
# This is bashrc so _should_ be always interactive (see above) but people do
# things like source this file in other contexts.
# Guard against common practice instead of demanding adherence to an ideal.
#
if [[ $- == *i* ]]; then
  # anything which sets PS1 or emits output, or controls user interaction, here
  PS1='$?:\u@\h[\A](\!)\w\$ '

  # Avoid storing in history lines starting with space:
  HISTCONTROL='ignorespace'
fi

# Other setup
alias ..='cd ..'
alias z='exec zsh -l'

# ######################################################################
# Final banner

# We guard on being interactive again, and then emit whatever we think
# will help our future forgetful selves remember Things Which Matter when
# dealing with Keybase in our setup.
if [[ $- == *i* ]]; then
  cat >&2 <<'EOBANNER'
This is a Docker Keybase container.
Run:
  - run_keybase            : to start the service
  - keybase.is-up-to-date  : to check if a newer release is available
  - z                      : to use zsh
Git repositories are checked out as: ~/repos/$TEAM/$REPO/
KeybaseFS is mounted by `run_keybase`, as /keybase :
  - /keybase/public/YOUR_KEYBASE_HANDLE/
    + Eg: <memos to self go here>
  - /keybase/public/$FOLLOWEE/
  - /keybase/team/$TEAM/
    + Eg: /keybase/team/exim/maintainers-keyring.asc
  - /keybase/private/$COMBINATIONS/
EOBANNER
fi
