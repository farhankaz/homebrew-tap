class Llx < Formula
  desc "Unix-based system utility for interacting with LLM models using llama.cpp"
  homepage "https://github.com/farhankaz/llx"
  url "https://github.com/farhankaz/llx/archive/refs/tags/v0.0.1.tar.gz"
  sha256 "486641165c95598d36de58aa5fb6d78a01e38b6df8af21e59edb9cd822238dd6"
  license "MIT"
  head "https://github.com/farhankaz/llx.git", branch: "main"
  depends_on "cmake" => :build
  depends_on "curl"
  depends_on "git"
  depends_on :macos => :ventura
  depends_on arch: :arm64
  def install
  system "rm", "-rf", "llama.cpp"
  system "git", "clone", "--depth", "1", "--branch", "gguf-v0.4.0", "https://github.com/ggerganov/llama.cpp.git"
  system "cp", "llama.cpp/common/build-info.cpp.in", "llama.cpp/common/build-info.cpp"
  buildvars = { "BUILD_NUMBER" => "0", "BUILD_COMMIT" => "local", "BUILD_COMPILER" => "unknown", "BUILD_TARGET" => "native" }
  buildvars.each do |key, value|
  inreplace "llama.cpp/common/build-info.cpp", "@#{key}@", value
  end
  system "cmake", "-S", ".", "-B", "build", "-DCMAKE_BUILD_TYPE=Release", "-DLLAMA_CURL=ON", "-DLLAMA_STANDALONE=ON"
  system "cmake", "--build", "build"
  bin.install "build/llx"
  bin.install "build/llxd"
  end
  service do
  run [opt_bin/"llxd"]
  keep_alive true
  error_log_path var/"log/llxd.log"
  log_path var/"log/llxd.log"
  working_dir HOMEBREW_PREFIX
  end
  test do
  system "#{bin}/llx", "--version"
  system "#{bin}/llxd", "--version"
  end
  end
