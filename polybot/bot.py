import telebot
from loguru import logger
import os
import time
from datetime import datetime
from telebot.types import InputFile
import polybot_helper_lib
import boto3


class Bot:

    def __init__(self, token, telegram_chat_url):
        # create a new instance of the TeleBot class.
        # all communication with Telegram servers are done using self.telegram_bot_client
        self.telegram_bot_client = telebot.TeleBot(token)

        # remove any existing webhooks configured in Telegram servers
        self.telegram_bot_client.remove_webhook()
        time.sleep(0.5)

        # set the webhook URL
        self.telegram_bot_client.set_webhook(url=f'{telegram_chat_url}/{token}/', timeout=60)

        logger.info(f'Telegram Bot information\n\n{self.telegram_bot_client.get_me()}')

    def send_text(self, chat_id, text):
        self.telegram_bot_client.send_message(chat_id, text)

    def send_text_with_quote(self, chat_id, text, quoted_msg_id):
        self.telegram_bot_client.send_message(chat_id, text, reply_to_message_id=quoted_msg_id)

    def is_current_msg_photo(self, msg):
        return 'photo' in msg

    def download_user_photo(self, msg):
        """
        Downloads the photos that sent to the Bot to `photos` directory (should be existed)
        :return:
        """
        if not self.is_current_msg_photo(msg):
            raise RuntimeError(f'Message content of type \'photo\' expected')

        file_info = self.telegram_bot_client.get_file(msg['photo'][-1]['file_id'])
        data = self.telegram_bot_client.download_file(file_info.file_path)
        folder_name = file_info.file_path.split('/')[0]

        if not os.path.exists(folder_name):
            os.makedirs(folder_name)

        with open(file_info.file_path, 'wb') as photo:
            photo.write(data)

        return file_info.file_path

    def send_photo(self, chat_id, img_path):
        if not os.path.exists(img_path):
            raise RuntimeError("Image path doesn't exist")

        self.telegram_bot_client.send_photo(
            chat_id,
            InputFile(img_path)
        )

    def handle_message(self, msg):
        """Bot Main message handler"""
        logger.info(f'Incoming message: {msg}')
        self.send_text(msg['chat']['id'], f'Your original message: {msg["text"]}')


class ObjectDetectionBot(Bot):
    def __init__(self, token, telegram_chat_url, images_bucket):
        super().__init__(token, telegram_chat_url)
        self.media_group = None
        self.filter = None

        self.previous_pic = None
        self.images_bucket = images_bucket

    def add_date_to_filename(self, file_path):
        # Split the file path into directory and filename
        directory, filename = os.path.split(file_path)

        # Get the current date
        current_date = datetime.now().strftime("%Y-%m-%d")

        # Extract file extension
        name, extension = os.path.splitext(filename)

        # Create the new filename with the date appended
        new_filename = f"{name}_{current_date}{extension}"

        # Construct the new file path
        new_file_path = os.path.join(directory, new_filename)

        try:
            # Rename the file
            os.rename(file_path, new_file_path)
            print(f"File renamed to: {new_filename}")
            return new_file_path
        except Exception as e:
            print(f"Error: {e}")
        return None

    def handle_message(self, msg):
        logger.info(f'Incoming message: {msg}')

        if self.is_current_msg_photo(msg):
            photo_path = self.download_user_photo(msg)

            # TODO upload the photo to S3

            if self.filter == "Predict":
                images_dir = "photos/predicted_images"

                photo_path = self.download_user_photo(msg)
                photo_path = self.add_date_to_filename(photo_path)
                s3 = boto3.client('s3')
                polybot_helper_lib.upload_file(photo_path, self.images_bucket, s3)

            else:
                self.send_text(
                    msg['chat']['id'],
                    f"An error occurred. \
                    You have to provide a picture and one of the following filters: {self.filters_list}"
                )
                self.filter = None

            # TODO send a job to the SQS queue
            # TODO send message to the Telegram end-user (e.g. Your image is being processed. Please wait...)
