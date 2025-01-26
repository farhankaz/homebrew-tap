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
  (buildpath/"build-info.cpp").write <<~EOS
  const char * BUILD_NUMBER = "0"
  const char * BUILD_COMMIT = "local"
  const char * BUILD_COMPILER = "unknown"
  const char * BUILD_TARGET = "native"
  EOS
  inreplace "CMakeLists.txt", "configure_file(
    llama.cpp/common/build-info.cpp.in
    ${CMAKE_CURRENT_BINARY_DIR}/build-info.cpp
    @ONLY
)", "configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/build-info.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/build-info.cpp
    COPYONLY
)"
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
