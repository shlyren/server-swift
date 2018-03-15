
#!/usr/bin/env bash
# Linux platform bash file
git add .
echo -n "请填写备注（可空）:"
read remarks
if [ ! -n "$remarks" ];then
    remarks="update: "$(date +%F\ %T)
fi
git commit -m "$remarks"
echo "开始提交代码..."
git push