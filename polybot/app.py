import flask
from flask import request
import os
from bot import ObjectDetectionBot
import boto3
from botocore.exceptions import ClientError
import polybot_helper_lib
import json

dynamo_client = boto3.client('dynamodb', region_name='eu-central-1')

app = flask.Flask(__name__)

# TODO break down this line to multiple steps, for readability and error-checking
TELEGRAM_TOKEN = json.loads(polybot_helper_lib.get_secret("telegram_bot_token")).get('TELEGRAM_BOT_TOKEN')

S3_IMAGE_BUCKET = os.environ['S3_BUCKET']

TELEGRAM_APP_URL = os.environ['TELEGRAM_APP_URL']

@app.route('/', methods=['GET'])
def index():
    return 'Ok'


@app.route(f'/{TELEGRAM_TOKEN}/', methods=['POST'])
def webhook():
    req = request.get_json()
    bot.handle_message(req['message'])
    return 'Ok'


@app.route('/status')
def status():
    return 'OK'


@app.route(f'/results', methods=['POST'])
def results():
    prediction_id = request.args.get('predictionId')

    # TODO use the prediction_id to retrieve results from DynamoDB and send to the end-user

    chat_id = ...
    text_results = ...

    bot.send_text(chat_id, text_results)
    return 'Ok'


@app.route(f'/loadTest/', methods=['POST'])
def load_test():
    req = request.get_json()
    bot.handle_message(req['message'])
    return 'Ok'


if __name__ == "__main__":
    bot = ObjectDetectionBot(TELEGRAM_TOKEN, TELEGRAM_APP_URL, S3_IMAGE_BUCKET)

    app.run(host='0.0.0.0', port=8443)
