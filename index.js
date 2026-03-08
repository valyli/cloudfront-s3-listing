const { S3Client, ListObjectsV2Command } = require('@aws-sdk/client-s3');

const s3 = new S3Client({ region: 'ap-northeast-1' });
const BUCKET_NAME = 'valyli-storage';

exports.handler = async (event, context) => {
    const request = event.Records[0].cf.request;
    const uri = request.uri;
    
    // 只处理以 / 结尾的目录请求
    if (!uri.endsWith('/')) {
        return request;
    }
    
    try {
        const prefix = uri.substring(1);
        const command = new ListObjectsV2Command({
            Bucket: BUCKET_NAME,
            Prefix: prefix,
            Delimiter: '/'
        });
        const data = await s3.send(command);
        
        let html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Index of ${uri}</title><style>body{font-family:Arial,sans-serif;margin:20px}h1{border-bottom:1px solid #ccc}table{border-collapse:collapse;width:100%}th,td{text-align:left;padding:8px;border-bottom:1px solid #ddd}th{background-color:#f2f2f2}a{text-decoration:none;color:#0066cc}a:hover{text-decoration:underline}</style></head><body><h1>Index of ${uri}</h1><table><tr><th>Name</th><th>Size</th><th>Last Modified</th></tr>`;
        
        if (uri !== '/') {
            const parentUri = uri.substring(0, uri.lastIndexOf('/', uri.length - 2) + 1);
            html += `<tr><td><a href="${parentUri}">../</a></td><td>-</td><td>-</td></tr>`;
        }
        
        if (data.CommonPrefixes) {
            data.CommonPrefixes.forEach(p => {
                const name = p.Prefix.substring(prefix.length);
                html += `<tr><td><a href="/${p.Prefix}">${name}</a></td><td>-</td><td>-</td></tr>`;
            });
        }
        
        if (data.Contents) {
            data.Contents.forEach(item => {
                if (item.Key !== prefix) {
                    const name = item.Key.substring(prefix.length);
                    const size = item.Size < 1024 ? item.Size + ' B' : Math.round(item.Size/1024) + ' KB';
                    const date = new Date(item.LastModified).toLocaleString();
                    html += `<tr><td><a href="/${item.Key}">${name}</a></td><td>${size}</td><td>${date}</td></tr>`;
                }
            });
        }
        
        html += `</table></body></html>`;
        
        return {
            status: '200',
            statusDescription: 'OK',
            headers: {
                'content-type': [{ key: 'Content-Type', value: 'text/html; charset=utf-8' }],
                'cache-control': [{ key: 'Cache-Control', value: 'max-age=300' }]
            },
            body: html
        };
    } catch (error) {
        console.error('Error:', error);
        return request; // 出错时继续正常流程
    }
};
