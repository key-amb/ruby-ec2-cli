require 'optparse'
require 'ostruct'

require 'pp'

module EC2Cli
  class << self
    def parse_option
      options = OpenStruct.new
      OptionParser.new do |opts|
        opts.on('-i', '--instance-id ID', 'instance-id') do |id|
          options.instance_id = id
        end
        opts.on('-n', '--dry-run', 'Dry-run') do |dr|
          options.dry_run = true
        end
      end.parse!
      options
    end

    def list(cli)
      cli.describe_instances.reservations[0].instances.each do |i|
        name_tags = i.tags.select { |t| t.key == 'Name' }
        puts [
          name_tags[0].value, i.instance_id, i.state.name,
          i.private_ip_address, i.public_ip_address
        ].join("\t")
      end
    end

    def start(cli)
      options = parse_option
      cli.start_instances({
        instance_ids: [options.instance_id],
        dry_run:      options.dry_run,
      })
    end

    def stop(cli)
      options = parse_option
      cli.stop_instances({
        instance_ids: [options.instance_id],
        dry_run:      options.dry_run,
      })
    end
  end
end
