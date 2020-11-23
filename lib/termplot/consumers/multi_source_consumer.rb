# frozen_string_literal: true

require "termplot/file_config"
require "termplot/producers"

module Termplot
  module Consumers
    class MultiSourceConsumer < BaseConsumer
      def positioned_widgets
        @positioned_widgets ||= config.positioned_widgets
      end

      def register_producers_and_brokers
        config.widget_configs.each do |widget_config|
          producer = build_producer(widget_config)
          broker_pool.broker(sender: producer, receiver: widget_config.widget)
          producer_pool.add_producer(producer)
        end
      end

      private
      def config
        @config ||= FileConfig.new(options).parse_config
      end

      def build_producer(widget_config)
        Termplot::Producers::CommandProducer.new(
          widget_config.producer_options
        )
      end
    end
  end
end
