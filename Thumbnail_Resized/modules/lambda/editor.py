import boto3
import sys
import os
from urllib.parse import urlparse
from PIL import Image, ImageFilter
import PIL.Image
import uuid

#Get all service resources
sqs = boto3.resource('sqs',region_name=os.environ['region'])
s3 = boto3.client('s3')
s3_resource = boto3.resource('s3')
dynamodb = boto3.client('dynamodb',region_name=os.environ['region'])
sns = boto3.client('sns',region_name=os.environ['region'])

#Get the S3InURL from the DynamoDB
def get_bucket_in(umail, UUID):
    s3bucketin = dynamodb.query(
             ExpressionAttributeNames={
                '#email': 'Email',
                '#uuid': 'UUID',
            },
            ExpressionAttributeValues={
                ':email': {
                    'S': umail,
                },
                ':uuid': {
                    'S': UUID,
                },
            },
            KeyConditionExpression='#email = :email AND #uuid = :uuid',
            ProjectionExpression='S3In',
            TableName=os.environ['table_name'],
            )
    return s3bucketin

#Get the S3OutURL from the DynamoDB 
def get_bucket_out(umail, UUID):
    s3bucketout = dynamodb.query(
             ExpressionAttributeNames={
                '#email': 'Email',
                '#uuid': 'UUID',
            },
            ExpressionAttributeValues={
                ':email': {
                    'S': umail,
                },
                ':uuid': {
                    'S': UUID,
                },
            },
            KeyConditionExpression='#email = :email AND #uuid = :uuid',
            ProjectionExpression='S3Out',
            TableName=os.environ['table_name'],
            )
    return s3bucketout

#Get the name of the user from the DynamoDB
def get_name(umail, UUID):
    name_of_user = dynamodb.query(
             ExpressionAttributeNames={
                '#email': 'Email',
                '#uuid': 'UUID',
                '#name': 'Name'
            },
            ExpressionAttributeValues={
                ':email': {
                    'S': umail,
                },
                ':uuid': {
                    'S': UUID,
                },
            },
            KeyConditionExpression='#email = :email AND #uuid = :uuid',
            ProjectionExpression='#name',
            TableName=os.environ['table_name'],
            )
    return name_of_user

#Process the image and create a thumbnail
def create_thumbnail(download_image, upload_image):
    #https://docs.python-guide.org/scenarios/imaging/
    #https://stackoverflow.com/questions/1386352/pil-thumbnail-and-end-up-with-a-square-image
    size = (100, 100)
    image = Image.open(download_image)
    image.thumbnail(size, Image.ANTIALIAS)
    background = Image.new('RGBA', size, (255, 255, 255, 0))
    background.paste(
            image, (int((size[0] - image.size[0]) / 2), int((size[1] - image.size[1]) / 2))
    )
    background.save(upload_image)

#Update the Status in DynamoDB from 0 -> 1 to indicate job completion
def update_dynamodb_status(umail, UUID):
    update_status = dynamodb.update_item(
                ExpressionAttributeNames={
                    '#status': 'Status',
                },
                ExpressionAttributeValues={
                ':status': {
                    'N': '1',
                },
            },
                Key={
                'Email': {
                    'S': umail,
                },
                'UUID': {
                    'S': UUID,
                },
            },
                ReturnValues='ALL_NEW',
                TableName=os.environ['table_name'],
                UpdateExpression='SET #status = :status',
            )

#Update the S3Out URL in DynamoDB
def update_s3out(umail, UUID, s3bucketout, new_UUID, file_extention):
    update_s3out = dynamodb.update_item(
                ExpressionAttributeNames={
                    '#s3out': 'S3Out',
                },
                ExpressionAttributeValues={
                ':s3out': {
                    'S': 's3://' + s3bucketout + '/' + 'thumbnail-' + new_UUID + '.' + file_extention,
                },
            },
                Key={
                'Email': {
                    'S': umail,
                },
                'UUID': {
                    'S': UUID,
                },
            },
                ReturnValues='ALL_NEW',
                TableName=os.environ['table_name'],
                UpdateExpression='SET #s3out = :s3out',
            )

#Send email
def sns_publish(sns_subj, sns_message):
    sns.publish(TopicArn=os.environ['topic_arn'], Subject=sns_subj, Message=sns_message)

#Format email
def email_format(name, bucket, item):
    sns_subj = "Task is completed!"
    sns_message = """
    Hello {}. Your image has been rendered.

    ---------------------------------------------------------------------------------------------------------
    Output summary:
    ---------------------------------------------------------------------------------------------------------
    The output bucket is: {}
    The new image is: {}
    ---------------------------------------------------------------------------------------------------------
    """.format(name,bucket,item)
    sns_publish(sns_subj, sns_message)

def handler(event, context):
    
    #Get message from the Dynamo Stream, only process for Insert records
    for record in event['Records']:
        if record['eventName'] == 'INSERT':
            #Get the email & UUID from the stream
            umail = record['dynamodb']['Keys']['Email']['S']
            UUID = record['dynamodb']['Keys']['UUID']['S']
            new_UUID = uuid.uuid4()

            try:
                #Get the input S3 bucket name and object name - using urlparse 
                #https://www.xspdf.com/help/50864227.html
                s3bucketin = get_bucket_in(umail, UUID)
                o = urlparse(s3bucketin['Items'][0]['S3In']['S'])
                bucketin = o.netloc
                keyin = o.path.lstrip('/')

                #Get the output S3 bucket name using urlparse 
                s3bucketout = get_bucket_out(umail, UUID)
                bucketout = s3bucketout['Items'][0]['S3Out']['S']

                #Define the path to download and upload files in /tmp of Lambda
                file_extension = keyin.split('.')[1]
                download_path = '/tmp/{}'.format(keyin)
                upload_path = '/tmp/thumbnail-{}.{}'.format(new_UUID, file_extension)

                #Download the file from input S3 bucet
                s3.download_file(bucketin, keyin, download_path)

                #Create the thumbnail
                create_thumbnail(download_path, upload_path)

                #Naming for the thumbnail uploaded to output S3 bucket
                keyout = 'thumbnail-{}.{}'.format(new_UUID, file_extension)

                #Upload the thumbnail to the output S3 bucket
                s3.upload_file(upload_path, bucketout, keyout)

                ##Update the Status from 0 to 1 for the item in DynamoDB
                update_dynamodb_status(umail, UUID)

                #Update the S3Out with the new URL
                update_s3out(umail, UUID, bucketout, str(new_UUID), file_extension)
            
                #Get the name of the user to send SNS notification
                name_of_user = get_name(umail, UUID)
                name_of_user = name_of_user['Items'][0]['Name']['S']
                
                #Send email to user to notify job completed
                email_format(name_of_user,bucketout,keyout)

            except Exception as e:
                print(e)