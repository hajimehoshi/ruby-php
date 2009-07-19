# coding: utf-8

module ::Kernel

  alias echo print

  def null
    nil
  end

  NULL = nil

  def array(*args)
    if args.size == 1 and args[0].kind_of?(Hash)
      args[0]
    else
      [*args]
    end
  end
  
end

class ::Object

  def _php_nil?
    false
  end

  def _php_true?
    true
  end

  def _php_false?
    !_php_true?
  end

  def _php_eqeq?(rhs)
    if self.class == rhs.class
      if self.kind_of?(String) and rhs.kind_of?(String) and
          self._php_numeric? and rhs._php_numeric? and
          self.strip._ruby_eqeq?(self) and rhs.strip._ruby_eqeq?(rhs)
        self._php_to_f._ruby_eqeq?(rhs._php_to_f)
      elsif self.kind_of?(Float) and rhs.kind_of?(Float) and
          self.nan? and rhs.nan?
        true
      else
        self._ruby_eqeq?(rhs)
      end
    else
      if self.kind_of?(Float) and self.nan? and rhs.kind_of?(String)
        true
      elsif rhs.kind_of?(Float) and rhs.nan? and self.kind_of?(String)
        rhs._php_eqeq?(self)
      elsif self.kind_of?(NilClass)
        rhs._php_nil?
      elsif rhs.kind_of?(NilClass)
        self._php_nil?
      elsif self.kind_of?(TrueClass)
        rhs._php_true?
      elsif rhs.kind_of?(TrueClass)
        self._php_true?
      elsif self.kind_of?(FalseClass)
        rhs._php_false?
      elsif rhs.kind_of?(FalseClass)
        self._php_false?
      elsif self.kind_of?(Numeric) and rhs.kind_of?(Numeric)
        (self.nan? and rhs._ruby_eqeq?(0)) or
          (self._ruby_eqeq?(0) and rhs.nan?) or
          self.to_f._ruby_eqeq?(rhs.to_f)
      elsif self.kind_of?(Numeric) and rhs.respond_to?(:_php_to_f)
        self._php_to_f._ruby_eqeq?(rhs._php_to_f)
      elsif rhs.kind_of?(Numeric) and self.respond_to?(:_php_to_f)
        rhs._php_eqeq?(self)
      else
        self._ruby_eqeq?(rhs)
      end
    end
  end

end

class ::FalseClass

  def _php_nil?
    true
  end

  def _php_true?
    false
  end

end

class ::String

  def _php_nil?
    empty?
  end

  def _php_true?
    !empty? and !_ruby_eqeq?("0")
  end

  def _php_numeric?
    !!(self =~ /^\s*(([+-]?((\d+(\.\d+)?)|(\.\d+))(e[+-]?\d+)?)|(0x\d+))\s*$/i)
  end

  def _php_to_f
    if self =~ /^\s*0x(\d+)\s*$/i
      $1.to_i(16)
    else
      to_f
    end
  end

end

class ::Numeric

  def _php_nil?
    _ruby_eqeq?(0)
  end

  def _php_true?
    !_ruby_eqeq?(0)
  end

  def _php_to_f
    self
  end

end

class ::Float

  def _php_nil?
    super or nan?
  end

  def _php_true?
    super and !nan?
  end

end

class ::Integer

  def nan?
    false
  end

end

class ::Array

  def _php_nil?
    empty?
  end

  def _php_true?
    !empty?
  end

end

[::String, ::Fixnum, ::Bignum, ::Float, ::NilClass,
 ::TrueClass, ::FalseClass, ::Array].each do |klass|

  klass.class_eval do

    alias_method(:_ruby_eqeq?, :==)

    def ==(rhs)
      self._php_eqeq?(rhs)
    end

  end

end

