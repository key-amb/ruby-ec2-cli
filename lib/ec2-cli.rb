require 'aws-sdk-core'
require 'thor'

#require 'ec2-cli/image'

class EC2Cli < Thor
  package_name "ec2-cli"
  default_command :list

  desc 'list', 'List instances'
  def list
    cli().describe_instances.reservations[0].instances.each do |i|
      name_tags = i.tags.select { |t| t.key == 'Name' }
      puts [
        name_tags[0].value, i.instance_id, i.state.name,
        i.private_ip_address, i.public_ip_address
      ].join("\t")
    end
  end

  desc 'start', 'Start an instance'
  option 'instance-id', :required => true, :aliases => 'i'
  option 'dry-run', :type => :boolean, :default => false, :aliases => 'n'
  def start
    cli().start_instances({
      instance_ids: [options['instance-id']],
      dry_run:      options['dry-run'],
    })
  end

  desc 'stop', 'Stop an instance'
  option 'instance-id', :required => true, :aliases => 'i'
  option 'dry-run', :type => :boolean, :default => false, :aliases => 'n'
  def stop
    cli().stop_instances({
      instance_ids: [options['instance-id']],
      dry_run:      options['dry-run'],
    })
  end

  private

  def cli
    @cli ||= Aws::EC2::Client.new
  end
end
