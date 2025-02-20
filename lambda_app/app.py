"""Entry points for the application."""

import json
import logging
from typing import Dict, Union

logger = logging.getLogger()
logger.setLevel('INFO')


def process(message: str) -> str:
    """Process message. The application logic is impleted here.
    Nothing to implement for the assessment.
    """
    return f"The received message is: '{message}'"


JSON = Dict[str, Union[int, str, float, 'JSON']]

LambdaEvent = JSON
LambdaContext = object
LambdaOutput = JSON


def lambda_handler(event: LambdaEvent, context: LambdaContext) -> LambdaOutput:  # noqa: ARG001
    """Entry point for Lambda function.

    Parameters
    ----------
    event: dict, required
        API Gateway Lambda Proxy Input Format

        Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format

    context: object, required
        Lambda Context runtime methods and attributes

        Context doc: https://docs.aws.amazon.com/lambda/latest/dg/python-context-object.html

    Returns
    -------
    API Gateway Lambda Proxy Output Format: dict

        Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html

    """
    try:
        if 'body' not in event or not isinstance(event['body'], str):
            return {
                'isBase64Encoded': False,
                'statusCode': 400,
                'headers': { 'Content-Type': 'application/json' },
                'multiValueHeaders': { 'Access-Control-Allow-Origin': ['*'] },
                'body': json.dumps(
                    {'error': 'Invalid request: missing or malformed body'},
                ),
            }

        try:
            body = json.loads(event['body'])
        except json.JSONDecodeError:
            return {
                'isBase64Encoded': False,
                'statusCode': 400,
                'headers': { 'Content-Type': 'application/json' },
                'multiValueHeaders': { 'Access-Control-Allow-Origin': ['*'] },
                'body': json.dumps(
                    {'error': 'Invalid JSON format'},
                ),
            }

        message = body.get('message')
        if not message:
            return {
                'isBase64Encoded': False,
                'statusCode': 400,
                'headers': { 'Content-Type': 'application/json' },
                'multiValueHeaders': { 'Access-Control-Allow-Origin': ['*'] },
                'body': json.dumps(
                    {'error': 'Missing message field in request'},
                ),
            }

        response_body = {'message': process(message)}
        return {
            'isBase64Encoded': False,
            'statusCode': 200,
            'headers': { 'Content-Type': 'application/json' },
            'multiValueHeaders': { 'Access-Control-Allow-Origin': ['*'] },
            'body': json.dumps(response_body),
        }

    except Exception:
        logger.exception('An unexpected error occurred')
        return {
            'isBase64Encoded': False,
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'multiValueHeaders': {'Access-Control-Allow-Origin': ['*']},
            'body': json.dumps(
                {'error': 'Internal server error'},
            ),
        }
