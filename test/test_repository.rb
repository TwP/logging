# $Id$

require 'test/setup.rb'

module TestLogging

  class TestRepository < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @repo = ::Logging::Repository.instance
    end

    def test_instance
      assert_same @repo, ::Logging::Repository.instance
    end

    def test_aref
      root = @repo[:root]
      assert_same root, @repo[:root]

      a = []
      assert_same @repo['Array'], @repo[Array]
      assert_same @repo['Array'], @repo[a]

      assert_not_same @repo['Array'], @repo[:root]
      assert_not_same @repo['A'], @repo['A::B']
    end

    def test_fetch
      assert_raise(IndexError) {@repo.fetch 'A'}
      assert_same @repo[:root], @repo.fetch(:root)
    end

    def test_parent
      @repo['A']
      @repo['A::B']
      @repo['A::B::C::D']
      @repo['A::B::C::E']
      @repo['A::B::C::F']

      assert_same @repo[:root], @repo.parent('A')
      assert_same @repo['A'], @repo.parent('A::B')
      assert_same @repo['A::B'], @repo.parent('A::B::C')
      assert_same @repo['A::B'], @repo.parent('A::B::C::D')
      assert_same @repo['A::B'], @repo.parent('A::B::C::E')
      assert_same @repo['A::B'], @repo.parent('A::B::C::F')

      @repo['A::B::C']

      assert_same @repo['A::B'], @repo.parent('A::B::C')
      assert_same @repo['A::B::C'], @repo.parent('A::B::C::D')
      assert_same @repo['A::B::C'], @repo.parent('A::B::C::E')
      assert_same @repo['A::B::C'], @repo.parent('A::B::C::F')

      @repo['A::B::C::E::G']

      assert_same @repo['A::B::C::E'], @repo.parent('A::B::C::E::G')
    end

    def test_children
      @repo['A']

      assert_equal [], @repo.children('A')

      @repo['A::B']
      a = [@repo['A::B::C::D'],
           @repo['A::B::C::E'],
           @repo['A::B::C::F']].sort

      assert_equal [@repo['A::B']], @repo.children('A')
      assert_equal a, @repo.children('A::B')
      assert_equal a, @repo.children('A::B::C')

      @repo['A::B::C']

      assert_equal [@repo['A::B::C']], @repo.children('A::B')
      assert_equal a, @repo.children('A::B::C')

      @repo['A::B::C::E::G']

      assert_equal a, @repo.children('A::B::C')
      assert_equal [@repo['A::B::C::E::G']], @repo.children('A::B::C::E')
    end

    def test_to_key
      assert_equal :root, @repo.send(:to_key, :root)
      assert_equal 'Object', @repo.send(:to_key, 'Object')
      assert_equal 'Object', @repo.send(:to_key, Object)
      assert_equal 'Object', @repo.send(:to_key, Object.new)

      assert_equal 'String', @repo.send(:to_key, String)
      assert_equal 'Array', @repo.send(:to_key, [])

      assert_equal 'blah', @repo.send(:to_key, 'blah')
      assert_equal :blah, @repo.send(:to_key, :blah)
    end

  end  # class TestRepository
end  # module TestLogging

# EOF
