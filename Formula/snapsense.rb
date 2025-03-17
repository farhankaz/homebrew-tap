class Snapsense < Formula
  desc "Intelligent screenshot renaming tool for Apple Silicon Macs using Claude AI"
  homepage "https://github.com/farhankaz/snapsense"
  url "https://github.com/farhankaz/snapsense/archive/refs/tags/0.1.0.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "MIT"
  
  depends_on "python@3.12"
  depends_on :macos
  depends_on arch: :arm64

  resource "anthropic" do
    url "https://files.pythonhosted.org/packages/0f/43/9a0f2e3a93f1e0a29a3e6b4a4b5eef8e9a9d30c6a2b1e5ea4b6a0b8a1e4/anthropic-0.18.1.tar.gz"
    sha256 "6b2b5c5e2e9d6c1e9c7262e35e2a94d79a1e3c8a5e3e4e1d8f1b9c7a8e1e9b9a"
  end

  resource "watchdog" do
    url "https://files.pythonhosted.org/packages/95/a6/d6ef450ed3eb3ab185f9f85ded8e41a064a2e9c6b3c93ff3304dfc1a5d0/watchdog-3.0.0.tar.gz"
    sha256 "4d98a320595da7a7c5a18fc48cb633c2e73cda78f93cac2ef42d42bf609a33f9"
  end

  resource "configparser" do
    url "https://files.pythonhosted.org/packages/82/97/930be4777f6b08fc7c248e4ee45ad6e7a9e0f32efb537cf0e32bb32a36c0/configparser-5.3.0.tar.gz"
    sha256 "8be267824b541c09b08db124917f48ab525a6c3e837011f3130781a224c57090"
  end

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
