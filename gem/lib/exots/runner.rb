# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'timeout'

module Exots
  class Runner
    attr_reader :pid, :socket_path

    def initialize(script, command: 'node', timeout: 5.0)
      @script = script
      @command = command
      @timeout = timeout
      @running = false
    end

    def start
      raise Error, 'Process already running' if @running

      @tmp_dir = Dir.mktmpdir('exots-')
      @socket_path = File.join(@tmp_dir, 'rpc.sock')
      @pid_file = File.join(@tmp_dir, 'server.pid')

      env = {
        'EXOTS_SOCKET' => @socket_path,
        'EXOTS_PID' => @pid_file
      }

      # Use exec form to avoid shell overhead, but join command/script for simplicity if needed
      # Assuming command is in PATH
      @pid = Process.spawn(env, @command, @script)

      begin
        wait_for_socket
        @running = true
        Context.new(@socket_path)
      rescue StandardError
        stop
        raise
      end
    end

    def stop
      return unless @pid

      if process_running?
        Process.kill('TERM', @pid)
        begin
          Timeout.timeout(2) { Process.wait(@pid) }
        rescue Timeout::Error
          Process.kill('KILL', @pid)
          Process.wait(@pid)
        rescue Errno::ECHILD
          # Already gone
        end
      end
    rescue Errno::ESRCH
      # Process already gone
    ensure
      cleanup_files
      @running = false
      @pid = nil
    end

    private

    def wait_for_socket
      start_time = Time.now

      until File.exist?(@socket_path)
        raise ProcessError, "Timeout waiting for socket at #{@socket_path}" if Time.now - start_time > @timeout

        unless process_running?
          # Try to read stderr/stdout if we could, but for now just report exit
          raise ProcessError, 'Process exited unexpectedly'
        end

        sleep 0.1
      end
    end

    def process_running?
      return false unless @pid

      Process.getpgid(@pid)
      true
    rescue Errno::ESRCH
      false
    end

    def cleanup_files
      FileUtils.rm_rf(@tmp_dir) if @tmp_dir && File.directory?(@tmp_dir)
    end
  end
end
