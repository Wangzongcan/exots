# frozen_string_literal: true

require 'socket'
require 'tmpdir'
require 'fileutils'
require 'timeout'

module Exots
  class Client
    attr_reader :pid, :socket_path, :pid_path

    def initialize(script_path:, socket_path:, pid_path: nil, runner: Runner::Node, timeout: 5.0, auto_stop: true)
      @script_path = script_path
      @socket_path = socket_path
      @pid_path = pid_path
      @runner = runner
      @timeout = timeout
      @running = false
      @context = nil
      @owner = false
      @owner_pid = nil

      at_exit { stop } if auto_stop
    end

    def call(method, params = {})
      start unless @running
      @context.call(method, params)
    end

    def start
      return @context if @running

      lock_path = "#{@socket_path}.lock"
      # Ensure lock directory exists
      FileUtils.mkdir_p(File.dirname(lock_path))

      File.open(lock_path, File::RDWR | File::CREAT, 0o644) do |f|
        f.flock(File::LOCK_EX)

        if server_alive?
          @running = true
          @owner = false
        else
          File.unlink(@socket_path) if File.exist?(@socket_path)
          spawn_process
          wait_for_socket
          @running = true
          @owner = true
          @owner_pid = Process.pid
        end
      end

      @context = Context.new(@socket_path)
    end

    def stop
      if @owner && @pid && Process.pid == @owner_pid && process_running?
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
      if @owner && Process.pid == @owner_pid
        cleanup_files
        File.unlink("#{@socket_path}.lock") if File.exist?("#{@socket_path}.lock")
      end
      @running = false
      @pid = nil
      @context = nil
      @owner = false
      @owner_pid = nil
    end

    private

    def server_alive?
      return false unless File.exist?(@socket_path)

      begin
        UNIXSocket.new(@socket_path).close
        true
      rescue Errno::ECONNREFUSED, Errno::ENOENT
        false
      end
    end

    def spawn_process
      env = {
        'EXOTS_SOCKET' => @socket_path
      }
      env['EXOTS_PID'] = @pid_path if @pid_path

      # Use exec form to avoid shell overhead
      args = @runner.command(@script_path, @socket_path, @pid_path)
      @pid = Process.spawn(env, *args)
    end

    def wait_for_socket
      start_time = Time.now

      until server_alive?
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
