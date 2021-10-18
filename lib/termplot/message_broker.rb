require "forwardable"

module Termplot
  class MessageBrokerPool
    def initialize
      @brokers = []
      @mutex = Mutex.new
      @on_message_callbacks = []
    end

    def broker(sender:, receiver:)
      mutex.synchronize do
        broker = MessageBroker.new(sender: sender, receiver: receiver)
        broker.on_message do |v|
          on_message_callbacks.each do |block|
            block.call(v)
          end
        end
        brokers.push(broker)
        broker
      end
    end

    def on_message(&block)
      mutex.synchronize do
        on_message_callbacks.push(block)
      end
    end

    def closed?
      mutex.synchronize do
        (brokers.count == 0) || brokers.all?(&:closed?)
      end
    end

    def shutdown
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
    attr_reader :brokers, :mutex, :on_message_callbacks
  end

  # Broker messages in a thread-safe way between a sender and a receiver.
  class MessageBroker
    def initialize(sender:, receiver:)
      @sender = sender
      @receiver = receiver
      @queue = Queue.new
      @on_message_callbacks = []

      register_callbacks
    end

    def on_message(&block)
      on_message_callbacks.push(block)
    end

    def pending_message_count
      queue.size
    end

    def flush_queue
      num_samples = queue.size
      num_samples.times do
        receiver << queue.shift
      end
    end

    def close
      queue.close
    end

    def closed?
      queue.closed?
    end

    private
    attr_reader :sender, :receiver, :queue, :on_message_callbacks

    def register_callbacks
      on_message_callbacks.push -> (value) { queue << value }

      sender.on_message do |value|
        on_message_callbacks.each do |block|
          block.call(value)
        end
      end
    end
  end
end
