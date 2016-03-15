# ec2it [![Build Status](https://travis-ci.org/key-amb/ruby-ec2it.svg?branch=master)](https://travis-ci.org/key-amb/ruby-ec2it)

Handy CLI for AWS EC2 operations.  
Mainly focused on instance operations.

```
# List(default)/Show instances
ec2it [-r <{Role}>] [-g <{Group}>] [-s <INSTANCE_STATE_NAME>] [-k <Key1> <Key2> ...]
ec2it list [OPTIONS]
ec2it show -i <INSTANCE_ID> [-k <Key1> <Key2> ...]
ec2it show -n <tag:Name> [OPTIONS]

# Start/Stop instance
ec2it start -i <INSTANCE_ID> [--dry-run]
ec2it start -n <tag:Name> [--dry-run]
ec2it stop  -i <INSTANCE_ID> [--dry-run]
ec2it stop  -n <tag:Name> [--dry-run]

# Launch/Terminate instance
ec2it launch -i <AMI_ID> -n <tag:Name> [-az AZ] [--dry-run]
ec2it terminate -i <INSTANCE_ID> [--dry-run]
ec2it terminate -n <tag:Name> [--dry-run]

# List/Create/Delete AMI
ec2it list-ami [-r <{Role}>] [-g <{Group}>]
ec2it create-ami -i <INSTANCE_ID> [--dry-run]
ec2it create-ami -n <tag:Name> [--dry-run]
ec2it delete-ami -i <AMI_ID> [--dry-run]

# Set role for Instance/AMI
ec2it set-role -r <{Role}> -i <INSTANCE_ID> [--dry-run]
ec2it set-role -r <{Role}> -n <tag:Name(of Instance)> [--dry-run]
ec2it set-role -r <{Role}> -i <AMI_ID> [--dry-run]

# Set group for Instance/AMI
ec2it set-group -r <{Group}> -i <INSTANCE_ID> [--dry-run]
ec2it set-group -r <{Group}> -n <tag:Name(of Instance)> [--dry-run]
ec2it set-group -r <{Group}> -i <AMI_ID> [--dry-run]

# Show help
ec2it help
```

As for `{Role}` and `{Group}`, see below description and samples.

# Configure

```sh
export AWS_REGION=ap-northeast-1 # Your AWS Region
export AWS_ACCESS_KEY_ID=<Your Access Key ID>
export AWS_SECRET_ACCESS_KEY=<Your Secret Access Key>
```

See also [AWS SDK for Ruby v2](http://docs.aws.amazon.com/sdkforruby/api/index.html)
for more information.

In addition, you need following envvar for some commands.

```sh
export EC2IT_CONFIG_PATH=/path/to/config.toml
```

You can see a sample of `config.toml` at [config/sample.toml](config/sample.toml).

## Role and Group

`{Role}` and `{Group}` are combination of tag values.
The keys of tags are configured as `.['tags']['roles']` and `.['tags']['groups']` .

Here is an example configuration:

```
[tags]
roles  = [ "Role1", "Role2"  ]
groups = [ "Group1", "Group2" ]
```

And below are examples.
They show when an instance or AMI have those tags, how their "role" and "group"
will be interpreted.

| Role1, Role2 | Group1, Group2 | role, group |
| ------------ | -------------- | ----------- |
| web, rails   | EC, production | web:rails, EC:production |
| db, master   | SNS, testing   | db:master, SNS:testing   |
| test         | personal       | test, personal   |

# LICENSE

The MIT License (MIT)

Copyright (c) 2016 YASUTAKE Kiyoshi

