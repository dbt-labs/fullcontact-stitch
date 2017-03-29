# fullcontact-stitch

Creates a horizontally scalable fullcontact syncer using your Stitch account, your Fullcontact account, and your AWS account.

### Architecture

This is designed to scale horizontally, to not require management of an actual server, and to be deployable out of the box. There are two lambda functions, with a kinesis stream connecting them:

__Warehouse View > Fanout Lambda > Kinesis Stream > Worker Lambda__

- __Warehouse View__: view that you create in your warehouse that defines email addresses requiring updates from Fullcontact. This system will only sync those emails in this view.
- __Fanout Lambda__: queries your warehouse to get a list of emails to update via Fullcontact's Person API, and writes them out to the Kinesis Stream.
- __Kinesis Stream__: contains a list of email addresses that need to be updated. The number of shards in this stream defines the concurrency level with which this system will hit Fullcontact's API.
- __Worker Lambda__: automatically triggers when new records are added to the Kinesis stream. In batches of ten, queries the Fullcontact API and then persists the result to Stitch. This lambda runs eagerly, there is no rate limiting whatsoever.

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

Deploy to terraform:

```bash
bin/plan
bin/apply
```
