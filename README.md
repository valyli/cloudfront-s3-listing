# CloudFront S3 目录列表 Lambda@Edge

## 问题诊断

Lambda@Edge 部署失败的常见原因：

1. **区域错误**: 必须在 us-east-1 部署 ✓
2. **IAM 角色信任策略**: 必须同时信任 lambda.amazonaws.com 和 edgelambda.amazonaws.com
3. **未发布版本**: 不能使用 $LATEST，必须发布具体版本号
4. **内存/超时限制**: Origin Request 最大 128MB/30秒
5. **环境变量**: Lambda@Edge 不支持环境变量

## 部署步骤

```bash
cd /home/ec2-user/git/cloudfront-s3-listing
chmod +x deploy.sh
./deploy.sh
```

## 文件说明

- `index.js` - Lambda@Edge 函数代码

## 手动部署步骤

如果脚本失败，按以下步骤手动操作：

### 1. 检查并更新 IAM 角色

```bash
# 查看当前信任策略
aws iam get-role --role-name valyli-cf-s3-edge-lambda --region us-east-1

# 更新信任策略
aws iam update-assume-role-policy \
    --role-name valyli-cf-s3-edge-lambda \
    --policy-document file://trust-policy.json \
    --region us-east-1

# 附加权限策略
aws iam put-role-policy \
    --role-name valyli-cf-s3-edge-lambda \
    --policy-name LambdaEdgeS3ListPolicy \
    --policy-document file://permissions-policy.json \
    --region us-east-1
```

### 2. 打包并上传函数

```bash
# 打包
zip -r function.zip index.js node_modules/

# 更新函数代码
aws lambda update-function-code \
    --function-name valyli-storage \
    --zip-file fileb://function.zip \
    --region us-east-1

# 等待更新完成
aws lambda wait function-updated \
    --function-name valyli-storage \
    --region us-east-1
```

### 3. 发布版本

```bash
# 发布新版本
aws lambda publish-version \
    --function-name valyli-storage \
    --region us-east-1
```

记录输出的版本号（例如：1, 2, 3...）

### 4. 关联到 CloudFront

在 CloudFront 控制台：
1. 选择分发 E2ISEL423ZXYI1
2. 编辑 Behavior（通常是 Default）
3. Function associations 添加：
   - Event type: **Origin Request**
   - Function ARN: `arn:aws:lambda:us-east-1:210126446796:function:valyli-storage:版本号`
4. 保存并等待部署（15-20分钟）

## 测试

```bash
# 测试目录列表
curl https://your-cloudfront-domain.cloudfront.net/

# 测试子目录
curl https://your-cloudfront-domain.cloudfront.net/folder/

# 测试文件访问
curl https://your-cloudfront-domain.cloudfront.net/file.txt
```

## 故障排查

查看 Lambda@Edge 日志（在最近访问的 CloudFront 边缘位置的 CloudWatch Logs）：
```bash
aws logs tail /aws/lambda/us-east-1.valyli-storage --follow
```

## 注意事项

- Lambda@Edge 日志分散在全球各个区域
- 更新后需要等待 CloudFront 分发部署完成
- 建议先在测试环境验证
