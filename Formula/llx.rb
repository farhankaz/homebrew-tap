class Llx < Formula
  desc "Unix-based system utility for interacting with LLM models using llama.cpp"
  homepage "https://github.com/farhankaz/llx"
  url "https://github.com/farhankaz/llx/archive/refs/tags/v0.0.4.tar.gz"
  sha256 "25f861979b20bcb35d5ff98dd9c58b4d8400f875b6fd948f570db56ac05f7f73"
  license "MIT"
  head "https://github.com/farhankaz/llx.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "curl"
  depends_on "git"
  depends_on :macos => :ventura
  depends_on arch: :arm64

  def install
    system "rm", "-rf", "llama.cpp"
    system "git", "clone", "--recursive", "https://github.com/ggerganov/llama.cpp.git"
    
    # Build everything in a single step
    mkdir_p "build"
    
    # Set environment for compilation
    ENV.append "CXXFLAGS", "-I#{buildpath}/llama.cpp"
    ENV.append "CXXFLAGS", "-I#{buildpath}/llama.cpp/common"
    ENV.append "CXXFLAGS", "-I#{buildpath}/llama.cpp/include"
    
    # Configure with all components and chat support
    system "cmake", "-S", ".", "-B", "build",
           "-DCMAKE_BUILD_TYPE=Release",
           "-DCMAKE_OSX_ARCHITECTURES=arm64",
           "-DLLAMA_NATIVE=OFF",
           "-DLLAMA_STATIC=ON",
           "-DLLAMA_STANDALONE=ON",
           "-DLLAMA_BUILD_EXAMPLES=OFF",
           "-DLLAMA_BUILD_TESTS=OFF",
           "-DLLAMA_BUILD_COMMON=ON",
           "-DLLAMA_COMMON_CHAT=ON",
           "-DLLAMA_DIR=#{buildpath}/llama.cpp",
           "-DCMAKE_PREFIX_PATH=#{buildpath}/llama.cpp",
           "-DCMAKE_FIND_DEBUG_MODE=ON",
           "-DCMAKE_VERBOSE_MAKEFILE=ON"
    
    system "cmake", "--build", "build", "--verbose"
    bin.install "build/llx"
    bin.install "build/llxd"
  end


  test do
    system "#{bin}/llx", "--version"
    system "#{bin}/llxd", "--version"
  end
end
