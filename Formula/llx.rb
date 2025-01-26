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

    # Create build-info.cpp with required variables
    (buildpath/"build-info.cpp").write <<~EOS
      const char * BUILD_NUMBER = "0";
      const char * BUILD_COMMIT = "local";
      const char * BUILD_COMPILER = "unknown";
      const char * BUILD_TARGET = "native";
    EOS

    # Force remove existing CMakeLists.txt
    rm_f "CMakeLists.txt"

    # Create a new CMakeLists.txt that properly handles the build
    cmake_content = <<~EOS
      cmake_minimum_required(VERSION 3.12)
      project(llx)

      set(LLX_VERSION "0.0.1")
      set(CMAKE_CXX_STANDARD 17)
      set(CMAKE_CXX_STANDARD_REQUIRED ON)

      # Force static library building
      set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)

      # Add Homebrew paths for curl on macOS
      if(APPLE)
          list(APPEND CMAKE_PREFIX_PATH "/opt/homebrew/opt/curl")
          set(CURL_ROOT "/opt/homebrew/opt/curl")
          set(CURL_INCLUDE_DIR "/opt/homebrew/opt/curl/include")
          set(CURL_LIBRARY "/opt/homebrew/opt/curl/lib/libcurl.dylib")
      endif()

      # Find curl package
      find_package(CURL REQUIRED)

      # Enable CURL support in llama.cpp
      set(LLAMA_CURL ON CACHE BOOL "Enable CURL support in llama.cpp" FORCE)
      set(LLAMA_STANDALONE ON CACHE BOOL "Build llama.cpp as standalone" FORCE)
      add_compile_definitions(LLAMA_USE_CURL)
      add_compile_definitions(GGML_USE_CURL)

      # Add llama.cpp as a subdirectory
      add_subdirectory(llama.cpp)

      # Set build info variables
      set(BUILD_NUMBER 0)
      set(BUILD_COMMIT "local")
      set(BUILD_COMPILER "unknown")
      set(BUILD_TARGET "native")

      # Configure build info
      configure_file(
          build-info.cpp
          ${CMAKE_CURRENT_BINARY_DIR}/build-info.cpp
          COPYONLY
      )

      # llxd executable
      add_executable(llxd
          src/llxd/main.cpp
          src/llxd/llxd.cpp
      )

      target_compile_definitions(llxd PRIVATE LLX_VERSION="${LLX_VERSION}" LLAMA_USE_CURL GGML_USE_CURL)
      target_link_libraries(llxd PRIVATE llama CURL::libcurl)
      target_include_directories(llxd PRIVATE 
          llama.cpp
          llama.cpp/common
          llama.cpp/include
      )

      # llx executable
      add_executable(llx
          src/llx/main.cpp
          src/llx/llx.cpp
          src/llx/daemon_manager.cpp
      )

      target_compile_definitions(llx PRIVATE LLX_VERSION="${LLX_VERSION}" LLAMA_USE_CURL GGML_USE_CURL)
      target_link_libraries(llx PRIVATE llama CURL::libcurl)
      target_include_directories(llx PRIVATE 
          llama.cpp
          llama.cpp/common
          llama.cpp/include
      )
    EOS

    (buildpath/"CMakeLists.txt").write cmake_content

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
