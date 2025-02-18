from lambda_app.app import lambda_handler


def test_valid_message():
    event = {
        'body': '{"message": "Je suis un test valide"}',
    }

    response = lambda_handler(event, None)

    assert response['statusCode'] == 200
    assert response['body'] == "The received message is: 'Je suis un test valide'"

def test_missing_message():
    event = {
        'body': '{"marchepas": "Je suis un test invalide"}',
    }

    response = lambda_handler(event, None)
    assert response['statusCode'] == 400
    assert response['body'] == 'Missing message field in request.'

def test_missing_body():
    event = {
        'head': '{"marchepas": "Je suis un test invalide"}',
    }

    response = lambda_handler(event, None)
    assert response['statusCode'] == 500
    assert response['body'] == 'Internal server error. Missing body in request.'
