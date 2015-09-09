require 'spec_helper'

FIXTURE_DIR = "#{File.dirname(__FILE__)}/../fixtures/php/simple_brats"
OPTIONS_JSON = "#{FIXTURE_DIR}/.bp-config/options.json"

RSpec.shared_examples :a_deploy_of_php_app_to_cf do |runtime_version, web_server_binary, stack|

  web_server         = web_server_binary['name']
  web_server_version = web_server_binary['version']

  context "with php-#{runtime_version} and web_server: #{web_server}-#{web_server_version}", version: runtime_version do

    before :all do
      create_options_json({
        :runtime_version    => runtime_version,
        :web_server         => web_server,
        :web_server_version => web_server_version
      })
      @app = Machete.deploy_app(
        'php/simple_brats',
        name: "simple-php-#{Time.now.to_i}",
        buildpack: 'php-brat-buildpack',
        stack: stack
      )
      @browser = Machete::Browser.new(@app)
    end

    it 'should be running' do
      expect(@app).to be_running
      2.times do
        @browser.visit_path('/')
        expect(@browser).to have_body('Hello World!')
      end
    end

    it 'should have the correct version' do
      expect(@app).to have_logged("Installing PHP")
      expect(@app).to have_logged("PHP #{runtime_version}")
    end

    it 'should be loading redis' do
      expect(@app).to be_running
      2.times do
        @browser.visit_path('/?redis=true')
        expect(@browser).to have_body('Redis loads')
      end
    end

    it 'should not include any warning messages when loading all the extensions' do
      expect(@app).to_not have_logged(/The extension .* is not provided by this buildpack./)
    end

    after :all do
      Machete::CF::DeleteApp.new.execute(@app)
      FileUtils.rm OPTIONS_JSON
    end
  end
end

describe 'Deploying CF apps' do
  before(:all) { install_buildpack(buildpack: 'php') }
  after(:all) { cleanup_buildpack(buildpack: 'php') }

  def self.dependencies
    parsed_manifest(buildpack: 'php')
      .fetch('dependencies')
  end

  php_runtimes       = dependencies.select {|binary| binary['name'] == 'php' }

  valid_web_servers  = ['httpd', 'nginx']
  web_servers        = dependencies.select {|binary| valid_web_servers.include?(binary['name']) }

  ['cflinuxfs2'].each do |stack|
    context "on the #{stack} stack", stack: stack do

      php_runtimes.select { |php_runtime|
        php_runtime['cf_stacks'].include?(stack)
      }.each do |php_runtime|

        web_servers.select {|web_server|
          web_server['cf_stacks'].include?(stack)
        }.each do |web_server|

          it_behaves_like :a_deploy_of_php_app_to_cf, php_runtime['version'], web_server, stack
        end
      end
    end
  end
end

def create_options_json(options = {})
  runtime_version    = options[:runtime_version]
  web_server         = options[:web_server]
  web_server_version = options[:web_server_version]

  options = {
    'PHP_VM'                       => 'php',
    "PHP_VERSION"                  => runtime_version,
    'WEB_SERVER'                   => web_server,
    'PHP_EXTENSIONS'               => %w{amqp bz2 curl dba exif fileinfo ftp gd gettext gmp igbinary imagick imap intl ldap mailparse mbstring mcrypt memcache memcached mongo msgpack mysql mysqli openssl pdo pdo_sqlite pdo_mysql pdo_pgsql pgsql phalcon phpiredis pspell redis soap sockets sundown twig xsl zip zlib},
    "#{web_server.upcase}_VERSION" => web_server_version
  }

  File.open(OPTIONS_JSON, 'w') do |file|
    file << JSON.generate(options)
  end
end
