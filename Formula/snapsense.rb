class Snapsense < Formula
  include Language::Python::Virtualenv
  
  desc "Intelligent screenshot renaming tool for Apple Silicon Macs using Claude AI"
  homepage "https://github.com/farhankaz/snapsense"
  url "https://github.com/farhankaz/snapsense/archive/refs/tags/0.1.0.tar.gz"
  sha256 "82cc57d7032d5dbd2ade5f557474af4a8ac5d00f160c4b97eeebc00ae8b2b103"
  license "MIT"
  
  depends_on "python@3.12"
  depends_on :macos
  depends_on arch: :arm64
  
  resource "anthropic" do
    url "https://files.pythonhosted.org/packages/e3/bb/af5c28b27039224b309ce21df38c2285072b17c7804efb1e604c47a6bdb7/anthropic-0.20.0.tar.gz"
    sha256 "f9f1a5213af4710d6e1f9b83208a4b158355d1a95eb4ae0906c7580aa0e0f1d1"
  end
  
  resource "watchdog" do
    url "https://files.pythonhosted.org/packages/95/a6/d6ef450393dac5734c63c40a131f66808d2e6f59f6165ab38c98fbe4e6ec/watchdog-3.0.0.tar.gz"
    sha256 "4d98a320595da7a7c5a18fc48cb633c2e73cda78f93cac2ef42d42bf609a33f9"
  end
  
  resource "configparser" do
    url "https://files.pythonhosted.org/packages/4b/c0/3a47084aca7a940ed1334f89ed2e67bcb42168c4f40c486e267fe71e7aa0/configparser-5.3.0.tar.gz"
    sha256 "8be267824b541c09b08db124917f48ab525a6c3e837011f3130781a224c57090"
  end

  def install
    # Install Python dependencies
    venv = virtualenv_create(libexec, "python3.12")
    venv.pip_install resources
    
    # Install the Python files manually
    libexec.install Dir["*.py"]
    
    # Create a wrapper script for snapsense
    (bin/"snapsense").write <<~EOS
      #!/bin/bash
      export PYTHONPATH="#{libexec}:$PYTHONPATH"
      exec "#{libexec}/bin/python" "#{libexec}/snapsense_cli.py" "$@"
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
    begin
      system "mkdir", "-p", "#{ENV["HOME"]}/.config/snapsense"
      system "ln", "-sf", "#{etc}/snapsense/config.ini", "#{ENV["HOME"]}/.config/snapsense/config.ini"
    rescue
      opoo "Could not create symlink for config file. You may need to manually create it:"
      opoo "  mkdir -p #{ENV["HOME"]}/.config/snapsense"
      opoo "  ln -sf #{etc}/snapsense/config.ini #{ENV["HOME"]}/.config/snapsense/config.ini"
    end
    
    # Create a symlink from the user's log directory to the Homebrew log
    begin
      system "mkdir", "-p", "#{ENV["HOME"]}/Library/Logs"
      system "ln", "-sf", "#{var}/log/snapsense/snapsense.log", "#{ENV["HOME"]}/Library/Logs/snapsense.log"
    rescue
      opoo "Could not create symlink for log file. You may need to manually create it:"
      opoo "  mkdir -p #{ENV["HOME"]}/Library/Logs"
      opoo "  ln -sf #{var}/log/snapsense/snapsense.log #{ENV["HOME"]}/Library/Logs/snapsense.log"
    end
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
