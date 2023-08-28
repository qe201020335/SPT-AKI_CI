echo "clone repo"
git clone https://dev.sp-tarkov.com/SPT-AKI/Server.git ./Server

echo "lfs"
cd ./Server
git lfs fetch
git lfs pull

$Head = git rev-parse --short HEAD

echo "build"
cd ./project
npm install
npm run build:debug

ls ./build

Compress-Archive -Path ./build/* -DestinationPath "../SPT-Aki-Server-$Head.zip"
echo "Built file: SPT-Aki-Server-$Head.zip"
echo "ZIP_NAME=SPT-Aki-Server-$Head.zip" >> "$GITHUB_OUTPUT"
cat "$GITHUB_OUTPUT"