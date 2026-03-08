#!/bin/bash

set -e

FUNCTION_NAME="valyli-storage"
ROLE_NAME="valyli-cf-s3-edge-lambda"
REGION="us-east-1"
ACCOUNT_ID="210126446796"

echo "=== Lambda@Edge 部署脚本 ==="

# 1. 更新 IAM 角色的信任策略
echo "步骤 1: 更新 IAM 角色信任策略..."
aws iam update-assume-role-policy \
    --role-name ${ROLE_NAME} \
    --policy-document file://trust-policy.json \
    --region ${REGION}

# 2. 附加权限策略
echo "步骤 2: 附加权限策略..."
aws iam put-role-policy \
    --role-name ${ROLE_NAME} \
    --policy-name LambdaEdgeS3ListPolicy \
    --policy-document file://permissions-policy.json \
    --region ${REGION}

# 3. 打包 Lambda 函数
echo "步骤 3: 打包 Lambda 函数..."
zip -r function.zip index.js node_modules/

# 4. 更新 Lambda 函数代码
echo "步骤 4: 更新 Lambda 函数代码..."
aws lambda update-function-code \
    --function-name ${FUNCTION_NAME} \
    --zip-file fileb://function.zip \
    --region ${REGION}

# 等待函数更新完成
echo "等待函数更新完成..."
aws lambda wait function-updated \
    --function-name ${FUNCTION_NAME} \
    --region ${REGION}

# 更新超时配置
echo "步骤 4.5: 更新超时和运行时配置..."
aws lambda update-function-configuration \
    --function-name ${FUNCTION_NAME} \
    --timeout 30 \
    --runtime nodejs20.x \
    --region ${REGION} > /dev/null

aws lambda wait function-updated \
    --function-name ${FUNCTION_NAME} \
    --region ${REGION}

# 5. 发布新版本
echo "步骤 5: 发布 Lambda 函数版本..."
VERSION=$(aws lambda publish-version \
    --function-name ${FUNCTION_NAME} \
    --region ${REGION} \
    --query 'Version' \
    --output text)

echo "已发布版本: ${VERSION}"
echo "函数 ARN: arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${FUNCTION_NAME}:${VERSION}"

echo ""
echo "=== 部署完成 ==="
echo "下一步: 在 CloudFront 分发中关联此 Lambda@Edge 函数"
echo "1. 打开 CloudFront 控制台"
echo "2. 选择分发 E2ISEL423ZXYI1"
echo "3. 编辑 Behavior"
echo "4. 在 Function associations 中添加:"
echo "   - Event type: Origin Request"
echo "   - Function ARN: arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${FUNCTION_NAME}:${VERSION}"
echo "5. 保存并等待分发部署完成（约 15-20 分钟）"
