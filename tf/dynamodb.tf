module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"

  name     = "prediction-db-tf"
  hash_key = "prediction_id"

  attributes = [
    {
      name = "prediction_id"
      type = "S"
    }
  ]
}
