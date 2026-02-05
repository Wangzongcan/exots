# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Exots::Runner do
  describe 'Integration' do
    # Adjust path to fixtures relative to this file or use absolute
    let(:script_path) { File.expand_path('../../fixtures/test_server.js', __dir__) }
    let(:runner) { described_class.new(script_path, command: 'node') }
    let(:context) { runner.start }

    after do
      runner.stop
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
  end
end
