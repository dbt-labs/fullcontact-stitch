import boto3
import json
import os
import psycopg2
import time

kinesis_client = boto3.client('kinesis')


def log(s):
    now = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime())
    print('{} | {}'.format(now, s))


def enqueue_records(event, context, records):
    if len(records) > 500:
        log("ERROR: a max of 500 records can be queued at once")
        raise RuntimeError

    s = time.time()

    kinesis_client.put_records(
        Records=[{
            'Data': json.dumps(records).encode('utf-8'),
            'PartitionKey': json.dumps(records)
        } for record in records],
        StreamName=os.getenv('KINESIS_STREAM_NAME'))

    e = time.time()

    log('Wrote {} records to kinesis in {} seconds.'.format(
        len(records),
        round(e-s, 2)))


def handle_fanout(event, context, sql_generation_fn):
    connection = psycopg2.connect(
        host=os.getenv('POSTGRES_HOST'),
        user=os.getenv('POSTGRES_USER'),
        password=os.getenv('POSTGRES_PASSWORD'),
        port=os.getenv('POSTGRES_PORT'),
        dbname=os.getenv('POSTGRES_DBNAME'))

    sql = sql_generation_fn()
    cursor = connection.cursor()
    cursor.execute(sql)

    log("Enqueuing {} records.".format(cursor.rowcount))

    while True:
        records = cursor.fetchmany(500)

        if records == ():
            break

        enqueue_records(records)

    cursor.close()


def handle_worker(event, context, worker_fn):
    records = event.get('Records', {})

    for record in records:
        data = json.loads(record.get('data').decode('utf-8'))

        worker_fn(data)

    return "Handled {} records.".format(len(records))
