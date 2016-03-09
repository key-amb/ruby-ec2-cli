# ec2it

Handy CLI for AWS EC2 operations.  
Mainly focused on instance operations.

```
# List instances
ec2it [-r <Role>] [-g <Group>]
ec2it list [OPTIONS]

# Start/Stop instance
ec2it start -i <INSTANCE_ID> [--dry-run]
ec2it start -n <Name> [--dry-run]
ec2it stop  -i <INSTANCE_ID> [--dry-run]
ec2it stop  -n <Name> [--dry-run]

# Launch/Terminate instance
ec2it launch -i <AMI_ID> -n <NAME_TAG> [-az AZ] [--dry-run]
ec2it terminate -i <INSTANCE_ID> [--dry-run]
ec2it terminate -n <Name> [--dry-run]

# List/Create/Delete AMI
ec2it list-ami [-r <Role>] [-g <Group>]
ec2it create-ami -i <INSTANCE_ID> [--dry-run]
ec2it create-ami -n <Name> [--dry-run]
ec2it delete-ami -i <AMI_ID> [--dry-run]

# Show help
ec2it help
```

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

# LICENSE

The MIT License (MIT)

Copyright (c) 2016 YASUTAKE Kiyoshi

