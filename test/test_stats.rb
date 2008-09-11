
require File.join(File.dirname(__FILE__), %w[setup])

module TestLogging
module TestStats

  class TestSampler < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @sampler = ::Logging::Stats::Sampler.new('test')
    end

    def test_reset
      (1..10).each {|n| @sampler.sample n}

      assert_equal 55,  @sampler.sum
      assert_equal 385, @sampler.sumsq
      assert_equal 10,  @sampler.num
      assert_equal 1,   @sampler.min
      assert_equal 10,  @sampler.max
      assert_equal 10,  @sampler.last

      @sampler.reset

      assert_equal 0, @sampler.sum
      assert_equal 0, @sampler.sumsq
      assert_equal 0, @sampler.num
      assert_equal 0, @sampler.min
      assert_equal 0, @sampler.max
      assert_nil @sampler.last
    end

    def test_sample
      @sampler.sample 1

      assert_equal 1, @sampler.sum
      assert_equal 1, @sampler.sumsq
      assert_equal 1, @sampler.num
      assert_equal 1, @sampler.min
      assert_equal 1, @sampler.max
      assert_equal 1, @sampler.last

      @sampler.sample 2

      assert_equal 3, @sampler.sum
      assert_equal 5, @sampler.sumsq
      assert_equal 2, @sampler.num
      assert_equal 1, @sampler.min
      assert_equal 2, @sampler.max
      assert_equal 2, @sampler.last
    end

    def test_to_s
      (1..10).each {|n| @sampler.sample n}
      assert_equal(
        "[test]: SUM=55.000000, SUMSQ=385.000000, NUM=10, MEAN=5.500000, SD=3.027650, MIN=1.000000, MAX=10.000000",
        @sampler.to_s
      )
    end

    def test_to_a
      (1..10).each {|n| @sampler.sample n}
      assert_equal(
        ['test', 55, 385, 10, 5.5, @sampler.sd, 1, 10],
        @sampler.to_a
      )
    end

    def test_to_hash
      (1..10).each {|n| @sampler.sample n}
      assert_equal(
        {:name => 'test', :sum => 55, :sumsq => 385, :num => 10, :mean => 5.5, :sd => @sampler.sd, :min => 1, :max => 10},
        @sampler.to_hash
      )
    end

    def test_mean
      assert_equal 0, @sampler.mean

      @sampler.sample 10
      assert_equal 10, @sampler.mean

      @sampler.sample 20
      assert_equal 15, @sampler.mean
    end

    def test_sd
      assert_equal 0, @sampler.sd

      @sampler.sample 1
      assert_equal 0, @sampler.sd

      @sampler.sample 2
      assert_in_delta 0.707106781186548, @sampler.sd, 1e-10

      @sampler.sample 3
      assert_in_delta 1.0, @sampler.sd, 1e-10

      @sampler.sample 4
      assert_in_delta 1.29099444873581, @sampler.sd, 1e-10
    end

    def test_mark_and_tick
      10.times do
        @sampler.mark
        sleep 0.01
        @sampler.tick
      end

      assert_equal 10, @sampler.num
      assert_in_delta 0.01, @sampler.mean, 1e-3
    end
  end  # class TestSampler

  class TestTracker < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @tracker = ::Logging::Stats::Tracker.new
    end

    def test_mark
      assert @tracker.stats.empty?
      @tracker.mark 'foo'
      assert !@tracker.stats.empty?

      sampler = @tracker['foo']
      assert_equal 0, sampler.num
    end

    def test_tick
      assert @tracker.stats.empty?
      @tracker.tick 'foo'
      assert !@tracker.stats.empty?

      sampler = @tracker['foo']
      assert_equal 1, sampler.num
    end

    def test_sample
      assert @tracker.stats.empty?
      @tracker.sample 'foo', 1
      assert !@tracker.stats.empty?

      sampler = @tracker['foo']
      assert_equal 1, sampler.num
      assert_equal 1, sampler.last

      @tracker.sample 'foo', 2
      assert_equal 2, sampler.num
      assert_equal 2, sampler.last
      assert_equal 3, sampler.sum
    end

    def test_time
      assert @tracker.stats.empty?
      @tracker.time('foo') {sleep 0.05}
      assert !@tracker.stats.empty?

      sampler = @tracker['foo']
      assert_equal 1, sampler.num
      assert_in_delta 0.05, sampler.sum, 1e-3

      @tracker.time('foo') {sleep 0.05}
      assert_equal 2, sampler.num
      assert_in_delta 0.10, sampler.sum, 1e-2

      assert_raise(RuntimeError) do
        @tracker.time('foo') {raise 'Uh Oh!'}
      end
      assert_equal 3, sampler.num
    end

    def test_reset
      1.times {|n| @tracker.sample('foo', n)}
      2.times {|n| @tracker.sample('bar', n)}
      3.times {|n| @tracker.sample('baz', n)}

      assert_equal 1, @tracker['foo'].num
      assert_equal 2, @tracker['bar'].num
      assert_equal 3, @tracker['baz'].num

      @tracker.reset

      assert_equal 0, @tracker['foo'].num
      assert_equal 0, @tracker['bar'].num
      assert_equal 0, @tracker['baz'].num
    end

    def test_reentrant_synchronization
      assert_nothing_raised do
        @tracker.sync {
          @tracker.sample('foo', Math::PI)
          @tracker.reset
        }
      end
    end

    def test_periodically_run
      @tracker.periodically_run(0.1) {
        @tracker['foo'].tick
      }
      sleep 0.5
      @tracker.stop

      assert(@tracker['foo'].num > 1)
    end
  end  # class TestTracker

end  # module TestStats
end  # module TestLogging

# EOF
