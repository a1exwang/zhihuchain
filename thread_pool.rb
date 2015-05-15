require 'thread'

class ThreadPool
  def initialize(size = 8)
    @threads = size
    @queue = Queue.new
  end
  def add_resource(res)
    @queue.enq res
  end
  def start_task(task)
    @threads.times do
      Thread.new do
        loop do
          task.call self, @queue.deq
        end
      end
    end
  end
end
