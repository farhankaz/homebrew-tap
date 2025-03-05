class Llx < Formula
  desc "Unix-based system utility for interacting with LLM models using llama.cpp"
  homepage "https://github.com/farhankaz/llx"
  url "https://github.com/farhankaz/llx/archive/refs/tags/v0.0.4.tar.gz"
  sha256 "cd837b3155615f739175414133ede91d775d95fa0c905c6b59493b6bf93e7055"
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
    
    # Patch CMakeLists.txt to use the correct curl path
    inreplace "CMakeLists.txt" do |s|
      s.gsub! 'list(APPEND CMAKE_PREFIX_PATH "/opt/homebrew/opt/curl")',
              "list(APPEND CMAKE_PREFIX_PATH \"#{Formula["curl"].opt_prefix}\")"
      s.gsub! 'set(CURL_ROOT "/opt/homebrew/opt/curl")',
              "set(CURL_ROOT \"#{Formula["curl"].opt_prefix}\")"
      s.gsub! 'set(CURL_INCLUDE_DIR "/opt/homebrew/opt/curl/include")',
              "set(CURL_INCLUDE_DIR \"#{Formula["curl"].opt_include}\")"
      s.gsub! 'set(CURL_LIBRARY "/opt/homebrew/opt/curl/lib/libcurl.dylib")',
              "set(CURL_LIBRARY \"#{Formula["curl"].opt_lib}/libcurl.dylib\")"
    end
    
    # Modify llama.cpp CMakeLists.txt directly
    llama_cmake = File.read("llama.cpp/CMakeLists.txt")
    
    # Add curl include directories at the top of the file
    llama_cmake = "# Add curl include directories\ninclude_directories(#{Formula["curl"].opt_include})\n\n" + llama_cmake
    
    # Enable LLAMA_CURL
    llama_cmake.gsub!(/option\(LLAMA_CURL\s+"Enable libcurl for URL requests"\s+OFF\)/, 
                     'option(LLAMA_CURL           "Enable libcurl for URL requests" ON)')
    
    # Write the modified file back
    File.write("llama.cpp/CMakeLists.txt", llama_cmake)
    
    # Modify llama.cpp common CMakeLists.txt directly
    llama_common_cmake = File.read("llama.cpp/common/CMakeLists.txt")
    
    # Add direct link to curl library
    llama_common_cmake.gsub!(/target_link_libraries\(common PRIVATE llama\)/, 
                           "target_link_libraries(common PRIVATE llama)\ntarget_link_libraries(common PRIVATE #{Formula["curl"].opt_lib}/libcurl.dylib)")
    
    # Write the modified file back
    File.write("llama.cpp/common/CMakeLists.txt", llama_common_cmake)
    
    # Create a FindCURL.cmake file to help llama.cpp find curl
    mkdir_p "llama.cpp/cmake"
    File.write "llama.cpp/cmake/FindCURL.cmake", <<~EOS
      # Custom FindCURL.cmake for Homebrew
      set(CURL_FOUND TRUE)
      set(CURL_INCLUDE_DIRS "#{Formula["curl"].opt_include}")
      set(CURL_LIBRARIES "#{Formula["curl"].opt_lib}/libcurl.dylib")
      set(CURL_VERSION_STRING "#{Formula["curl"].version}")
      
      if(NOT TARGET CURL::libcurl)
        add_library(CURL::libcurl SHARED IMPORTED)
        set_target_properties(CURL::libcurl PROPERTIES
          INTERFACE_INCLUDE_DIRECTORIES "${CURL_INCLUDE_DIRS}"
          IMPORTED_LOCATION "${CURL_LIBRARIES}"
        )
      endif()
    EOS
    
    # Build everything in a single step
    mkdir_p "build"
    
    # Set environment for compilation
    ENV.append "CXXFLAGS", "-I#{buildpath}/llama.cpp"
    ENV.append "CXXFLAGS", "-I#{buildpath}/llama.cpp/common"
    ENV.append "CXXFLAGS", "-I#{buildpath}/llama.cpp/include"
    ENV.append "CXXFLAGS", "-I#{Formula["curl"].opt_include}"
    ENV.append "LDFLAGS", "-L#{Formula["curl"].opt_lib}"
    
    # Explicitly set CURL environment variables
    ENV["CURL_CONFIG"] = "#{Formula["curl"].opt_bin}/curl-config"
    
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
           "-DLLAMA_CURL=ON",
           "-DLLAMA_DIR=#{buildpath}/llama.cpp",
           "-DCMAKE_MODULE_PATH=#{buildpath}/llama.cpp/cmake",
           "-DCMAKE_PREFIX_PATH=#{Formula["curl"].opt_prefix}",
           "-DCURL_INCLUDE_DIR=#{Formula["curl"].opt_include}",
           "-DCURL_LIBRARY=#{Formula["curl"].opt_lib}/libcurl.dylib",
           "-DCURL_ROOT=#{Formula["curl"].opt_prefix}",
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
