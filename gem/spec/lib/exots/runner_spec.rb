# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Exots::Runner do
  describe 'Integration' do
    # Adjust path to fixtures relative to this file or use absolute
    let(:script_path) { File.expand_path('../../fixtures/test_server.js', __dir__) }
    let(:tmp_dir) { Dir.mktmpdir('exots-spec-') }
    let(:socket_path) { File.join(tmp_dir, 'rpc.sock') }
    let(:pid_path) { File.join(tmp_dir, 'server.pid') }

    # Disable auto_stop to avoid accumulation of at_exit hooks during tests
    let(:runner) do
      described_class.new(
        script_path,
        socket_path: socket_path,
        pid_path: pid_path,
        command: 'node',
        auto_stop: false
      )
    end
    let(:context) { runner.start }

    after do
      runner.stop
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
      pid = runner.pid
      expect(pid).not_to be_nil

      # Check process exists
      expect { Process.getpgid(pid) }.not_to raise_error

      runner.stop

      # Check process is gone
      expect { Process.getpgid(pid) }.to raise_error(Errno::ESRCH)
    end

    it 'creates a pid file' do
      context # ensure started
      expect(File.exist?(pid_path)).to be true
      expect(File.read(pid_path).to_i).to eq(runner.pid)
    end

    describe 'Lazy Loading' do
      it 'starts lazily on call' do
        expect(runner.instance_variable_get(:@running)).to be false
        expect(runner.call('ping')).to eq('pong')
        expect(runner.instance_variable_get(:@running)).to be true
      end

      it 'start is idempotent' do
        context1 = runner.start
        context2 = runner.start
        expect(context1).to eq(context2)
      end
    end
  end
end
