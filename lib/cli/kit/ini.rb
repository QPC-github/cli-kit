# typed: true
require 'cli/kit'

module CLI
  module Kit
    # INI is a language similar to JSON or YAML, but simplied
    # The spec is here: https://en.wikipedia.org/wiki/INI_file
    # This parser includes supports for 2 very basic uses
    # - Sections
    # - Key Value Pairs (within and outside of the sections)
    #
    # [global]
    # key = val
    #
    # Nothing else is supported right now
    # See the ini_test.rb file for more examples
    #
    class Ini
      extend T::Sig

      sig { params(ini: T.untyped).returns(T.untyped) }
      attr_writer :ini

      sig { returns(T.untyped) }
      attr_reader :ini

      sig do
        params(path: T.untyped, config: T.untyped, default_section: T.untyped,
          convert_types: T.untyped).void
      end
      def initialize(path = nil, config: nil, default_section: nil, convert_types: true)
        @config = if path && File.exist?(path)
          File.readlines(path)
        elsif config
          config.lines
        end
        @ini = {}
        @current_key = nil
        @default_section = default_section
        @convert_types = convert_types
      end

      sig { returns(T.untyped) }
      def parse
        return @ini if @config.nil?

        @config.each do |l|
          l.strip!

          # If section, then set current key, this will nest the setting
          if section_designator?(l)
            @current_key = l

          # A new line will reset the current key
          elsif l.strip.empty?
            @current_key = nil

          # Otherwise set the values
          else
            k, v = l.split('=', 2).map(&:strip)
            set_val(k, v)
          end
        end
        @ini
      end

      sig { returns(T.untyped) }
      def git_format
        to_ini(@ini, git_format: true).flatten.join("\n")
      end

      sig { returns(T.untyped) }
      def to_s
        to_ini(@ini).flatten.join("\n")
      end

      private

      sig { params(h: T.untyped, git_format: T.untyped).returns(T.untyped) }
      def to_ini(h, git_format: false)
        optional_tab = git_format ? "\t" : ''
        str = []
        h.each do |k, v|
          if section_designator?(k)
            str << '' unless str.empty? || git_format
            str << k
            str << to_ini(v, git_format: git_format)
          else
            str << "#{optional_tab}#{k} = #{v}"
          end
        end
        str
      end

      sig { params(key: T.untyped, val: T.untyped).returns(T.untyped) }
      def set_val(key, val)
        return if key.nil? && val.nil?

        current_key = @current_key || @default_section
        if current_key
          @ini[current_key] ||= {}
          @ini[current_key][key] = typed_val(val)
        else
          @ini[key] = typed_val(val)
        end
      end

      sig { params(val: T.untyped).returns(T.untyped) }
      def typed_val(val)
        return val.to_s unless @convert_types
        return val.to_i if val =~ /^-?[0-9]+$/
        return val.to_f if val =~ /^-?[0-9]+\.[0-9]*$/
        val.to_s
      end

      sig { params(k: T.untyped).returns(T.untyped) }
      def section_designator?(k)
        k.start_with?('[') && k.end_with?(']')
      end
    end
  end
end
