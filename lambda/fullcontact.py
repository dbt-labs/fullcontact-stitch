import os
import requests
import time

from . import common


def persist_to_stitch(data):
    url = 'https://api.stitchdata.com/v2/import/push'
    api_key = os.getenv('STITCH_API_KEY')

    return requests.post(
        url,
        headers={'Content-Type': 'application/json',
                 'Authorization': 'Bearer {}'.format(api_key)},
        data=data)


def get_select():
    return 'SELECT "{}" from "{}"."{}"'.format(
        os.getenv('FULLCONTACT_INPUT_EMAIL_ADDRESS_FIELD'),
        os.getenv('FULLCONTACT_INPUT_SCHEMA'),
        os.getenv('FULLCONTACT_INPUT_TABLE'))


def workon_record(record):
    (email_address,) = record
    url = "https://api.fullcontact.com/person.json"
    api_key = os.getenv('FULLCONTACT_API_KEY')

    response = requests.get(
        url,
        headers={'X-FullContact-APIKey': api_key},
        params={'email': email_address})

    requested_at = int(round(time.time()))
    success_at = None
    to_persist = {}

    if response.status_code == 200:
        success_at = int(round(time.time()))
        to_persist = response.json().copy()

        desired_keys = set('photos', 'contactInfo', 'organizations',
                           'demographics', 'socialProfiles')

        all_keys = set(to_persist.keys())

        unwanted_keys = all_keys - desired_keys

        for k in unwanted_keys:
            del to_persist[k]

    elif response.status_code == 202:
        # we tried, but there's no data yet. just tell stitch that we tried.
        pass

    else:
        common.log(
            "WARNING: Fullcontact request failed with {}."
            .format(response.status_code))
        common.log(response.data)
        raise RuntimeError

    to_persist['email_address'] = email_address
    to_persist['requested_at'] = requested_at
    to_persist['success_at'] = success_at

    result = persist_to_stitch({
        'client_id': os.getenv('STITCH_CLIENT_ID'),
        'table_name': 'fullcontact_person',
        'sequence': int(round(time.time())),
        'action': 'upsert',
        'key_names': ['email_address'],
        'data': to_persist,
    })

    if result.status_code >= 400:
        common.log(
            "WARNING: Stitch request failed with {}."
            .format(result.status_code))
        common.log(result.data)
        raise RuntimeError

    else:
        common.log("Persisted to Stitch successfully.")


def handle_fanout(event, context):
    return common.handle_fanout(event, context, get_select)


def handle_worker(event, context):
    return common.handle_worker(event, context, workon_record)
