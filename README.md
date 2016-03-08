# ec2-cli

Handy CLI for AWS EC2 operations.  
Mainly focused on instance operations.

```
# List instances
ec2-cli
ec2-cli list

# Start/Stop instance
ec2-cli start -i <INSTANCE_ID> [-n|--dry-run]
ec2-cli stop  -i <INSTANCE_ID> [-n|--dry-run]

# Create AMI
ec2-cli create-ami -i <INSTANCE_ID> [-n|--dry-run]
```

# Configure

```sh
export AWS_REGION=ap-northeast-1 # Your AWS Region
export AWS_ACCESS_KEY_ID=<Your Access Key ID>
export AWS_SECRET_ACCESS_KEY=<Your Secret Access Key>
```

See also [AWS SDK for Ruby v2](http://docs.aws.amazon.com/sdkforruby/api/index.html)
for additional information.

In addition, you need following envvar for some commands.

```sh
export AWS_ACCOUNT_ID=XXXXXXXXXXXX # Your AWS Account ID
```

# LICENSE

The MIT License (MIT)

Copyright (c) 2016 YASUTAKE Kiyoshi

