# File Service

## Overview
The File Service handles file uploads and storage using AWS S3. It provides a REST API for uploading files (images, documents, etc.) and returns public URLs for accessing the uploaded files.

## Port
- **4008**

## Features
- AWS S3 integration for file storage
- Multipart file upload support
- File metadata tracking (size, content type, URL)
- Organized folder structure in S3
- Health check endpoint

## API Endpoints

### Upload File
- **POST** `/file/upload`
- **Content-Type**: `multipart/form-data`
- **Parameters**:
  - `file` (required): The file to upload
  - `folder` (optional): Folder path within bucket (e.g., "farm-verifications")
  - `fileName` (optional): Custom file name. If not provided, generates a unique name
- **Response**:
  ```json
  {
    "message": "File uploaded successfully",
    "data": {
      "url": "https://krushikranti-files.s3.ap-south-1.amazonaws.com/farm-verifications/file.jpg",
      "fileName": "file.jpg",
      "fileSize": 123456,
      "contentType": "image/jpeg"
    }
  }
  ```

### Health Check
- **GET** `/file/health`
- **Response**:
  ```json
  {
    "message": "File service is running",
    "data": "OK"
  }
  ```

## Configuration

### AWS Credentials
**⚠️ IMPORTANT: Never commit AWS credentials to the repository!**

Set the following environment variables before running the service:

- `AWS_ACCESS_KEY_ID`: AWS access key (required)
- `AWS_SECRET_ACCESS_KEY`: AWS secret key (required)
- `AWS_REGION`: AWS region (default: `ap-south-1`)
- `S3_BUCKET`: S3 bucket name (default: `krushikranti-files`)

#### Setting Environment Variables

**Windows (PowerShell):**
```powershell
$env:AWS_ACCESS_KEY_ID="your-access-key"
$env:AWS_SECRET_ACCESS_KEY="your-secret-key"
$env:AWS_REGION="ap-south-1"
$env:S3_BUCKET="krushikranti-files"
```

**Linux/Mac:**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="ap-south-1"
export S3_BUCKET="krushikranti-files"
```

**Docker:**
Set in `docker-compose.yml` or use `.env` file (not committed to git).

### File Size Limits
- Maximum file size: 10MB (configurable in `application.yml`)

## Building
```bash
mvn clean install -pl :file-service -am
```

## Running
```bash
# Local
mvn spring-boot:run -pl :file-service

# Docker
docker-compose up file-service
```

## Integration with API Gateway
The service is accessible through the API Gateway at:
- `/file/**` → File Service (4008)

## Example Usage

### Upload a farm verification photo
```bash
curl -X POST http://localhost:4004/file/upload \
  -H "Authorization: Bearer <token>" \
  -F "file=@photo.jpg" \
  -F "folder=farm-verifications" \
  -F "fileName=farm_123_verification.jpg"
```

## S3 Bucket Structure
Files are organized in S3 as:
```
{bucket}/
  {base-folder}/
    {folder}/
      {fileName}
```

Example:
```
krushikranti-files/
  farm-verifications/
    farm_123_verification.jpg
```

