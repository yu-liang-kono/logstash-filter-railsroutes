# encoding: utf-8
require_relative '../spec_helper'
require 'logstash/filters/railsroutes'

describe LogStash::Filters::RailsRoutes do
  before do
    Tempfile.open('railsroutes') do |f|
      f.write(routes_spec_content)
      @route_spec_filename = f.path
    end
  end

  after do
    File.exists?(@route_spec_filename) && File.unlink(@route_spec_filename)
  end

  describe 'routes spec content' do
    let(:config) do <<-CONFIG
      filter {
        railsroutes {
          verb_source => 'verb'
          uri_source => 'uri'
          routes_spec => '#{@route_spec_filename}'
        }
      }
    CONFIG
    end

    context 'when prefix exists in routes spec' do
      let(:routes_spec_content) do <<-SPEC
        resources GET /resources/:id(.:format) resources#show
      SPEC
      end

      sample('verb' => 'GET', 'uri' => '/resources/1') do
        expect(subject.get('controller#action')).to eq 'resources#show'
        expect(subject.get('id')).to eq '1'
        expect(subject.get('format')).to be nil
      end
    end

    context 'when prefix does not exist in routes spec' do
      let(:routes_spec_content) do <<-SPEC
        GET /resources/:id(.:format) resources#show
      SPEC
      end

      sample('verb' => 'GET', 'uri' => '/resources/1') do
        expect(subject.get('controller#action')).to eq 'resources#show'
        expect(subject.get('id')).to eq '1'
        expect(subject.get('format')).to be nil
      end
    end
  end

  describe 'api_prefix' do
    let(:config) do <<-CONFIG
      filter {
        railsroutes {
          verb_source => 'verb'
          uri_source => 'uri'
          routes_spec => '#{@route_spec_filename}'
          api_prefix => 'https://api.domain.com/'
        }
      }
    CONFIG
    end
    let(:api_prefix) { 'https://api.domain.com/' }
    let(:routes_spec_content) do <<-SPEC
      resources GET /resources/:id(.:format) resources#show
    SPEC
    end

    sample('verb' => 'GET', 'uri' => "https://api.domain.com/resources/1") do
      expect(subject.get('controller#action')).to eq 'resources#show'
      expect(subject.get('id')).to eq '1'
      expect(subject.get('format')).to be nil
    end
  end

  describe 'target' do
    let(:config) do <<-CONFIG
      filter {
        railsroutes {
          verb_source => 'verb'
          uri_source => 'uri'
          routes_spec => '#{@route_spec_filename}'
          target => 'target'
        }
      }
    CONFIG
    end
    let(:routes_spec_content) do <<-SPEC
      resources GET /resources/:id(.:format) resources#show
    SPEC
    end

    sample('verb' => 'GET', 'uri' => '/resources/1') do
      obj = subject.get('target')
      expect(obj['controller#action']).to eq 'resources#show'
      expect(obj['id']).to eq '1'
      expect(obj['format']).to be nil
    end
  end

  describe 'normalize uri' do
    let(:config) do <<-CONFIG
      filter {
        railsroutes {
          verb_source => 'verb'
          uri_source => 'uri'
          routes_spec => '#{@route_spec_filename}'
        }
      }
    CONFIG
    end
    let(:routes_spec_content) do <<-SPEC
      resources POST /resources(.:format)     resources#create
                GET  /resources/:id(.:format) resources#show
    SPEC
    end

    context 'when uri ends with a slash' do
      sample('verb' => 'POST', 'uri' => '/resources/') do
        expect(subject.get('controller#action')).to eq 'resources#create'
      end
    end

    context 'when uri has double slash' do
      sample('verb' => 'GET', 'uri' => '//resources//1') do
        expect(subject.get('controller#action')).to eq 'resources#show'
      end
    end
  end
end