if $0 == __FILE__

  require "minitest/autorun"
  require "stringio"

  class PHPizeTest < MiniTest::Unit::TestCase

    def test_echo
      io = StringIO.new
      begin
        orig_stdout = $stdout
        $stdout = io
        echo("hello, ", "world")
        io.rewind
        assert("hello, world" == io.read)
      ensure
        $stdout = orig_stdout
      end
    end

    def test_array
      assert_equal([1, 2, 3], array(1, 2, 3))
      assert_equal({"foo" => 1, "bar" => 2, "baz" => 3},
                   array("foo" => 1, "bar" => 2, "baz" => 3))
    end

    def test__php_numeric?
      assert_equal(false, ""._php_numeric?)
      assert_equal(false, "foo"._php_numeric?)
      assert_equal(true, "1"._php_numeric?)
      assert_equal(true, "0x1"._php_numeric?)
      assert_equal(true, "0X1"._php_numeric?)
      assert_equal(true, "1e0"._php_numeric?)
      assert_equal(true, "1E0"._php_numeric?)
      assert_equal(true, " 1e0 "._php_numeric?)
      assert_equal(true, " 1E0 "._php_numeric?)
      assert_equal(true, " +314e-2 "._php_numeric?)
      assert_equal(true, " -314e-2 "._php_numeric?)
      assert_equal(false, " *314e-2 "._php_numeric?)
      assert_equal(false, " 314f-2 "._php_numeric?)

    end

    def test__php_to_f
      assert_equal(1, "1"._php_to_f)
      assert_equal(1, "0x1"._php_to_f)
      assert_equal(1, "0X1"._php_to_f)
      assert_equal(1.0, "1e0"._php_to_f)
      assert_equal(1.0, "1E0"._php_to_f)
      assert_equal(1.0, " 1e0 "._php_to_f)
      assert_equal(1.0, " 1E0 "._php_to_f)
    end

    def test_eqeq
      es = [1, 1.0, "1", "0x1", "0X1", "1e0", "1E0"]
      es.each do |i|
        es.each do |j|
          assert(i == j, "#{i.inspect} == #{j.inspect}")
        end
      end
      assert("1a" == 1)
      assert("1a" == 1.0)
      assert(1 == "1a")
      assert(1.0 == "1a")
      es = [128, 128.0, "128", "0x80", "128e0", "+12.8e1", "1.28e2"]
      es.each do |i|
        es.each do |j|
          assert(i == j, "#{i.inspect} == #{j.inspect}")
        end
      end
      assert(128 != "+0x80")
      es = [-128, -128.0, "-128", "-128e0", "-12.8e1", "-1.28e2"]
      es.each do |i|
        es.each do |j|
          assert(i == j, "#{i.inspect} == #{j.inspect}")
        end
      end
      assert(-128 != "-0x80")
    end

    def test_space
      assert(128 == "12.8e1");
      assert(128 == "12.8e1 ");
      assert("128" == "12.8e1");
      assert("128" != "12.8e1 ");
    end

    def test_float
      assert(0.5 == "0.5")
      assert(0.5 == ".5")
      assert(0.5 == "+.5")
      assert(0.5 == "5e-1")
      assert(".5" == "+.5")
      assert(".5" == "5e-1")
    end

    def test_zero
      assert(0 == "")
      assert(0 == "0")
      assert(0 == "00")
      assert(0 == "-0")
      assert(0 != [])
      assert("" != "0")
      assert("0" == "00")
    end

    def test_nil
      assert(true != nil);
      assert(false == nil);
      assert(nil == nil);
      assert(0 == nil);
      assert(1 != nil);
      assert(2 != nil);
      assert('' == nil);
      assert(' ' != nil);
      assert('0' != nil);
      assert('0.0' != nil);
      assert('00' != nil);
      assert('0x0' != nil);
      assert('1' != nil);
      assert('foo' != nil);
      assert([] == nil);
      assert([0] != nil);

      assert(nil == 0);
      assert(nil != 1);
      assert(nil != 2);
      assert(nil == '');
      assert(nil != ' ');
      assert(nil != '0');
      assert(nil != '0.0');
      assert(nil != '00');
      assert(nil != '0x0');
      assert(nil != '1');
      assert(nil != 'foo');
      assert(nil == []);
      assert(nil != [0]);
    end

    def test_true
      assert(true == true);
      assert(false != true);
      assert(nil != true);
      assert(0 != true);
      assert(1 == true);
      assert(2 == true);
      assert('' != true);
      assert(' ' == true);
      assert('0' != true);
      assert('0.0' == true);
      assert('00' == true);
      assert('0x0' == true);
      assert('1' == true);
      assert('foo' == true);
      assert([] != true);
      assert([0] == true);

      assert(true != 0);
      assert(true == 1);
      assert(true == 2);
      assert(true != '' );
      assert(true == ' ');
      assert(true != '0');
      assert(true == '0.0');
      assert(true == '00');
      assert(true == '0x0');
      assert(true == '1');
      assert(true == 'foo');
      assert(true != []);
      assert(true == [0]);
    end

    def test_false
      assert(true != false);
      assert(false == false);
      assert(nil == false);
      assert(0 == false);
      assert(1 != false);
      assert(2 != false);
      assert('' == false);
      assert(' ' != false);
      assert('0' == false);
      assert('0.0' != false);
      assert('00' != false);
      assert('0x0' != false);
      assert('1' != false);
      assert('foo' != false);
      assert([] == false);
      assert([0] != false);

      assert(false == 0);
      assert(false != 1);
      assert(false != 2);
      assert(false == '' );
      assert(false != ' ');
      assert(false == '0');
      assert(false != '0.0');
      assert(false != '00');
      assert(false != '0x0');
      assert(false != '1');
      assert(false != 'foo');
      assert(false == []);
      assert(false != [0]);
    end

    def test_nan
      nan = 0.0/0.0
      assert(nan == nan)

      assert(nan == "NaN")
      assert(nan == "foo")
      assert(nan == "1")
      assert(nan == 0)
      assert(nan != 1)
      assert(nan == nil)
      assert(nan == false)

      assert("NaN" == nan)
      assert("foo" == nan)
      assert("1" == nan)
      assert(0 == nan)
      assert(1 != nan)
      assert(nil == nan)
      assert(false == nan)

      assert("NaN" != "nan")
    end

  end

end
