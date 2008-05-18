require 'assert2'

#:stopdoc:

  #  ERGO  reach out to an SQL lint?
  #  ERGO  cite, and peacibly coexist with mysql_helper.rb
  #  ERGO  report all failings, not one at a time
  #  ERGO  check for valid options
  #  ERGO  highlite the offending row in the analysis
  #  ERGO  cite http://hackmysql.com/selectandsort
#  ERGO  link from http://efficient-sql.rubyforge.org/files/README.html to 
#        project page
# ERGO hamachi.cc
#  ERGO  is flunk susceptible to <?> bug?
# ERGO One catch that jumps out right away is that you’re going to have to run this against a DB that looks a lot like production, since MySQL will punt to full table scans on smaller tables, and your unit test data probably qualifies as “smaller tables”.
#   (and cross-cite) http://enfranchisedmind.com/blog/2008/01/14/assert_efficient_sql/
#  ERGO  all with no possible keys is worse than ALL with possible keys
#  ERGO  retire _exec

class Array
  protected
    def qa_columnized_row(fields, sized)
      row = []
      fields.each_with_index do |f, i|
        row << sprintf("%0-#{sized[i]}s", f.to_s)
      end
      row.join(' | ')
    end

  public
    def qa_columnized
      sized = {}
      self.each do |row|
        row.values.each_with_index do |value, i|
          sized[i] = [sized[i].to_i, row.keys[i].length, value.to_s.length].max
        end
      end

      table = []
      table << qa_columnized_row(self.first.keys, sized)
      table << '-' * table.first.length
      self.each { |row| table << qa_columnized_row(row.values, sized) }
      table.join("\n   ") # Spaces added to work with format_log_entry
    end
end

module ActiveRecord
  module ConnectionAdapters
    class MysqlAdapter < AbstractAdapter
      attr_accessor :analyses

      private
        alias_method :select_without_analyzer, :select

        def select(sql, name = nil)
          query_results = select_without_analyzer(sql, name)

          if sql =~ /^select /i
            analysis = select_without_analyzer("EXPLAIN extended #{sql}", name)

#  TODO  use extended?
#  http://www.mysqlperformanceblog.com/2006/07/24/extended-explain/
#  
# ERGO          p select_without_analyzer('show warnings')
#         hence, show warnings caused by your queries, too

            if @logger and @logger.level <= Logger::INFO
              @logger.debug(
                @logger.silence do
                  format_log_entry("Analyzing #{ name }\n",
                    "#{ analysis.qa_columnized }\n"
                  )
                end
              ) if sql =~ /^select/i
            end
            
            explained = [sql, name, analysis.map(&:with_indifferent_access)]
            (@analyses ||= []) << explained
          end

          query_results
        end
    end
  end
end

module AssertEfficientSql; end

class AssertEfficientSql::SqlEfficiencyAsserter
  
  def initialize(options, context)
    @issues = []
    @options, @context = options, context
    @analyses = ActiveRecord::Base.connection.analyses
    @session_before = fetch_database_session
    yield
    check_for_query_statements    
    @session_after = fetch_database_session
    check_session_status

    @analyses.each do |@name, @sql, @analysis|
      @analysis.each do |@explanation|
        analyze_efficiency
      end
    end
    
    puts explain_all  if @options[:verbose]
  end

  def explain_all
    @analyses.map{ |@name, @sql, @analysis|
      format_explanation
    }.join("\n")
  end

  def fetch_database_session
    result = ActiveRecord::Base.connection.execute('show session status')
    hashes = []
    result.each_hash{|h|  hashes << h  }
    zz = {}.with_indifferent_access
    hashes.each{|v|  zz[v['Variable_name'].to_sym] = v['Value'].to_i  }
    return zz
  end

  def check(bool)
    @issues << yield  unless bool
  end

  def check_session_status
    @options.each do |key, value|
      if @session_before[key]  # ERGO and not true
        if (before = @session_before[key]) + value <=
           (after = @session_after[key])
          flunk "Status variable #{ key } incremented > #{ value },\n" +
                "from #{ before } to #{ after }, during one of these:\n" +
                 explain_all
        end
      end
    end
  end
  
  def analyze_efficiency
    rows = @explanation[:rows].to_i
    throttle = @options[:throttle]
    
    check rows <= throttle do
      "row count #{ rows } is more than :throttle => #{ throttle }"
    end
  
    check @options[:ALL] || 'ALL' != @explanation[:type] do  
      'full table scan'  
    end
    
    check @options[:Using_filesort] ||
          @explanation[:Extra] !~ /(Using filesort)/ do
      $1
    end
    
    flunk 'Pessimistic ' + format_explanation  unless @issues.empty?
  end
  
  def check_for_query_statements
    flunk 'assert_efficient_sql saw no queries!'  if @analyses.empty?
  end

  def flunk(why)
    @context.flunk @context.build_message(@options[:diagnostic], why)
  end
  
  def format_explanation
    @name = 'for ' + @name  unless @name.blank?

    return "\nquery #{ @name }\n" +
           @issues.join("\n") +
           "\n#{ @sql }\n   " + 
           @analysis.qa_columnized
  end

