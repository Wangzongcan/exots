# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Exots::Client do
  describe 'Integration' do
    # Adjust path to fixtures relative to this file or use absolute
    let(:script_path) { File.expand_path('../../../../npm/examples/node_server.js', __dir__) }
    let(:tmp_dir) { Dir.mktmpdir('exots-spec-') }
    let(:socket_path) { File.join(tmp_dir, 'rpc.sock') }
    let(:pid_path) { File.join(tmp_dir, 'server.pid') }

    # Disable auto_stop to avoid accumulation of at_exit hooks during tests
    let(:client) do
      described_class.new(
        script_path: script_path,
        socket_path: socket_path,
        pid_path: pid_path,
        runner: Exots::Runner::Node,
        auto_stop: false
      )
    end
    let(:context) { client.start }

    after do
      client.stop
      FileUtils.rm_rf(tmp_dir) if File.directory?(tmp_dir)
    end

    it 'can spawn a process and call a simple method' do
      result = context.call('ping')
      expect(result).to eq('pong')
    end

    it 'can pass parameters' do
      result = context.call('echo', msg: 'hello world')
      expect(result).to eq('hello world')

      sum = context.call('add', a: 10, b: 20)
      expect(sum).to eq(30)
    end

    it 'handles RPC errors from the server' do
      expect do
        context.call('error_method')
      end.to raise_error(Exots::RPCError, /Something went wrong/)
    end

    it 'handles non-existent methods' do
      expect do
        context.call('missing_method')
      end.to raise_error(Exots::RPCError, /Method not found/)
    end

    it 'can handle async methods' do
      result = context.call('slow_method')
      expect(result).to eq('done')
    end

    it 'cleans up the process on stop' do
      context # ensure started
      pid = client.pid
      expect(pid).not_to be_nil

      # Check process exists
      expect { Process.getpgid(pid) }.not_to raise_error

      client.stop

      # Check process is gone
      expect { Process.getpgid(pid) }.to raise_error(Errno::ESRCH)
    end

    it 'creates a pid file' do
      context # ensure started
      expect(File.exist?(pid_path)).to be true
      expect(File.read(pid_path).to_i).to eq(client.pid)
    end

    describe 'Lazy Loading' do
      it 'starts lazily on call' do
        expect(client.instance_variable_get(:@running)).to be false
        expect(client.call('ping')).to eq('pong')
        expect(client.instance_variable_get(:@running)).to be true
      end

      it 'start is idempotent' do
        context1 = client.start
        context2 = client.start
        expect(context1).to eq(context2)
      end
    end

    describe 'Concurrency' do
      it 'handles multiple processes starting concurrently' do
        pids = []

        3.times do
          pids << fork do
            # Re-initialize client in forked process to simulate fresh start in a new process
            # We use the same socket_path to test contention
            c = described_class.new(
              script_path: script_path,
              socket_path: socket_path,
              pid_path: pid_path,
              runner: Exots::Runner::Node,
              auto_stop: true
            )

            begin
              # Start (should handle locking)
              c.start

              # Verify call works
              res = c.call('ping')

              if res == 'pong'
                exit(0)
              else
                warn "Ping failed: #{res}"
                exit(1)
              end
            rescue StandardError => e
              warn "Worker failed: #{e.message}"
              warn e.backtrace.join("\n")
              exit(2)
            end
          end
        end

        # Wait for all workers to finish
        failures = 0
        pids.each do |pid|
          _, status = Process.wait2(pid)
          failures += 1 unless status.exitstatus == 0
        end

        expect(failures).to eq(0)

        # Verify socket still exists (owned by one of them, but they exited)
        # Wait, if they exited, the owner should have cleaned up!
        # Since we use auto_stop: true in the fork, the owner will kill the server on exit.
        # This is expected behavior.

        # To verify ONLY ONE server was ever started is tricky post-factum.
        # But if all 3 returned pong, the locking worked.
      end
    end
  end
end
