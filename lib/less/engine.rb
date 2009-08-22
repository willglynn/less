$:.unshift File.dirname(__FILE__)

require 'engine/nodes'

begin
  require 'engine/parser'
rescue LoadError
  Treetop.load File.join(LESS_GRAMMAR, 'common.tt')
  Treetop.load File.join(LESS_GRAMMAR, 'entity.tt')
  Treetop.load File.join(LESS_GRAMMAR, 'less.tt')
end

module Less
  class Engine
    attr_reader :css, :less
    
    def initialize obj, options = {}
      @less = if obj.is_a? File
        @path = File.dirname File.expand_path(obj.path)
        obj.read
      elsif obj.is_a? String
        obj.dup
      else
        raise ArgumentError, "argument must be an instance of File or String!"
      end
      
      @parser = StyleSheetParser.new
      @options = options
      
      # Make the parser input respond_to :less_engine, returning us
      @less.instance_variable_set(:@less_engine, self)
      @less.instance_eval { def less_engine; @less_engine; end }
    end
    
    def parse build = true, env = Node::Element.new
      self.prepare
      root = @parser.parse(@less)
      
      return root unless build
      
      if root
        @tree = root.build env.tap {|e| e.file = @path }
      else
        raise SyntaxError, @parser.failure_message
      end

      @tree
    end
    alias :to_tree :parse
    
    def to_css
      @css || @css = self.parse.group.to_css
    end
    
    def prepare
      @less.gsub!(/\r\n/, "\n")
      @less.gsub!(/\t/, '  ')
    end
    
    # :nodoc:
    attr_reader :options
  end
end