end
  
#:startdoc:


module AssertEfficientSql
  
  #  See: http://www.oreillynet.com/onlamp/blog/2007/07/assert_latest_and_greatest.html
 
  def assert_latest(*models, &block)
    models, diagnostic = _get_latest_args(models, 'assert')
    get_latest(models, &block) or _flunk_latest(models, diagnostic, true, block)
  end

  def _get_latest_args(models, what)
    diagnostic = nil
    diagnostic = models.pop if models.last.kind_of? String
  
    unless models.length > 0 and 
            (diagnostic.nil? or diagnostic.kind_of? String)
      raise "call #{ what }_latest(models..., diagnostic) with any number " +
            'of Model classes, followed by an optional diagnostic message'
    end
    return models, diagnostic
  end
  private :_get_latest_args
  
  def deny_latest(*models, &block)
    models, diagnostic = _get_latest_args(models, 'deny')
    return unless got = get_latest(models, &block)
    models = [got].flatten.compact.map(&:class)
   _flunk_latest(models, diagnostic, false, block)
  end

  def get_latest(models, &block)
    max_ids = models.map{|model| model.maximum(:id) || 0 }
    block.call
    index = -1
    return *models.map{|model|
      all = *model.find( :all,
                        :conditions => "id > #{max_ids[index += 1]}",
                        :order => "id asc" )
      all # * returns nil for [], 
            #     one object for [x], 
            #     or an array with more than one item
    }
  end
  
  def _flunk_latest(models, diagnostic, polarity, block)
    model_names = models.map(&:name).join(', ')
    rationale = "should#{ ' not' unless polarity 
                 } create new #{ model_names
                 } record(s) in block:\n\t\t#{ 
                    reflect_source(&block).gsub("\n", "\n\t\t") 
                 }\n"
#                 RubyNodeReflector::RubyReflector.new(block, false).result }"
                 # note we don't evaluate...
    flunk build_message(diagnostic, rationale)
  end
  private :_flunk_latest
  
  
  def _exec(cmd) #:nodoc:
    ActiveRecord::Base.connection.execute(cmd)
  end

  def assert_efficient_sql(options = {}, &block)
    options = { :verbose => true } if options == :verbose
    
    if options.class == Hash
      options.reverse_merge! default_options

      if current_adapter?(:MysqlAdapter)
        return assert_efficient_mysql(options, &block)
      else
        warn_adapter_required(options)
        block.call if block
      end
    else
      print_syntax
    end
    
    return []
  end

  class BufferStdout #:nodoc:
    def write(stuff)
      (@output ||= '') << stuff  
    end
    def output;  @output || ''  end
  end

  def assert_stdout(matcher = nil, diagnostic = nil)  #:nodoc:
    waz = $stdout
    $stdout = BufferStdout.new
    yield
    assert_match matcher, $stdout.output, diagnostic  if matcher
    return $stdout.output
  ensure
    $stdout = waz
  end

  def deny_stdout(unmatcher, diagnostic = nil, &block) #:nodoc:
    got = assert_stdout(nil, nil, &block)
    assert_no_match unmatcher, got, diagnostic
  end

  private
  
    def current_adapter?(type) #:nodoc:
      ActiveRecord::ConnectionAdapters.const_defined?(type) and
        ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters.const_get(type))
    end
    
    def warn_adapter_required(options)
      if options[:warn_mysql_required]
        puts 'assert_efficient_sql requires MySQL' unless $warned_once
        $warned_once = true
      end  
    end
    
    def assert_efficient_mysql(options, &block)
      outer_block_analyses = ActiveRecord::Base.connection.analyses
      ActiveRecord::Base.connection.analyses = []
      _exec('flush tables') if options[:flush]
      SqlEfficiencyAsserter.new(options, self, &block)
      return ActiveRecord::Base.connection.analyses  #  in case someone would like to use it!
    ensure
      ActiveRecord::Base.connection.analyses = outer_block_analyses
    end
    
    def syntax
      return {
        :diagnostic          => [nil  , 'supplementary message in failure reports'],
        :flush               => [true , 'flush memory before evaluation'],
        :throttle            => [1000 , 'maximum permitted rows scanned'],
        :Using_filesort      => [false, 'permission to write a temporary file to sort'],
        :verbose             => [false, 'if the test passes, print the EXPLAIN'],
        :warn_mysql_required => [true , 'disable the spew advising we only work with MySQL'] }
    end
    
    def default_options
      options = syntax.dup
      options.each{|k,(v,m)| options[k] = v}
      return options
    end
    
    def print_syntax
      puts "\n\nassert_efficient_sql called with invalid argument.\n"
      puts "  __flag__            __default__  __effect__"
    
      syntax.each do |k,(v,m)|
        printf "   :%-14s =>   %-8s # %s\n", k, v.inspect, m
      end
    end
  
end

#:stopdoc:
Test::Unit::TestCase.send :include, AssertEfficientSql