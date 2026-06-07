# Tools needed to run this project (macOS / Homebrew).
# Install everything with:  brew bundle
#
# git and make come preinstalled on macOS (via the Xcode Command Line Tools).
#
# NOTE: AWS CLI is intentionally NOT installed via Homebrew. The Homebrew
# awscli formula depends on Homebrew's python and breaks when python is bumped
# (e.g. a pyexpat / libexpat symbol mismatch). Install the official, self-
# contained AWS CLI v2 package instead — see the README:
#   curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o AWSCLIV2.pkg
#   sudo installer -pkg AWSCLIV2.pkg -target /

tap "hashicorp/tap"

brew "hashicorp/tap/terraform" # Terraform CLI (>= 1.9)
brew "hey"                     # HTTP load generator — used in the scaling demo
