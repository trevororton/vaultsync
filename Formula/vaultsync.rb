# Homebrew formula for vaultsync.
#
# This file makes the repository double as a Homebrew tap:
#
#   brew tap trevororton/vaultsync https://github.com/trevororton/vaultsync
#   brew install vaultsync
#
# The explicit URL is needed because `brew tap trevororton/vaultsync` alone would look
# for a repo called `homebrew-vaultsync`. Naming the repo `homebrew-vaultsync`
# instead would let people drop the URL, at the cost of an odd repo name.
#
# Before the first release, `brew install --HEAD vaultsync` works with no
# further changes. To ship a stable version, tag a release and fill in `url`
# and `sha256` below:
#
#   git tag v1.0.0 && git push --tags
#   curl -sL https://github.com/trevororton/vaultsync/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256

class Vaultsync < Formula
  desc "Two-way sync between an Obsidian folder and Google Drive, with native Google Docs"
  homepage "https://github.com/trevororton/vaultsync"
  license "MIT"
  version "1.0.0"

  url "https://github.com/trevororton/vaultsync/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "833d9d2cb65a37c01531dc0d2a2737568ab7e299332eae39326a740d8e38cd87"

  head "https://github.com/trevororton/vaultsync.git", branch: "main"

  depends_on :macos
  depends_on "rclone"
  depends_on "fswatch"
  # A non-Apple interpreter matters: macOS denies Apple's bundled python3 access
  # to ~/Documents when it runs as a background launchd agent, and the denial is
  # silent rather than an error.
  depends_on "python@3.13"

  def install
    bin.install "vaultsync"
    doc.install "README.md", "docs/google-oauth.md"
  end

  def caveats
    <<~EOS
      Next steps:

        vaultsync setup     # connect Google Drive and pick your vault
        vaultsync doctor    # check everything, including background access

      Google Docs mode needs a Google API client of your own (about two minutes):
        #{doc}/google-oauth.md

      Nothing syncs until you run `vaultsync add`.
    EOS
  end

  test do
    assert_match "vaultsync #{version}", shell_output("#{bin}/vaultsync version")
    assert_match "mirrored", shell_output("#{bin}/vaultsync help")
  end
end
