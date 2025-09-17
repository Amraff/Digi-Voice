resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name
  tags = {
    Name = "text-to-speech"
  }
}
resource "aws_s3_bucket_public_access_block" "my_bucket_public_access_block" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.my_bucket.arn}/*"
      }
    ]
  })
   depends_on = [aws_s3_bucket_public_access_block.my_bucket_public_access_block]
}


resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name_static_website

  tags = {
    Name = "PollyAppStaticSite"
  }
}
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "my_bucket_public_access_block_website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_policy" "public_access" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Sid: "PublicRead",
        Effect: "Allow",
        Principal: "*",
        Action: "s3:GetObject",
        Resource: "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.my_bucket_public_access_block_website]
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.website.bucket
  key          = "index.html"
  source       = var.source_index_html
  content_type = "text/html"
}

resource "aws_s3_object" "scripts_js" {
  bucket       = aws_s3_bucket.website.bucket
  key          = "scripts.js"
  source       = var.source_script_js
  content_type = "application/javascript"
}


resource "aws_s3_object" "styles_css" {
  bucket       = aws_s3_bucket.website.bucket
  key          = "styles.css"
  source       = var.source_css
  content_type = "text/css"
}

