# VoiceBox - Text-to-Speech Application Architecture

## Overview
VoiceBox is a modern, serverless text-to-speech application built on AWS that provides multi-language voice synthesis with audio download capabilities. The application uses a hybrid architecture combining browser-based speech synthesis for instant playback and AWS services for scalable backend processing.

## Architecture Diagram
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   CloudFront    │    │   S3 Website     │    │  Browser APIs   │
│   (CDN)         │◄───┤   Hosting        │◄───┤  Speech Synth   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  API Gateway    │    │   Lambda         │    │  Audio Download │
│  (REST API)     │◄───┤   Functions      │    │  (Web Audio)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌──────────────────┐
│   DynamoDB      │    │   Amazon Polly   │
│   (Database)    │    │   (TTS Service)  │
└─────────────────┘    └──────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌──────────────────┐
│      SNS        │    │       S3         │
│  (Messaging)    │    │  (Audio Storage) │
└─────────────────┘    └──────────────────┘
```

## Core Components

### 1. Frontend Layer
**Technology**: HTML5, CSS3, JavaScript (jQuery)
**Location**: `website/` directory
**Components**:
- `index.html` - Main application interface
- `styles.css` - Custom yellow/brown/white/black theme
- `script.js` - Client-side logic and browser speech synthesis

**Features**:
- Multi-language voice selection (20+ languages)
- Browser-based speech synthesis using Web Speech API
- Audio recording and download using Web Audio API
- Responsive design with modern UI/UX
- Real-time text-to-speech conversion

### 2. Content Delivery Network
**Service**: Amazon CloudFront
**Purpose**: Global content distribution and caching
**Configuration**:
- Origin: S3 static website
- Custom domain support
- HTTPS enforcement
- Global edge locations for low latency

### 3. Static Website Hosting
**Service**: Amazon S3
**Bucket**: `polly-app-static-website-20251809`
**Configuration**:
- Static website hosting enabled
- Public read access for web assets
- Versioning enabled
- CORS configuration for API calls

### 4. API Gateway
**Service**: AWS API Gateway (REST API)
**Name**: VoiceBox API No Auth
**Endpoints**:
- `GET /voices` - Retrieve available Polly voices
- `POST /new_post` - Create new text-to-speech job
- `GET /get-post` - Check job status and retrieve audio URL
- `POST /direct-audio` - Direct audio generation (future use)

**Configuration**:
- No authentication required
- CORS enabled for cross-origin requests
- Integration with Lambda functions

### 5. Lambda Functions
**Runtime**: Python 3.9
**Functions**:

#### a) Voices Lambda (`PostReader_Voices`)
- **Purpose**: Retrieve available Amazon Polly voices
- **Handler**: `voices.lambda_handler`
- **Timeout**: 30 seconds
- **Permissions**: Polly DescribeVoices

#### b) New Post Lambda (`PostReader_NewPost`)
- **Purpose**: Create new TTS job and store in DynamoDB
- **Handler**: `handler.lambda_handler`
- **Timeout**: 30 seconds
- **Permissions**: DynamoDB PutItem, SNS Publish

#### c) Get Post Lambda (`PostReader_GetPost`)
- **Purpose**: Retrieve job status and audio URL
- **Handler**: `get_post.lambda_handler`
- **Timeout**: 30 seconds
- **Permissions**: DynamoDB Query/Scan

#### d) Convert to Audio Lambda (`PostReader_ConvertToAudio`)
- **Purpose**: Process TTS conversion using Polly
- **Handler**: `convert_to_audio.lambda_handler`
- **Timeout**: 60 seconds
- **Trigger**: SNS Topic
- **Permissions**: Polly SynthesizeSpeech, S3 PutObject, DynamoDB UpdateItem

#### e) Direct Audio Lambda (`DirectAudio`)
- **Purpose**: Immediate audio generation (backup solution)
- **Handler**: `direct_audio.lambda_handler`
- **Timeout**: 30 seconds
- **Permissions**: Polly SynthesizeSpeech, S3 PutObject

### 6. Database Layer
**Service**: Amazon DynamoDB
**Table**: `posts`
**Schema**:
```json
{
  "id": "string (UUID)",
  "voice": "string",
  "text": "string", 
  "status": "string (PROCESSING|COMPLETED|FAILED)",
  "url": "string (S3 URL)",
  "timestamp": "number"
}
```
**Configuration**:
- On-demand billing
- Point-in-time recovery enabled
- Encryption at rest

### 7. Text-to-Speech Service
**Service**: Amazon Polly
**Features**:
- 100+ voices in 60+ languages
- Neural and standard voice engines
- SSML support for advanced speech control
- MP3 audio output format

### 8. Audio Storage
**Service**: Amazon S3
**Bucket**: `mp3-pollybucket-app-20251809`
**Purpose**: Store generated audio files
**Configuration**:
- Public read access for audio files
- Lifecycle policies for cost optimization
- Versioning enabled

### 9. Messaging Service
**Service**: Amazon SNS
**Topic**: `polly-app-topic`
**Purpose**: Decouple TTS job creation from processing
**Subscribers**: Convert to Audio Lambda function

### 10. Infrastructure as Code
**Tool**: Terraform
**Files**:
- `main.tf` - Provider and variable configuration
- `s3.tf` - S3 buckets and policies
- `dynamodb.tf` - DynamoDB table configuration
- `lambda.tf` - Lambda functions and permissions
- `apigateway.tf` - API Gateway configuration
- `apigateway_v2.tf` - New API Gateway (no auth)
- `sns.tf` - SNS topic and subscriptions
- `iam.tf` - IAM roles and policies
- `cloudfront.tf` - CloudFront distribution
- `cognito.tf` - Cognito configuration (legacy)

### 11. CI/CD Pipeline
**Platform**: GitHub Actions
**Workflow**: `.github/workflows/deploy.yml`
**Steps**:
1. Checkout code
2. Package Lambda functions
3. Upload to S3
4. Import existing resources
5. Terraform plan and apply
6. Deploy frontend to S3
7. Invalidate CloudFront cache

## Data Flow

### Primary Flow (Browser-based)
1. User enters text and selects voice
2. Browser Speech Synthesis API generates audio
3. Web Audio API records the speech
4. User can download generated audio file
5. No server-side processing required

### Backup Flow (AWS-based)
1. User submits text via web interface
2. API Gateway receives request
3. New Post Lambda creates DynamoDB record
4. SNS message triggers audio conversion
5. Convert to Audio Lambda uses Polly to generate speech
6. Audio file stored in S3
7. DynamoDB record updated with audio URL
8. User polls for completion via Get Post Lambda

## Security Architecture

### Authentication & Authorization
- **Current**: No authentication required (public access)
- **Legacy**: AWS Cognito User Pools (disabled)
- **API**: Open access with CORS protection

### Network Security
- HTTPS enforcement via CloudFront
- CORS policies for cross-origin protection
- VPC endpoints for internal AWS communication

### Data Protection
- DynamoDB encryption at rest
- S3 server-side encryption
- CloudFront SSL/TLS termination

### IAM Security
- Least privilege access for Lambda functions
- Service-specific IAM roles
- Resource-based policies for S3 and DynamoDB

## Scalability & Performance

### Auto-scaling
- Lambda functions scale automatically
- DynamoDB on-demand scaling
- CloudFront global distribution

### Performance Optimizations
- Browser-based synthesis for instant results
- CloudFront caching for static assets
- Asynchronous processing via SNS
- Connection pooling in Lambda functions

### Cost Optimization
- On-demand pricing for DynamoDB
- S3 lifecycle policies for old audio files
- Lambda execution time optimization
- CloudFront caching to reduce origin requests

## Monitoring & Logging

### AWS CloudWatch
- Lambda function metrics and logs
- API Gateway request/response logging
- DynamoDB performance metrics
- S3 access logging

### Error Handling
- Lambda function error handling and retries
- DynamoDB conditional writes
- S3 upload failure handling
- Client-side error messaging

## Deployment Architecture

### Environments
- **Production**: Live application
- **Development**: Local testing with Terraform

### Infrastructure Management
- Terraform state management
- Resource import for existing infrastructure
- Automated deployment via GitHub Actions
- Environment-specific configurations

## Technology Stack Summary

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | HTML5, CSS3, JavaScript | User interface |
| CDN | Amazon CloudFront | Content delivery |
| Hosting | Amazon S3 | Static website hosting |
| API | AWS API Gateway | REST API endpoints |
| Compute | AWS Lambda | Serverless functions |
| Database | Amazon DynamoDB | NoSQL data storage |
| TTS | Amazon Polly | Text-to-speech conversion |
| Storage | Amazon S3 | Audio file storage |
| Messaging | Amazon SNS | Asynchronous processing |
| IaC | Terraform | Infrastructure management |
| CI/CD | GitHub Actions | Automated deployment |
| Browser APIs | Web Speech API, Web Audio API | Client-side audio |

## Future Enhancements

### Planned Features
- User authentication and personalization
- Voice cloning capabilities
- Batch processing for large texts
- Advanced SSML support
- Multi-format audio output (WAV, OGG, FLAC)

### Scalability Improvements
- API rate limiting
- CDN optimization
- Database sharding
- Multi-region deployment

### Security Enhancements
- API key authentication
- User-based access control
- Audit logging
- Data encryption in transit

---

**Document Version**: 1.0  
**Last Updated**: December 2024  
**Architecture Type**: Serverless, Event-driven, Microservices  
**Deployment Model**: Multi-tier, Cloud-native