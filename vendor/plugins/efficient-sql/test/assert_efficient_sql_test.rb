
#:stopdoc:

require 'rubygems'
require 'active_record'
require 'test/unit'
require 'assert_efficient_sql'
require 'yaml'
require 'optparse'
require 'erb'
require 'pathname'

#:startdoc:

class AssertEfficientSqlTest < Test::Unit::TestCase

  def setup #:nodoc:
    config_file = (rails_root + 'config/database.yml').to_s
    config = YAML.load(ERB.new(IO.read(config_file)).result)['test']
    ActiveRecord::Base.establish_connection(config)

    ActiveRecord::Base.connection.
      create_table(:foos) do |t|
        t.column :name, :string, :limit => 60
      end
    
    43.times{  Foo.create!(:name => 'whatever')  }
  end

  # If +assert_efficient_sql+ (generally) dislikes your arguments, 
  # it will print out its default options, each with an explanation
  #
  def test_help
    assert_stdout /invalid.*argument.*
                   verbose.*=\>.*false/mx do
      assert_efficient_sql(:help){}
    end  
  end

  def test_assert_efficient_sql
    assert_efficient_sql{  Foo.find(2)  }
  end
  
  # If your SQL is already efficient, use <b>:verbose</b> to diagnose 
  # <i>why</i> it's efficient.
  #
  def test_verbose
    assert_stdout /select_type/ do
      assert_efficient_sql :verbose do
        Foo.find_by_id(42)
      end
    end
  end

  # If your block did not call any SQL SELECT statements,
  # you probably need a warning!
  #
  def test_require_sql
    assert_flunked /no queries/ do
      assert_efficient_sql{}
    end
  end

  # This test case uses 
  # <code>assert_raise_message[http://www.oreillynet.com/onlamp/blog/2007/07/assert_raise_on_ruby_dont_just.html]</code> 
  # to demonstrate <code>assert_efficient_sql</code> failing:
  #
  def test_assert_inefficient_sql
    assert_flunked /Pessimistic.*
                    full.table.scan.*
                    Foo.Load/mx do
      assert_efficient_sql do
        Foo.find_by_sql('select * from foos a')
      end
    end
  end

  # One common pessimization is a query that reads thousands
  # of rows just to return a few. +assert_efficient_sql+ 
  # counts the rows hit in each phase of an SQL +SELECT+,
  # and faults if any row count exceeds <b>1,000</b>.
  # 
  # Adjust this count with <b><code>:throttle => 42</code></b>.
  # 
  def test_throttle
    101.times{|x|  Foo.create :name => "foo_#{ x }"  }

    assert_flunked /Pessimistic.*
                    more.than.*100.*
                    Foo.Load/mx do
      assert_efficient_sql :throttle => 100, :ALL => true do
        Foo.find(:all)
      end
    end
  end

  # Sometimes you need an +ALL+, even while other <code>assert_efficient_sql</code>
  # checks must pass. To positively declare we like +ALL+, pass it as the key of a
  # +true+ option into the assertion:
  #
  def test_assert_all
    assert_efficient_sql :ALL => true do
      Foo.find(:all)
    end
  end

  # If your +WHERE+ and +ORDER+ clauses are too complex, 
  # MySQL might need to write a file (or worse), just to
  # satisfy a query. +assert_efficient_sql+ detects this
  # pernicious situation:
  #
  def test_prevent_filesorts
    _exec %[ CREATE TABLE `t1` (
               `a` int(11) NOT NULL DEFAULT '0',
               `b` blob NOT NULL,
               `c` text NOT NULL,
               PRIMARY KEY (`a`,`b`(255),`c`(255)),
               KEY `t1ba` (`b`(10),`a`)
             ) ENGINE=InnoDB ]
    
    assert_flunked /Using.filesort/ do
      assert_efficient_sql do
        Foo.find_by_sql('SELECT a FROM t1 ORDER BY b')
      end
    end
  ensure
    _exec 'drop table t1' # ERGO if exist
  end

  def test_ALL_with_possible_keys
    _exec %[ CREATE TABLE `t2` (
               `a` int(11) NOT NULL DEFAULT '0',
               `b` blob,
               `c` int(11) NOT NULL,
                PRIMARY KEY (a)
             ) ENGINE=InnoDB ]
    
    assert_efficient_sql :ALL => true, :Using_filesort => true, :key => false do
      Foo.find_by_sql('SELECT a FROM t2 ORDER BY c')
    end

  ensure
    ActiveRecord::Base.connection.drop_table(:t2)  rescue nil
  end
  
  def test_with_keys
    #  FIXME
  end
  
  # <code>assert_efficient_sql</code> calls 
  # <code>SHOW SESSION STATUS</code> before and after
  # its sampled block. If you are seeking an advanced
  # pessimization, such as <code>Created_tmp_disk_tables</code>,
  # pass <code>:Created_tmp_disk_tables => 0</code>. The
  # assertion will compare difference in STATUS before
  # and after calling its block. A difference greater
  # than the allowed difference will trigger a fault.
  #
  # To test this, we simply detect a STATUS variable
  # which is not a warning.
  #
  def test_declare_futile_war_on_Innodb_rows_read
    assert_flunked /just.for.test.*
                    Innodb_rows_read/mx do
      assert_efficient_sql :diagnostic => 'just for test!',
                           :Innodb_rows_read => 0 do
        Foo.find(:all)
      end
    end
  end

  #  You can also nest the assertion, to provide different 
  #  options for different blocks. The assertion allows 
  #  this because your test might also have some other
  #  reason to use blocks
  #
  def test_nest
    outer_result = assert_efficient_sql do
      inner_result = assert_efficient_sql :ALL => true do
        Foo.find(:all)
      end
      
      assert_no_match /where/i, inner_result[0][0]
      Foo.find(42)
    end
    assert_match /where/i, outer_result[0][0]
  end

  def assert_flunked(gripe, &block) #:nodoc:
    assert_raise_message Test::Unit::AssertionFailedError, gripe, &block
  end  #  ERGO  move to assert{ 2.0 }, reflect, and leave there!
  
  def teardown #:nodoc:
    ActiveRecord::Base.connection.drop_table(:foos)  rescue nil
  end

end

#:enddoc:

class AssertNonMysqlTest < Test::Unit::TestCase

  #  The assertion requires MySQL. To peacefully coexist with 
  #  test rigs that use multiple adapters, we only warn, once,
  #  if MySQL is not found. If you don't need this warning,
  #  turn it off with :warn_mysql_required => false
  #
  def test_gently_forwarn_non_mysql_connectors
    ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', 
                                              :dbfile => ':memory:' )

    deny_stdout /requires MySQL/, 'disabled warning' do
      assert_efficient_sql :warn_mysql_required => false
    end
    
    assert_stdout /requires MySQL/, 'warn the first time' do
      assert_efficient_sql
    end
    
    deny_stdout /requires MySQL/, 'don\'t warn the second time' do
      assert_efficient_sql
    end
    
  ensure
    config_file = (rails_root + 'config/database.yml').to_s
    config = YAML.load(ERB.new(IO.read(config_file)).result)['test']
    ActiveRecord::Base.establish_connection(config)
  end

end


class Foo < ActiveRecord::Base; end


def rails_root  #  ERGO  is this used?
  return (Pathname.new(__FILE__).expand_path.dirname + '../../../..').expand_path
end
