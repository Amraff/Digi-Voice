variable "region" {
  type        = string
  description = "Choose an AWS region were amazon polly is available."
}
variable "bucket_name" {
  type        = string
  description = "your unique s3 bucket name"
}
variable "bucket_name_static_website" {
  type        = string
  description = "your unique s3 bucket name for the static website"
}
variable "source_index_html" {
  type        = string
  description = "Path to the index.html file for the static website."
}
variable "source_script_js" {
  type        = string
  description = "Path to the JavaScript file for the static website."
}
variable "source_css" {
  type        = string
  description = "Path to the CSS file for the static website."
}
variable "source_file_lambda_new_post" {
  type        = string
  description = "Path to the source file for the Lambda function that creates the new post."
}
variable "source_file_lambda_convert_to_audio" {
  type        = string
  description = "Path to the source file for the Lambda function that converts text to audio."
}
variable "source_file_lambda_get_post" {
  type        = string
  description = "Path to the source file for the Lambda function that retrieves a post."
}
variable "timeout_lambda" {
  type        = number
  description = "Timeout for the Lambda function in seconds."
}
variable "memory_size_lambda" {
  type        = number
  description = "Memory size for the Lambda function in MB."
}