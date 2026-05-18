class Loupe < Formula
  desc "iOS Simulator screen-context harness for UI automation agents"
  homepage "https://github.com/loupe-dev/loupe"
  url "https://github.com/loupe-dev/loupe/archive/refs/tags/0.1.0.tar.gz"
  sha256 "REPLACE_WITH_RELEASE_SHA256"
  license "MIT"
  head "https://github.com/loupe-dev/loupe.git", branch: "main"

  depends_on "cameroncooke/axe/axe"
  depends_on xcode: ["16.0", :build]

  def install
    system "swift", "build",
      "--configuration", "release",
      "--disable-sandbox",
      "--product", "loupe"

    bin.install ".build/release/loupe"

    build_dir = buildpath/".build/homebrew-loupe-injector"
    system "xcodebuild",
      "-scheme", "LoupeInjector",
      "-destination", "generic/platform=iOS Simulator",
      "-configuration", "Release",
      "CONFIGURATION_BUILD_DIR=#{build_dir}",
      "build"

    injector_framework = build_dir/"PackageFrameworks/LoupeInjector.framework"
    libexec.install injector_framework
  end

  test do
    assert_match "loupe: ok", shell_output("#{bin}/loupe doctor")
    assert_path_exists libexec/"LoupeInjector.framework/LoupeInjector"
    assert_equal(
      "#{libexec}/LoupeInjector.framework/LoupeInjector",
      shell_output("#{bin}/loupe injector-path").strip
    )
  end
end
