# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'timeout'

module Exots
  class Runner
    attr_reader :pid, :socket_path, :pid_path

    def initialize(script, socket_path:, pid_path: nil, command: 'node', timeout: 5.0, auto_stop: true)
      @script = script
      @socket_path = socket_path
      @pid_path = pid_path
      @command = command
      @timeout = timeout
      @running = false
      @context = nil

      at_exit { stop } if auto_stop
    end

    def call(method, params = {})
      start unless @running
      @context.call(method, params)
    end

    def start
      return @context if @running

      env = {
        'EXOTS_SOCKET' => @socket_path
      }
      env['EXOTS_PID'] = @pid_path if @pid_path

      args = [@command, @script, '--socket', @socket_path]
      args += ['--pid', @pid_path] if @pid_path

      # Use exec form to avoid shell overhead
      @pid = Process.spawn(env, *args)

      begin
        wait_for_socket
        @running = true
        @context = Context.new(@socket_path)
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
      @context = nil
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
      # FileUtils.rm_rf(@tmp_dir) if @tmp_dir && File.directory?(@tmp_dir)
    end
  end
end
