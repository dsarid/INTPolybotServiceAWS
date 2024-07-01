# The Polybot Service: AWS Project

## Summary
This is my submission for the Cloud (AWS) project at the DevOps:aug23 course.
The product is a Telegram bot which receive pictures from the user
and "predict" which objects are appears in the picture.

In this project I made 2 different microservices:
1. Polybot (used for receiving messages from Telegram api via webhooks.)
2. Yolo5 (used for making the prediction using yolo5 AI model)

the interaction between the two microservice is done like this:

### Polybot to Yolo5
Polybot uploads the image that has been received from the user to an Amazon S3 bucket
and then send a message to Amazon SQS with the name of the file and the chat ID.

### Yolo5 to Polybot
Yolo reads the message from the Amazon SQS and download the corresponding file from Amazon S3
later, after performing the prediction it save the results in an Amazon DynamoDB table.
Then it makes an HTTP POST request with the unique key of the results to the Polybot service.
Polybot then extract the Prediction key and use it to read the results from the DynamoDB table
then send them to the user in a human-friendly format.

## Technical details about the cloud infrastructure
- The Polybot microservice runs on two separate instances
that attached to a load balancer that routes the traffic to them.
- The yolo5 instance is handled by an autoscaling group,
the desired capacity is 1 but when there are high average CPU utilization the ASG
deploy another instance.
