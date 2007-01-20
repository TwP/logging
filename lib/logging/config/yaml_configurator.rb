# $Id$

require 'yaml'
require 'logging'

module Logging
module Config

  #
  #
  #
  class YamlConfigurator

    class Error < StandardError; end

    class << self
      #
      # call-seq:
      #    load( file )
      #
      def load( file )
        io, close = nil, false
        case file
        when String
          io = File.open(file, 'r')
          close = true
        when IO: io = file
        else raise Error, 'expecting a filename or a File' end

        begin new(io).load; ensure; io.close if close end
        nil
      end
    end  # class << self

    #
    # call-seq:
    #    YamlConfigurator.new( io )
    #
    def initialize( io )
      YAML.load_documents(io) do |doc|
        @config = doc['logging_config']
        break if @config.instance_of?(Hash)
      end

      unless @config.instance_of?(Hash)
        raise Error, "Key 'logging_config' not defined in YAML configuration"
      end
    end
    private :initialize

    #
    # call-seq:
    #    load
    #
    def load
      pre_config @config['pre_config']
      appenders @config['appenders']
      loggers @config['loggers']

      p @config
    end

    #
    # call-seq:
    #    pre_config( config )
    #
    def pre_config( config )
      # if no pre_config section was given, just create an empty hash
      # we do this to ensure that some logging levels are always defined
      config ||= Hash.new

      # define levels
      levels = config['define_levels']
      ::Logging.define_levels(levels) unless levels.nil?

      # format as
      format = config['format_as']
      ::Logging.format_as(format) unless format.nil?

      # grab the root logger and set the logging level
      root = ::Logging::Logger.root
      if config.has_key?('root')
        root.level = config['root']['level']
      end
    end

    #
    # call-seq:
    #    appenders( ary )
    #
    def appenders( ary )
      return if ary.nil?

      ary.each {|h| appender(h)}
    end

    #
    # call-seq:
    #    loggers( ary )
    #
    def loggers( ary )
      return if ary.nil?

      ary.each do |config|
        name = config['name']
        raise Error, 'Logger name not given' if name.nil?

        l = Logging::Logger.new name
        l.level = config['level'] if config.has_key?('level')
        l.additive = config['additive']
        l.trace = config['trace']

        if config.has_key?('appenders')
          l.appenders = config['appenders'].map {|n| ::Logging::Appender[n]}
        end
      end
    end

    #
    #
    #
    def appender( config )
      return if config.nil?
      config = config.dup

      type = config.delete('type')
      raise Error, 'Appender type not given' if type.nil?

      name = config.delete('name')
      raise Error, 'Appender name not given' if type.nil?

      config['layout'] = layout(config.delete('layout'))

      clazz = ::Logging::Appenders.const_get type
      clazz.new(name, config)
    end

    #
    #
    #
    def layout( config )
      return if config.nil?
      config = config.dup

      type = config.delete('type')
      raise Error, 'Layout type not given' if type.nil?

      clazz = ::Logging::Layouts.const_get type
      clazz.new config
    end

  end  # class YamlConfigurator
end  # module Config
end  # module Logging

# EOF
