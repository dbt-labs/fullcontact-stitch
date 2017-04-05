import base64
import boto3
import json
import os
import psycopg2
import time
import traceback

kinesis_client = boto3.client('kinesis')


def log(s):
    now = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime())
    print('{} | {}'.format(now, s))


def enqueue_records(records):
    if len(records) > 500:
        log("ERROR: a max of 500 records can be queued at once")
        raise RuntimeError

    s = time.time()

    log('Writing {} records to kinesis.'.format(len(records)))

    response = kinesis_client.put_records(
        Records=[{
            'Data': json.dumps(record).encode('utf-8'),
            'PartitionKey': json.dumps(record)
        } for record in records],
        StreamName=os.getenv('KINESIS_STREAM_NAME'))

    e = time.time()

    if response.get('FailedRecordCount'):
        for record in records:
            if response.get('ErrorCode'):
                if response.get('ErrorCode') == 'ProvisionedThroughputExceededException':  # noqa
                    log('Throughput exceeded, trying again in 5 seconds.')
                    time.sleep(5)
                    return enqueue_records(records)

                else:
                    log('Error: {}'.format(response.get('ErrorMessage')))
                    raise RuntimeError

    log('Wrote {} records to kinesis in {} seconds.'.format(
        len(records),
        round(e-s, 2)))

    return len(records)


def handle_fanout(event, context, sql_generation_fn):
    try:
        connection = psycopg2.connect(
            host=os.getenv('POSTGRES_HOST'),
            user=os.getenv('POSTGRES_USER'),
            password=os.getenv('POSTGRES_PASSWORD'),
            port=os.getenv('POSTGRES_PORT'),
            dbname=os.getenv('POSTGRES_DBNAME'))

        sql = sql_generation_fn()
        cursor = connection.cursor()
        cursor.execute(sql)

        total = cursor.rowcount

        log("Enqueuing {} records.".format(total))

        while True:
            records = cursor.fetchmany(500)

            if len(records) == 0:
                break

            enqueue_records(records)

            time.sleep(0.5)

        cursor.close()

        log("Done.")

        return total

    except Exception as e:
        print(traceback.format_exc())
        raise e


def handle_worker(event, context, worker_fn):
    records = event.get('Records', {})

    for record in records:
        data = json.loads(
            base64.b64decode(
                record.get('kinesis', {}).get('data')))

        worker_fn(data)

    return len(records)
