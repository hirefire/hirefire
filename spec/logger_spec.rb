# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

require 'timecop'

describe HireFire::Logger do

  before do
    Timecop.freeze( Time.now )
  end

  context 'when logging regular messages' do
    it do
      HireFire::Logger.expects(:puts).with("[#{ Time.now.strftime("%Y-%m-%d %H:%M:%S") }][\e[32mHireFire\e[0m] This has been logged.")

      HireFire::Logger.message "This has been logged."
    end
  end

  context 'when logging error messages' do
    it do
      HireFire::Logger.expects(:puts).with("[#{ Time.now.strftime("%Y-%m-%d %H:%M:%S") }][\e[31mHireFire\e[0m] This has been logged.")

      HireFire::Logger.error "This has been logged."
    end
  end

  context 'when logging warn messages' do
    it do
      HireFire::Logger.expects(:puts).with("[#{ Time.now.strftime("%Y-%m-%d %H:%M:%S") }][\e[33mHireFire\e[0m] This has been logged.")

      HireFire::Logger.warn "This has been logged."
    end
  end

end
