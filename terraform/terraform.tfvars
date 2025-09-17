# This is an example of a tfvars file for this Terraform configuration.
region                              = "us-east-1"
bucket_name                         = "mp3-pollybucket-app-20251809"
bucket_name_static_website          = "polly-app-static-website-20251809"
source_file_lambda_new_post         = "../lambda/handler.py"
source_file_lambda_convert_to_audio = "../lambda/convert_to_audio.py"
source_file_lambda_get_post         = "../lambda/get_post.py"
source_index_html                   = "../website/index.html"
source_script_js                    = "../website/script.js"
source_css                          = "../website/styles.css"
timeout_lambda                      = 120
memory_size_lambda                  = 256