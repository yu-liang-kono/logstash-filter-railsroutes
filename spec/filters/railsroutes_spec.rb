# encoding: utf-8
require 'spec_helper'
require "logstash/filters/railsroutes"

describe LogStash::Filters::RailsRoutes do
  subject { LogStash::Filters::RailsRoutes.new(config) }

  let(:attrs) { Hash[] }
  let(:event) { LogStash::Event.new(attrs) }
  let(:config) do
    {
      'verb_source' => 'verb',
      'uri_source' => 'uri',
      'routes_spec' => @route_spec_filename
    }
  end

  before(:each) do
    file = Tempfile.new('railsroutes')
    file.write(routes_spec_content)
    file.close
    @route_spec_filename = file.path
  end

  after(:each) do
    File.exists?(@route_spec_filename) && File.unlink(@route_spec_filename)
  end

  before(:each) do
    subject.register()
  end

  describe 'routes spec content' do
    context 'when prefix exists in routes spec' do
      let(:attrs) { Hash['verb', 'GET', 'uri', '/resources/1'] }
      let(:routes_spec_content) do <<-SPEC
        resources GET /resources/:id(.:format) resources#show
      SPEC
      end

      it 'can match' do
        subject.filter(event)
        expect(event['controller#action']).to eq 'resources#show'
      end
    end

    context 'when prefix does not exist in routes spec' do
      let(:attrs) { Hash['verb', 'GET', 'uri', '/resources/1'] }
      let(:routes_spec_content) do <<-SPEC
        GET /resources/:id(.:format) resources#show
      SPEC
      end

      it 'can match' do
        subject.filter(event)
        expect(event['controller#action']).to eq 'resources#show'
      end
    end
  end
end
