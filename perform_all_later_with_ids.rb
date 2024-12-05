require 'active_job'
require 'benchmark'
require 'ostruct'

# Silence ActiveJob logs
ActiveJob::Base.logger = Logger.new(nil)

# Configure ActiveJob adapter
ActiveJob::Base.queue_adapter = :inline

# Normalized Data Job
class NormalizeDataJob < ActiveJob::Base
  def perform(id)
    # Simulate minimal processing work
  end
end

# Section class to generate IDs
class Section
  def self.limit(n)
    OpenStruct.new(ids: (1..n).to_a)
  end
end

def benchmark_job_execution(record_count)
  ids = Section.limit(record_count).ids
  
  result1 = Benchmark.measure do
    ids.map{ |id| NormalizeDataJob.perform_later(id) }
  end
  
  result2 = Benchmark.measure do
    jobs = ids.map{ |id| NormalizeDataJob.now(id) }
    ActiveJob.perform_all_later(jobs)
  end
  
  puts "Total Execution Time: #{result2.real.round(4)} seconds"
  puts "Total Execution Time: #{result1.real.round(4)} seconds"
end

benchmark_job_execution(100_000)

#Output
Total Execution Time: 501.4737 seconds
Total Execution Time: 498.2403 seconds
