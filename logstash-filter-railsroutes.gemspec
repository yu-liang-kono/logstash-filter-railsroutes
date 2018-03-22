Gem::Specification.new do |s|
  s.name = 'logstash-filter-railsroutes'
  s.version = '0.2.0'
  s.licenses = ['Apache License (2.0)']
  s.summary = 'Use rails route to match URI in logstash'
  s.description = 'This gem is a logstash plugin required to be installed on '\
                  'top of the Logstash core pipeline using '\
                  '$LS_HOME/bin/plugin install gemname. '\
                  'It recognizes URI as rails controller#action and '\
                  'parameters inside URI path.'
  s.authors = ['Yu Liang']
  s.email = 'yu.liang@thekono.com'
  s.homepage = 'https://github.com/yu-liang-kono/logstash-filter-railsroutes'
  s.require_paths = ['lib']

  # Files
  s.files = Dir[
    'lib/**/*',
    'spec/**/*',
    'vendor/**/*',
    '*.gemspec',
    '*.md',
    'CONTRIBUTORS',
    'Gemfile',
    'LICENSE',
    'NOTICE.TXT'
  ]
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { 'logstash_plugin' => 'true', 'logstash_group' => 'filter' }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core-plugin-api', '~> 2.0'
  s.add_runtime_dependency 'journey', '1.0.4'
  s.add_development_dependency 'logstash-devutils', '~> 1.3', '>= 1.3.1'
end
