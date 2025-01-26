class Llx < Formula
  desc "Unix-based system utility for interacting with LLM models using llama.cpp"
  homepage "https://github.com/farhankaz/llx"
  url "https://github.com/farhankaz/llx/archive/refs/tags/v0.0.1.tar.gz"
  sha256 "370f0c555dbe8b6457725197eab087c27b24652d354109e112f8c65e3e32a3fa"
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
  inreplace "CMakeLists.txt", "add_library(llama_common STATIC
    llama.cpp/common/sampling.cpp
    llama.cpp/common/common.cpp
    llama.cpp/common/log.cpp
    llama.cpp/common/console.cpp
    llama.cpp/common/arg.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/build-info.cpp
)", "add_library(llama_common STATIC
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/examples/common/common.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/examples/common/console.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/examples/common/grammar-parser.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/build-info.cpp
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
