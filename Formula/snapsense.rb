class Snapsense < Formula
  desc "Intelligent screenshot renaming tool for Apple Silicon Macs using Claude AI"
  homepage "https://github.com/farhankaz/snapsense"
  url "https://github.com/farhankaz/snapsense/archive/refs/tags/0.1.0.tar.gz"
  sha256 "82cc57d7032d5dbd2ade5f557474af4a8ac5d00f160c4b97eeebc00ae8b2b103"
  license "MIT"
  
  depends_on "python@3.12"
  depends_on :macos
  depends_on arch: :arm64

  def install
    # Create a virtual environment in the Homebrew prefix
    venv = virtualenv_create(libexec, "python3.12")
    
    # Install the required Python packages
    resources.each do |r|
      r.stage do
        system libexec/"bin/pip", "install", "-v", "--no-deps", "--no-binary", ":all:", "."
      end
    end

    # Install the main scripts
    bin.install "snapsense.py"
    bin.install "snapsense_cli.py"
    
    # Create a wrapper script for snapsense
    (bin/"snapsense").write <<~EOS
      #!/bin/bash
      export PYTHONPATH="#{libexec}/lib/python3.12/site-packages:$PYTHONPATH"
      exec "#{bin}/snapsense_cli.py" "$@"
    EOS
    
    # Make the wrapper script executable
    chmod 0755, bin/"snapsense"
    
    # Create config directory
    (etc/"snapsense").mkpath
    
    # Create default config if it doesn't exist
    config_file = etc/"snapsense/config.ini"
    unless config_file.exist?
      config_file.write <<~EOS
        [General]
        scan_directory = ~/Desktop
        screenshot_prefix = Screenshot
        max_retries = 3
        retry_delay = 2
      EOS
    end
    
    # Create logs directory
    (var/"log/snapsense").mkpath
  end

  def post_install
    # Create a symlink from the user's config directory to the Homebrew config
    system "mkdir", "-p", "#{ENV["HOME"]}/.config/snapsense"
    system "ln", "-sf", "#{etc}/snapsense/config.ini", "#{ENV["HOME"]}/.config/snapsense/config.ini"
    
    # Create a symlink from the user's log directory to the Homebrew log
    system "mkdir", "-p", "#{ENV["HOME"]}/Library/Logs"
    system "ln", "-sf", "#{var}/log/snapsense/snapsense.log", "#{ENV["HOME"]}/Library/Logs/snapsense.log"
  end

  def caveats
    <<~EOS
      SnapSense requires an Anthropic API key to function.
      Please set your API key in your environment:
      
      echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.zshrc
      source ~/.zshrc
      
      To start SnapSense:
        snapsense start
      
      To check status:
        snapsense status
      
      To stop SnapSense:
        snapsense stop
      
      To edit configuration:
        snapsense config
    EOS
  end

  test do
    # Check if the executable runs
    system "#{bin}/snapsense", "status"
  end
end
