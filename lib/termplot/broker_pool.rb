require "forwardable"

module Termplot
  class BrokerPool
    def initialize
      @brokers = []
      @mutex = Mutex.new
    end

    def broker_messages(queue, reader)
      mutex.synchronize do
        @brokers.push(Broker.new(queue, reader))
      end
    end

    def closed?
      mutex.synchronize do
        brokers.count > 0 &&
          brokers.all?(:closed?)
      end
    end

    def close_all_queues
      mutex.synchronize do
        brokers.each(&:close)
      end
    end

    def flush_messages
      mutex.synchronize do
        brokers.each(&:flush_queue)
      end
    end

    def pending_message_count
      mutex.synchronize do
        brokers.inject(0) do |sum, broker|
          sum + broker.pending_message_count
        end
      end
    end

    def empty?
      pending_message_count == 0
    end

    private
    attr_reader :brokers, :mutex

    Broker = Struct.new(:queue, :reader) do
      extend Forwardable
      def_delegators :queue, :closed?, :close

      def flush_queue
        num_samples = queue.size
        num_samples.times do
          reader << queue.shift
        end
      end

      def pending_message_count
        queue.size
      end
    end
  end
end
