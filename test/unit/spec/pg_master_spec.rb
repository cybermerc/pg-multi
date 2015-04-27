# encoding: UTF-8
require_relative 'spec_helper'

describe 'pg-multi::pg_master' do
  before do
    allow(::File).to receive(:symlink?).and_return(false)
    stub_command("psql -c \"SELECT rolname FROM pg_roles WHERE rolname='repl'\" | grep repl").and_return(false)
    stub_command('ls /var/lib/postgresql/9.3/main/recovery.conf').and_return(true)
    stub_command('ls /var/lib/pgsql/9.3/data/recovery.conf').and_return(true)
  end

  platforms = {
    'ubuntu' => ['12.04', '14.04'],
    'centos' => ['6.6']
  }

  platforms.each do |platform, versions|
    versions.each do |version|
      context "on #{platform.capitalize} #{version}" do
        let(:chef_run) do
          ChefSpec::SoloRunner.new(platform: platform, version: version) do |node|
            node.set['postgresql']['password']['postgres'] = 'test123'
            node.set['postgresql']['version'] = '9.3'
            node.set['pg-multi']['replication']['user'] = 'repl'
            node.set['pg-multi']['replication']['password'] = 'useagudpasswd'
            node.set['testkitchen'] = false
          end.converge(described_recipe)
        end

        it 'sets the hba.conf' do
          expect(chef_run).to create_pg_hba_config('default')
        end

        it 'includes pg-multi::default' do
          expect(chef_run).to include_recipe('pg-multi::default')
        end

        it 'sets repl user' do
          expect(chef_run).to create_pg_repluser('default')
        end
      end
    end
  end
end
