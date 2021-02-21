var express = require('express'),
    aws = require('aws-sdk'),
    bodyParser = require('body-parser'),
    multer = require('multer'),
    multerS3 = require('multer-s3');

const { v4: uuidv4 } = require('uuid');

//Set region for all resources
aws.config.update({ 
    region: 'MyRegion'
});

/*Set S3 bucket for files uploading*/
var app = express(),
    s3 = new aws.S3(); //Create S3 service object

app.use(bodyParser.json());

//Using Multer to upload file to S3 buckets
var bucketin = "S3BucketIn"; //This value will need to be replaced
var bucketout = "S3BucketOut"; //This value will need to be replaced

var upload = multer({
    storage: multerS3({
        s3: s3,
        bucket: bucketin,
        key: function (req, file, cb) {
            cb(null, file.originalname);
        }
    })
});

/*Get DynamoDB config*/
var dynamodb = new aws.DynamoDB(); //Create Dynamo service object
var tableName = "MyTableName"; //This value will need to be replaced

/*When user make a request to the ALB, send out the index.html*/
app.get('/', function (req, res) {
    res.sendFile(__dirname + '/index.html');
});

/*After the user upload information, insert information to the database*/
app.post('/upload', upload.array('uploadFile',1), function (req, res, next) {

    //Generate randome UUID
    var UUID = uuidv4();

    //Get user's input
    var uname = req.body.name;
    var umail = req.body.email;
    var uphone = req.body.phone;

    //Get the file name from user
    var file_name = res.req.files[0].originalname;

    //Put Item into the DynamoDB after user upload
    var putItem = {
        Item: {
         "Email": {
           S: umail
          }, 
         "UUID": {
           S: UUID
          }, 
         "Name": {
           S: uname
          },
         "Phone": {
           S: uphone
          },
         "Status":{
           N: "0"
         },
         "S3In": {
           S: "s3://" + bucketin + "/" + file_name
          },
         "S3Out": {
           S: bucketout
         }
        }, 
        ReturnConsumedCapacity: "TOTAL", 
        TableName: tableName
       };
    
    dynamodb.putItem(putItem, function(err, data) {
        if (err) {
            console.log("DynamoError", err);
          } else {
          //Query Items in the DynamoDB that belongs to the user using email as the key
            var queryItem = {
              ExpressionAttributeNames: {
                "#uuid": "UUID", 
                "#name": "Name",
                "#phone": "Phone",
                "#status": "Status",
                "#s3in": "S3In",
                "#s3out": "S3Out",
               }, 
              ExpressionAttributeValues: {
              ":e": {
                  S: umail
                }
              }, 
              KeyConditionExpression: "Email = :e", 
              ProjectionExpression: "#uuid, #name, #phone, #status, #s3in, #s3out", 
              TableName: tableName
            };
            dynamodb.query(queryItem, function(err, data) {
              if (err) {
                console.log(err, err.stack);
              } else {
                  res.write("File uploaded successfully to Amazon S3!");
                  res.write("\n\n\nAll items for user with Email: " + umail);
                  //Loop through and print out all the items that associated with the email
                  data.Items.forEach(function(element, index, array){
                    res.write("\n\n--------------------------------" + "Item: " + (index+1) + "-----------------------------------");
                    res.write("\nUUID: " + element.UUID.S + "    " + "Name: " + element.Name.S + "    " + "Phone: " + element.Phone.S + "    " + "Status: " + element.Status.N + "    " + "S3URL: " + element.S3In.S);
                  });
                  res.end();
                }
            });
            } 
    });
});

//App listen on port 3300
app.listen(3300, function () {
});

/* This will create a new route/page located at /gallery and print out all the content in the DynamoDB */
app.get('/gallery', function (req, res) {
  var table = {
    TableName: tableName
};
  dynamodb.scan(table, function(err, data) {
  if (err) {console.log(err, err.stack);} // an error occurred
  else {    
    res.write("List of items in DynamoDB table");
      data.Items.forEach(function(element, index, array){
      res.write("\n\n--------------------------------" + "Item: " + (index+1) + "-----------------------------------");
      res.write("\nUUID: " + element.UUID.S + "    " + "Name: " + element.Name.S + "    " + "Phone: " + element.Phone.S + "    " + "Status: " + element.Status.N + "    " + "S3URL: " + element.S3In.S + "    " + "S3Out: " + element.S3Out.S);
    });
    res.end();
  }
  }); 
});