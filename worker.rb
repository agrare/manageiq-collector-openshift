$LOAD_PATH.unshift(".")

require 'trollop'
require 'manageiq/providers/openshift/collector'

def main args
  collector = ManageIQ::Providers::Openshift::Collector.new(args[:ems_id], args[:hostname], args[:port], args[:token])
  collector.run
end

def parse_args
  args = Trollop.options do
    opt :token,    "token",    :type => :string
    opt :hostname, "hostname", :type => :string
    opt :port,     "port",     :type => :int
    opt :ems_id,   "ems-id",   :type => :int
  end

  args[:hostname] ||= ENV["COLLECTOR_HOSTNAME"]
  args[:port]     ||= ENV["COLLECTOR_PORT"]
  args[:token]    ||= ENV["COLLECTOR_TOKEN"]
  args[:ems_id]   ||= ENV["COLLECTOR_EMS_ID"]

  raise Trollop::CommandlineError, "--token required"    if args[:token].nil?
  raise Trollop::CommandlineError, "--hostname required" if args[:hostname].nil?
  raise Trollop::CommandlineError, "--port required"     if args[:port].nil?
  raise Trollop::CommandlineError, "--ems-id required"   if args[:ems_id].nil?

  args
end

args = parse_args

main args
