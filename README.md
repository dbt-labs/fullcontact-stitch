# fullcontact-stitch

Creates a horizontally scalable fullcontact syncer using your Stitch account, your Fullcontact account, and your AWS account.

### Architecture

This is designed to scale horizontally, to not require management of an actual server, and to be deployable out of the box. There are two lambda functions, with a kinesis stream connecting them:

__Warehouse View > Fanout Lambda > Kinesis Stream > Worker Lambda__

- __Warehouse View__: view that you create in your warehouse that defines email addresses requiring updates from Fullcontact. This system will only sync those emails in this view.
- __Fanout Lambda__: queries your warehouse to get a list of emails to update via Fullcontact's Person API, and writes them out to the Kinesis Stream.
- __Kinesis Stream__: contains a list of email addresses that need to be updated. The number of shards in this stream defines the concurrency level with which this system will hit Fullcontact's API.
- __Worker Lambda__: automatically triggers when new records are added to the Kinesis stream. In batches of ten, queries the Fullcontact API and then persists the result to Stitch. This lambda runs eagerly, there is no rate limiting whatsoever.

### Gotchas

- You define the subnets where these lambdas run. These subnets __must__ be configured with NAT or some other way for the lambdas to access the internet without a public IP. If NAT is not set up, the lambdas will not be able to access Kinesis, Fullcontact or Stitch. If you aren't sure how to set this up, [AWS a lot of documentation about this](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Scenario2.html), and [many](https://gist.github.com/reggi/dc5f2620b7b4f515e68e46255ac042a7) [folks](http://evertrue.github.io/blog/2015/07/06/the-right-way-to-set-up-nat-in-ec2/) [on](http://www.tothenew.com/blog/configure-nat-instance-on-aws/) the internet have written about this topic.
- Also be sure to choose subnets where they can access your warehouse. Again, the lambdas are not assigned a static public IP, so you can't just provide access through security groups.

### Usage

#### Linux / macOS

Clone and enter this repository with:

```bash
git clone https://github.com/fishtown-analytics/fullcontact-stitch.git
cd fullcontact-stitch
```

Install terraform with:

```bash
bin/install
```

Copy the sample configuration, and update it with appropriate values for your integration:

```bash
cp config/sample.env config/config.env
... edit config/config.env ...
```

Build the python lambda package:

```bash
bin/build
```

Deploy with terraform:

```bash
bin/plan
bin/apply
```

---

Copyright &copy; 2017 Fishtown Analytics
