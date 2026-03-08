# 配置说明

## 当前配置

- **S3 Bucket**: valyli-storage
- **S3 Region**: ap-northeast-1
- **Lambda Function**: valyli-storage
- **Lambda Region**: us-east-1 (Lambda@Edge 必须在此区域)
- **IAM Role**: valyli-cf-s3-edge-lambda
- **CloudFront Distribution**: E2ISEL423ZXYI1
- **Account ID**: 210126446796

## 修改配置

如果需要修改配置，编辑以下文件：

1. **index.js** - 修改 S3 bucket 名称和区域
   ```javascript
   const s3 = new S3Client({ region: 'ap-northeast-1' });
   const BUCKET_NAME = 'valyli-storage';
   ```

2. **deploy.sh** - 修改 Lambda 函数名、角色名、账号 ID
   ```bash
   FUNCTION_NAME="valyli-storage"
   ROLE_NAME="valyli-cf-s3-edge-lambda"
   ACCOUNT_ID="210126446796"
   ```

3. **permissions-policy.json** - 修改 S3 bucket ARN
   ```json
   "Resource": "arn:aws:s3:::valyli-storage"
   ```

## 重要提示

- Lambda@Edge 必须部署在 us-east-1 区域
- S3Client 必须指定正确的 bucket 区域
- 删除 S3 中的空目录对象（如 `story/`），否则 Lambda 不会被触发
- 每次修改代码后需要发布新版本并更新 CloudFront 关联
