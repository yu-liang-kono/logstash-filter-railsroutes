# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require 'journey'

class LogStash::Filters::RailsRoutes < LogStash::Filters::Base
  config_name "railsroutes"

  config :routes_spec, :validate => :string, :required => true
  config :verb_source, :validate => :string, :required => true
  config :uri_source, :validate => :string, :required => true
  config :api_prefix, :validate => :string, :default => ''
  config :target, :validate => :string

  class RoutePattern
    ParseError = Class.new StandardError

    attr_reader :controller_action

    def self.parse_spec_line(line)
      sub_strings = line.split

      case sub_strings.size
      when 3
        verb, pattern, controller_action = sub_strings
        self.new(verb, pattern, controller_action)
      when 4
        _, verb, pattern, controller_action = sub_strings
        self.new(verb, pattern, controller_action)
      else
        fail ParseError, "Cannot parse route spec: #{line}"
      end
    end

    def initialize(verb, path, controller_action)
      if verb.include? '|'
        @verbs = verb.split('|').map(&:upcase)
      else
        @verbs = [verb.upcase]
      end

      @path_pattern = Journey::Path::Pattern.new(path)
      @controller_action = controller_action
    end

    def match(verb, uri)
      return nil unless @verbs.include?(verb)
      @path_pattern =~ uri
    end
  end

  public
  def register
    File.open(@routes_spec) do |f|
      @patterns = f.each_line.map do |line|
        begin
          RoutePattern.parse_spec_line(line)
        rescue RoutePattern::ParseError => err
          @logger.error(err.message)
          nil
        end
      end

      @patterns.compact!
    end
  end # def register

  public
  def filter(event)
    verb = event[@verb_source]
    uri = event[@uri_source]
    target = @target ? (event[@target] ||= {}) : event
    target['controller#action'] = nil

    if verb.nil? || uri.nil?
      @logger.error("Incomplete source: verb = '#{verb}', uri = '#{uri}'")
      return
    end

    if @api_prefix != ''
      if uri.start_with? @api_prefix
        uri = uri[@api_prefix.size..-1]
        uri = '/' + uri unless uri.start_with? '/'
      else
        @logger.warn("'#{uri}' does not start with '#{@api_prefix}'")
        return
      end
    end

    verb.upcase!
    match(verb, uri, target)

    unless target['controller#action']
      @logger.warn("Unrecognizable: #{verb} #{uri}")
    end

    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter

  private
  def match(verb, uri, target)
    @patterns.each do |pattern|
      next unless result = pattern.match(verb, uri)
      result.names.each_with_index { |name, ix| target[name] = result[ix + 1] }
      target['controller#action'] = pattern.controller_action
      break
    end
  end
end # class LogStash::Filters::RailsRoutes
