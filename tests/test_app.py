import json

from lambda_app.app import lambda_handler


def test_valid_message():
    event = {
        'body': '{"message": "Je suis un test valide"}',
    }

    response = lambda_handler(event, None)

    assert response['statusCode'] == 200
    assert 'body' in response

    body_content = json.loads(response['body'])

    assert body_content['message'] == "The received message is: 'Je suis un test valide'"
    assert response['headers']['Content-Type'] == 'application/json'
    assert response['multiValueHeaders']['Access-Control-Allow-Origin'] == ['*']

def test_missing_message():
    event = {
        'body': '{"marchepas": "Je suis un test invalide"}',
    }

    response = lambda_handler(event, None)

    assert response['statusCode'] == 400
    assert 'body' in response

    body_content = json.loads(response['body'])

    assert body_content['error'] == 'Missing message field in request'
    assert response['headers']['Content-Type'] == 'application/json'
    assert response['multiValueHeaders']['Access-Control-Allow-Origin'] == ['*']

def test_missing_body():
    event = {}

    response = lambda_handler(event, None)

    assert response['statusCode'] == 400
    assert 'body' in response

    body_content = json.loads(response['body'])

    assert body_content['error'] == 'Invalid request: missing or malformed body'
    assert response['headers']['Content-Type'] == 'application/json'
    assert response['multiValueHeaders']['Access-Control-Allow-Origin'] == ['*']


def test_invalid_json_body():
    event = {
        'body': 'not a json',  # JSON mal formé
    }

    response = lambda_handler(event, None)

    assert response['statusCode'] == 400
    assert 'body' in response

    body_content = json.loads(response['body'])

    assert body_content['error'] == 'Invalid JSON format'
    assert response['headers']['Content-Type'] == 'application/json'
    assert response['multiValueHeaders']['Access-Control-Allow-Origin'] == ['*']


def test_unexpected_exception(mocker):
    """Forced exception to test the error handling"""

    mocker.patch('lambda_app.app.process', side_effect=Exception('Unexpected Error'))

    event = {
        'body': json.dumps({'message': 'Ce test force une exception'}),
    }

    response = lambda_handler(event, None)

    assert response['statusCode'] == 500
    assert 'body' in response

    body_content = json.loads(response['body'])
    assert body_content['error'] == 'Internal server error'

    assert response['headers']['Content-Type'] == 'application/json'
    assert response['multiValueHeaders']['Access-Control-Allow-Origin'] == ['*']
