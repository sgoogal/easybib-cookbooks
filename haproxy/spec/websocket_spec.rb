require_relative 'spec_helper.rb'

describe 'haproxy::configure' do
  let(:runner) do
    ChefSpec::Runner.new do |node|
      node.override[:opsworks][:stack][:name] = 'chefspec'
      node.override[:opsworks][:instance][:region][:id] = 'local'
      node.override[:opsworks][:layers][:nginxphpapp][:instances] = {
        'php-app-server-1' => {
          'private_dns_name' => 'php.app.server.1.tld'
        }
      }
      node.override[:opsworks][:layers][:nodeapp][:instances] = {
        'node-app-server-1' => {
          'private_dns_name' => 'node.app.server.1.tld'
        },
        'node-app-server-2' => {
          'private_dns_name' => 'node.app.server.2.tld'
        }
      }
      node.override[:haproxy] = {
        :websocket_layers => {
          :nodeapp => {
            :port => 8123,
            :health_check => {
              :url => '/foo?bar=123',
              :host => 'ws.example.com'
            }
          }
        }
      }
    end
  end
  let(:chef_run) { runner.converge('haproxy::configure') }
  let(:node) { runner.node }

  describe 'forward servers set - check settings' do
    before do
      stub_command('pgrep haproxy').and_return(false)
    end

    it 'Configures haproxy' do

      expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
        :user => 'root',
        :group => 'root',
        :mode => 0644
      )

      expected = [
        # backend
        'server php-app-server-1 php.app.server.1.tld:80 weight 10 maxconn 255 rise 2 fall 3 check inter 3000',
        'server node-app-server-1 node.app.server.1.tld:8123 weight 10 maxconn 10000 rise 2 fall 3 check inter 3000',
        'server node-app-server-2 node.app.server.2.tld:8123 weight 10 maxconn 10000 rise 2 fall 3 check inter 3000',
        'GET /foo?bar=123 HTTP/1.1\r\nHost:\ ws.example.com\r\nConnection:\ Upgrade\r\nUpgrade:\ ' \
          'websocket\r\nSec-WebSocket-Key:\ haproxy\r\nSec-WebSocket-Version:\ 13\r\n' \
          'Sec-WebSocket-Protocol:\ echo-protocol',
        'http-check expect status 101',
        # frontend
        'use_backend nodeapp_websocket_app_servers if hdr_connection_upgrade hdr_upgrade_websocket'
      ]
      expected.each do |content|
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content(content)
      end

    end
  end
end
