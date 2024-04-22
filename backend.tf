#Haniehsadat Gholamhosseini

#Create S3 bukcet

#create a bucket - delete the bucket with no confirmation
resource "aws_s3_bucket" "terraform-backend" {
  bucket        = "hanieh-terraform-state-backend"
  force_destroy = true     
}

#Share ownership
resource "aws_s3_bucket_ownership_controls" "terraform-backend" {
  bucket = aws_s3_bucket.terraform-backend.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#Kepp the s3 private - only access to the owner
resource "aws_s3_bucket_acl" "terraform-backend" {
  bucket        = aws_s3_bucket.terraform-backend.id
  depends_on    = [aws_s3_bucket_ownership_controls.terraform-backend]
  acl           = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform-backend" {
  bucket = aws_s3_bucket.terraform-backend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# Create Dynamodb

resource "aws_dynamodb_table" "terraform-backend" {
  name  = "hanieh-terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

